# Portfolio Demo Launch Handoff

This project is presented as a completed Aptech TechWiz 7 competition project.
The live-demo and screenshot work must use a Firebase project separate from the
original competition project `pennypal-aymen`.

## Approval gate

Before creating cloud resources, obtain approval for:

- A new Firebase project, for example `pennypal-portfolio-demo`.
- Any Blaze billing upgrade required by Cloud Functions or scheduled work.
- Firebase Authentication, Firestore, Hosting, and optional FCM setup.
- Deployment of rules, Functions, and Hosting.

No production or competition Firebase data should be copied to the demo.

## Demo project setup

After approval, create the project in Firebase Console and enable Authentication,
Firestore, Hosting, and only the Functions/Cloud Messaging services required by
the screens being demonstrated. Then configure local staging output without
changing the checked-in production file:

```bash
cp lib/firebase_options.dart /tmp/pennypal-production-firebase-options.dart
flutterfire configure --project=pennypal-portfolio-demo --out=lib/firebase_options.staging.dart
cp lib/firebase_options.staging.dart lib/firebase_options.dart
```

Review the generated values, configure Email/Password and Google providers,
add the final Hosting domain to Authorized domains, and register the matching
web OAuth client. Deploy only after verification:

```bash
firebase use pennypal-portfolio-demo
flutter pub get
flutter analyze
flutter test
flutter build web --release
firebase deploy --project pennypal-portfolio-demo --only firestore:rules,firestore:indexes
firebase deploy --project pennypal-portfolio-demo --only hosting
```

Restore the checked-in production configuration immediately after local demo
testing, or use a disposable worktree for the staging swap:

```bash
cp /tmp/pennypal-production-firebase-options.dart lib/firebase_options.dart
rm lib/firebase_options.staging.dart
```

Deploy Functions only if notifications or account-deletion cleanup are part of
the approved demo scope. Functions may require the Blaze plan.

## Synthetic demo data

Create disposable accounts for `student`, `admin`, and `superAdmin` roles. Use
fictional names, dates, amounts, categories, support requests, and learning
content. Do not reuse competition accounts, production UIDs, credentials, or
personal financial records. Delete or reset demo data after capture as needed.

## Capture and publish

Use a real running build and synthetic data to capture dashboard, transactions,
budgets, savings goals, reports, and admin dashboard images. Save optimized
files under `docs/screenshots/` following its guide. Only after review should
the README receive image links and the verified Hosting URL.

## GitHub profile

Suggested repository description:

> PennyPal: a Flutter and Firebase student budgeting app built for Aptech TechWiz 7.

Suggested topics: `flutter`, `dart`, `firebase`, `firestore`, `student-app`,
`budgeting`, `personal-finance`, `mobile-app`, `web-app`.

To pin the repository, open the GitHub profile, choose **Edit pinned items**,
select PennyPal, and save. After deployment, edit the repository About section
to add the verified Hosting URL as the Website link. Do not add a URL before it
has been tested from an anonymous browser session.
