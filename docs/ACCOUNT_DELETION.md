# Account deletion

PennyPal reauthenticates the current Firebase user before requesting Auth deletion. A failed password or Google reauthentication therefore leaves the user's Firestore data untouched. The client does not perform Firestore cleanup before Auth deletion.

After Auth deletion, `cleanupDeletedUser` removes the user's `users/{uid}` document and all subcollections, plus matching `supportQueries` and `activityEvents` documents. The cleanup is idempotent. It records progress in `accountDeletionCleanup/{uid}` with `running`, `complete`, or `failed` status and rethrows failures so the trigger's retry policy can run again.

Before production release, an operator must:

1. Deploy `cleanupDeletedUser` and the reviewed Firestore rules from the intended Firebase project.
2. Confirm the Functions runtime service account can read and delete Firestore documents.
3. Confirm the `accountDeletionCleanup` status document is readable only by trusted server-side tooling.
4. Test password and Google deletion in a non-production Firebase project, including a forced cleanup failure and a later retry.

The repository does not deploy this function or delete any production account automatically.
