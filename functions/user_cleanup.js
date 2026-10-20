async function deleteQuery(db, query) {
  while (true) {
    const snapshot = await query.limit(400).get();
    if (snapshot.empty) return;
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
}

async function cleanupDeletedUser({db, uid, fieldValue}) {
  const statusRef = db.doc(`accountDeletionCleanup/${uid}`);
  const timestamp = fieldValue.serverTimestamp();
  await statusRef.set({
    uid,
    status: 'running',
    attempts: fieldValue.increment(1),
    startedAt: timestamp,
    updatedAt: timestamp,
  }, {merge: true});

  try {
    await db.recursiveDelete(db.doc(`users/${uid}`));
    await deleteQuery(db, db.collection('supportQueries').where('userId', '==', uid));
    await deleteQuery(db, db.collection('activityEvents').where('userId', '==', uid));
    await statusRef.set({
      status: 'complete',
      completedAt: fieldValue.serverTimestamp(),
      updatedAt: fieldValue.serverTimestamp(),
    }, {merge: true});
  } catch (error) {
    try {
      await statusRef.set({
        status: 'failed',
        lastError: error.message || String(error),
        failedAt: fieldValue.serverTimestamp(),
        updatedAt: fieldValue.serverTimestamp(),
      }, {merge: true});
    } catch (_) {
      // Preserve the original failure so the trigger can retry the event.
    }
    throw error;
  }
}

module.exports = {cleanupDeletedUser};
