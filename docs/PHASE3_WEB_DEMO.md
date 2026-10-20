# Phase 3: Staging Web Demo

This is a non-deployment plan for a safe PennyPal web demo. It contains no
credentials and does not select or modify a Firebase project.

## Staging project

Create a separate Firebase project such as `pennypal-staging`, rather than
using production `pennypal-aymen`. Enable only Authentication, Firestore,
Hosting, Cloud Functions, and Cloud Messaging if browser notifications are
required. Generate staging configuration locally with:

```bash
flutterfire configure --project=pennypal-staging
```

Review generated Firebase configuration before use. Keep staging and production
configuration separate. The repository includes
`config/firebase_options.staging.dart.example`; generated staging output belongs
in the ignored `lib/firebase_options.staging.dart` path and must not be
committed. The checked-in `lib/firebase_options.dart` remains production
configuration until an approved build-configuration change is made.

Confirm the active Firebase project before every deploy:

```bash
firebase projects:list
firebase use pennypal-staging
firebase use
```

## Deployment workflow

Verify from a clean checkout before any deployment:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
firebase use pennypal-staging
firebase deploy --only hosting
```

Rules, indexes, and Functions should be deployed separately after review:

```bash
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions
```

Production deployment requires explicit owner approval and an explicit project
selection. Do not use credentials or tokens in repository files.

## Rollback

Record the deployed commit and Hosting release before staging deployment. To
roll back safely, check out the last approved commit, rebuild, and redeploy to
the explicitly selected staging project:

```bash
git fetch origin
git checkout <known-good-commit>
flutter pub get
flutter build web --release
firebase deploy --project pennypal-staging --only hosting
firebase deploy --project pennypal-staging --only firestore:rules,firestore:indexes
firebase deploy --project pennypal-staging --only functions
```

Return to the feature branch after rollback verification. Do not use these
commands against production without owner approval and a recorded rollback
plan.

## Staging verification

Use synthetic accounts only: one student, one admin, and one Super Admin.
Seed synthetic transactions, budgets, savings goals, support requests, and
learning content manually or with a temporary local script that is not
committed. Verify email/password and Google Sign-In, profile writes,
transactions, budgets, goals, reports, support replies, notifications, offline
queue replay, and account deletion. Confirm cleanup failures are visible and
retryable in Cloud Logging.

Add the final staging Hosting domain to Firebase Auth authorized domains and
configure its matching OAuth client. Repeat this for the approved production
domain later. Confirm the Firebase billing plan, budget alerts, Firestore read
volume, Function usage, and web push requirements before enabling live traffic.

## Browser smoke checklist

- Chrome and Safari on desktop and mobile widths.
- Sign up, email verification, password sign-in, Google Sign-In, and sign out.
- Create, edit, and delete transactions; verify totals and reports.
- Create and update a budget and savings goal.
- Submit a support request and verify an admin reply.
- Disable the network, create a permitted write, restore it, and verify sync.
- Confirm unauthorized student reads and writes are rejected.
- Confirm account deletion reauthentication and cleanup in staging.
- Check deep links after refresh, console errors, accessibility focus, and logs.
