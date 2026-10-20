const {onDocumentCreated, onDocumentWritten} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function tokensFor(uid) {
  const user = await db.doc(`users/${uid}`).get();
  if (!user.exists || user.data().notificationsEnabled === false) return [];
  const devices = await db.collection(`users/${uid}/devices`).get();
  return devices.docs.map(d => d.data().token).filter(Boolean);
}
async function push(uid, title, body, data={}) {
  const tokens = await tokensFor(uid); if (!tokens.length) return;
  const result = await admin.messaging().sendEachForMulticast({tokens,notification:{title,body},data});
  const devices = await db.collection(`users/${uid}/devices`).get();
  const invalid = new Set();
  result.responses.forEach((r,i)=>{if(!r.success && ['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(r.error?.code)) invalid.add(tokens[i]);});
  await Promise.all(devices.docs.filter(d=>invalid.has(d.data().token)).map(d=>d.ref.delete()));
}

exports.onExpenseCreated = onDocumentCreated('users/{uid}/transactions/{txId}', async (event) => {
  const tx = event.data?.data(); if (!tx || tx.type !== 'expense') return;
  const uid = event.params.uid; const date = tx.date?.toDate?.() || new Date();
  const month = `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}`;
  const budgets = await db.collection(`users/${uid}/budgets`).where('month','==',month).get();
  if (budgets.empty) return;
  const start = new Date(date.getFullYear(), date.getMonth(), 1); const end = new Date(date.getFullYear(), date.getMonth()+1, 1);
  const allTx = await db.collection(`users/${uid}/transactions`).where('date','>=',admin.firestore.Timestamp.fromDate(start)).where('date','<',admin.firestore.Timestamp.fromDate(end)).get();
  const expenses = allTx.docs.map(d=>d.data()).filter(x=>x.type==='expense');
  for (const bdoc of budgets.docs) {
    const b=bdoc.data(); const spent=expenses.filter(x=>b.category==='Overall'||x.category===b.category).reduce((a,x)=>a+Number(x.amount||0),0);
    const ratio=b.limitAmount>0?spent/Number(b.limitAmount):0; if(ratio<0.8)continue;
    const marker=`${month}_${b.category.replace(/[^a-zA-Z0-9_-]/g,'_')}_${ratio>=1?'100':'80'}`;
    const alertRef=db.doc(`users/${uid}/notificationMarkers/${marker}`); if((await alertRef.get()).exists) continue;
    await alertRef.set({createdAt:admin.firestore.FieldValue.serverTimestamp(),ratio});
    await push(uid, ratio>=1?`${b.category} budget exceeded`:`${b.category} budget is nearly full`, ratio>=1?'Review your recent spending in PennyPal.':'You have used at least 80% of this spending limit.',{screen:'budget'});
  }
});


exports.onSavingsGoalWritten = onDocumentWritten('users/{uid}/savingsGoals/{goalId}', async (event) => {
  const after = event.data?.after;
  if (!after?.exists) return;
  const goal = after.data();
  const target = Number(goal.targetAmount || 0);
  const current = Number(goal.currentAmount || 0);
  if (target <= 0) return;
  const ratio = current / target;
  const milestone = ratio >= 1 ? 100 : ratio >= .75 ? 75 : ratio >= .5 ? 50 : ratio >= .25 ? 25 : 0;
  if (!milestone) return;
  const marker = `goal_${event.params.goalId}_${milestone}`;
  const markerRef = db.doc(`users/${event.params.uid}/notificationMarkers/${marker}`);
  if ((await markerRef.get()).exists) return;
  await markerRef.set({createdAt: admin.firestore.FieldValue.serverTimestamp(), ratio});
  await push(
    event.params.uid,
    milestone === 100 ? `Goal reached: ${goal.name || 'Savings goal'}` : `${milestone}% saved for ${goal.name || 'your goal'}`,
    milestone === 100 ? 'Great work — your savings target is complete.' : 'Keep going. Your progress is moving in the right direction.',
    {screen: 'goals'},
  );
});

exports.dailyGoalReminders = onSchedule('every day 09:00', async () => {
  const users=await db.collection('users').where('notificationsEnabled','==',true).get();
  for(const user of users.docs){const goals=await db.collection(`users/${user.id}/savingsGoals`).where('status','==','active').get();if(goals.empty)continue;const due=goals.docs.filter(d=>{const x=d.data();const dt=x.targetDate?.toDate?.();return dt&&dt>Date.now()&&dt-Date.now()<1000*60*60*24*30;});if(due.length)await push(user.id,'Savings goal check-in',`${due.length} goal${due.length===1?' is':'s are'} due within the next 30 days.`,{screen:'goals'});}
});

async function deleteQuery(query) {
  while (true) {
    const snapshot = await query.limit(400).get();
    if (snapshot.empty) return;
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
}

exports.cleanupDeletedUser = functions.auth.user().onDelete(async (user) => {
  const userRef = db.doc(`users/${user.uid}`);
  await db.recursiveDelete(userRef);
  await deleteQuery(db.collection('supportQueries').where('userId', '==', user.uid));
  await deleteQuery(db.collection('activityEvents').where('userId', '==', user.uid));
});
