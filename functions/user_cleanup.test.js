const test = require('node:test');
const assert = require('node:assert/strict');
const {cleanupDeletedUser} = require('./user_cleanup');

function fakeFieldValue() {
  return {
    serverTimestamp: () => 'timestamp',
    increment: (amount) => `increment:${amount}`,
  };
}

function fakeDb({failOnce = false} = {}) {
  const statusWrites = [];
  let recursiveCalls = 0;
  const statusRef = {set: async (values) => statusWrites.push(values)};
  return {
    statusWrites,
    get recursiveCalls() { return recursiveCalls; },
    doc: (path) => path.startsWith('accountDeletionCleanup/')
      ? statusRef
      : {path},
    recursiveDelete: async () => {
      recursiveCalls += 1;
      if (failOnce && recursiveCalls === 1) throw new Error('temporary cleanup failure');
    },
    collection: () => ({where: () => ({limit: () => ({get: async () => ({empty: true, docs: []})})})}),
    batch: () => ({delete: () => {}, commit: async () => {}}),
  };
}

test('records cleanup failure and succeeds on a later retry', async () => {
  const db = fakeDb({failOnce: true});
  const options = {db, uid: 'deleted-user', fieldValue: fakeFieldValue()};

  await assert.rejects(cleanupDeletedUser(options), /temporary cleanup failure/);
  assert.equal(db.statusWrites.at(-1).status, 'failed');

  await cleanupDeletedUser(options);
  assert.equal(db.recursiveCalls, 2);
  assert.equal(db.statusWrites.at(-1).status, 'complete');
});

test('cleanup is idempotent when the user subtree is already gone', async () => {
  const db = fakeDb();

  await cleanupDeletedUser({db, uid: 'deleted-user', fieldValue: fakeFieldValue()});

  assert.equal(db.statusWrites.at(-1).status, 'complete');
});
