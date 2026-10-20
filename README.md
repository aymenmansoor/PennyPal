# PennyPal

**A cross-platform student finance companion built with Flutter and Firebase.**

PennyPal helps students track income and expenses, set monthly budgets, work toward savings goals, understand their spending, and develop financial literacy. It includes a student experience and a role-restricted administration interface.

> **Status:** Educational / portfolio project. Features below describe the codebase; they are not a guarantee that every workflow has passed end-to-end testing.

## Features

### Student app
- **Authentication:** Email/password sign-up and sign-in, email verification, password reset, and Google Sign-In.
- **Income and expenses:** Create and manage transactions, with searchable and filterable history.
- **Dashboard:** Balance, recent transactions, and financial summaries.
- **Budgets:** Overall and category-specific monthly limits, spending progress, and threshold alerts.
- **Savings goals:** Targets, contributions, progress tracking, and reminders.
- **Reports:** Income/expense summaries and spending-category breakdowns.
- **Learning Hub:** Financial education content.
- **PennyPal assistant:** Context-aware, rule-based guidance about the app and recorded finances. It is not an externally hosted generative-AI service.
- **Personalisation:** Currency preferences, theme selection, and notification settings.
- **Support:** Feedback and support requests.

### Admin portal
- Role-restricted dashboard and user management.
- Support-query management, learning content, and announcements.
- Analytics and administrator-role workflows.

**Known issue:** The admin support-reply action has been reported to show an error. It should be investigated and retested before a production release.

## Tech stack

| Area | Technology |
| --- | --- |
| UI | Flutter / Dart |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Notifications | Firebase Cloud Messaging and Cloud Functions |
| Local preferences | Shared Preferences |
| Project targets | Android, iOS, and Web |

Firestore offline persistence is enabled in the app. Offline write/sync behaviour should be tested separately on each target platform.

## Repository structure

```text
lib/
  core/        # Shared app foundations and theming
  models/      # Application data models
  screens/     # Student, authentication, and admin screens
  services/    # Firebase and application services
  widgets/     # Reusable UI components
functions/     # Firebase Cloud Functions
android/       # Android project
ios/           # iOS project
web/           # Web project
test/          # Flutter tests
firestore.rules
firestore.indexes.json
firebase.json
```

## Getting started

**Prerequisites:** A Flutter SDK compatible with `pubspec.yaml`, platform-specific development tools, and a Firebase project.

1. Clone and install dependencies:

   ```bash
   git clone https://github.com/aymenmansoor/PennyPal.git
   cd PennyPal
   flutter pub get
   ```

2. Configure Firebase for your environment. Review `lib/firebase_options.dart` and `firebase.json`; enable the Authentication providers and Firebase services used by the app. To generate configuration for your own Firebase project:

   ```bash
   flutterfire configure
   ```

3. List available devices and launch the app:

   ```bash
   flutter devices
   flutter run -d chrome
   ```

4. Review Firestore security rules and indexes before deploying them to a Firebase project you control:

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

Cloud Functions live in `functions/` and require separate deployment and appropriate Firebase project configuration.

## Development checks

```bash
flutter analyze
flutter test
```

These are recommended checks, not a claim that all tests currently pass. Before a release, also verify authentication, Firestore permissions, offline synchronisation, notifications, and admin support workflows.

## Security and project scope

- Do not commit passwords, service-account private keys, or real users' financial records.
- Review and test Firebase rules before deployment.
- PennyPal is an educational budgeting application. It does **not** connect to bank accounts, hold or transfer funds, process card payments, or provide professional financial or investment advice.

## About

PennyPal is a multi-platform student finance application project focused on approachable budgeting, saving, and everyday financial education.
