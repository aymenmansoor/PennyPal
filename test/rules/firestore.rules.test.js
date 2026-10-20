const fs = require('node:fs');
const path = require('node:path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, getDoc } = require('firebase/firestore');
const { Timestamp } = require('firebase/firestore');

let testEnv;
const now = Timestamp.fromDate(new Date('2026-01-01T00:00:00Z'));

function userContext(uid, role) {
  return testEnv.authenticatedContext(uid, { role });
}

function profile(role) {
  return {
    name: role,
    email: `${role}@example.com`,
    mobile: '0000000000',
    role,
    countryCode: 'PK',
    currencyCode: 'PKR',
    currencySymbol: 'Rs',
    notificationsEnabled: true,
    onboardingComplete: true,
    createdAt: now,
    updatedAt: now,
  };
}

async function seedProfiles() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all([
      setDoc(doc(db, 'users/student-1'), profile('student')),
      setDoc(doc(db, 'users/student-2'), profile('student')),
      setDoc(doc(db, 'users/admin-1'), profile('admin')),
      setDoc(doc(db, 'users/super-1'), profile('superAdmin')),
    ]);
  });
}

describe('PennyPal Firestore permissions', () => {
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'pennypal-rules-test',
      firestore: {
        rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8'),
      },
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await seedProfiles();
  });

  after(async () => testEnv.cleanup());

  it('keeps student transactions private', async () => {
    const student = userContext('student-1', 'student').firestore();
    const other = userContext('student-2', 'student').firestore();
    const transaction = {
      userId: 'student-1',
      type: 'expense',
      amount: 12.5,
      category: 'Food',
      description: 'Lunch',
      date: now,
      recurrence: 'none',
      updatedAt: now,
    };

    await assertSucceeds(setDoc(doc(student, 'users/student-1/transactions/t1'), transaction));
    await assertFails(getDoc(doc(other, 'users/student-1/transactions/t1')));
    await assertFails(setDoc(doc(other, 'users/student-1/transactions/t2'), transaction));
  });

  it('allows admins to reply and audit, but blocks students', async () => {
    const admin = userContext('admin-1', 'admin').firestore();
    const student = userContext('student-1', 'student').firestore();
    const support = {
      userId: 'student-1',
      type: 'support',
      name: 'Student',
      email: 'student@example.com',
      subject: 'Help',
      message: 'Please help',
      rating: null,
      status: 'open',
      createdAt: now,
    };

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'supportQueries/q1'), support);
    });
    await assertSucceeds(updateDoc(doc(admin, 'supportQueries/q1'), {
      adminReply: 'We can help.',
      repliedAt: now,
      updatedAt: now,
    }));
    await assertSucceeds(setDoc(doc(admin, 'adminAudit/a1'), {
      adminId: 'admin-1',
      action: 'reply_support',
      targetId: 'q1',
      createdAt: now,
    }));
    await assertFails(updateDoc(doc(student, 'supportQueries/q1'), {
      adminReply: ' forged reply',
    }));
  });

  it('prevents role escalation and invalid transaction data', async () => {
    const student = userContext('student-1', 'student').firestore();
    await assertFails(updateDoc(doc(student, 'users/student-1'), { role: 'admin' }));
    await assertFails(setDoc(doc(student, 'users/student-1/transactions/bad'), {
      userId: 'student-1',
      type: 'expense',
      amount: -1,
      category: 'Food',
      description: 'Invalid',
      date: now,
      recurrence: 'none',
      updatedAt: now,
    }));
  });

  it('allows only Super Admins to change roles', async () => {
    const admin = userContext('admin-1', 'admin').firestore();
    const superAdmin = userContext('super-1', 'superAdmin').firestore();
    await assertFails(updateDoc(doc(admin, 'users/student-1'), { role: 'admin' }));
    await assertSucceeds(updateDoc(doc(superAdmin, 'users/student-1'), { role: 'admin' }));
  });
});
