# Android Release Preparation

## Current audit

- Application ID: `com.example.pennypal`, which must be confirmed as permanent.
- Version: `1.0.0+1` from `pubspec.yaml`.
- Release signing currently uses the debug signing configuration and is not
  suitable for Play publication.
- The manifest requests `INTERNET` and enables cleartext traffic. Remove
  `usesCleartextTraffic="true"` unless a reviewed non-TLS endpoint is required.
- Launcher icons are present under `android/app/src/main/res/mipmap-*`.
- No release keystore or private signing material is committed.

Changing the application ID requires a new Firebase Android app, updated
`google-services.json`, OAuth configuration, and a migration decision.

## Secure signing procedure

1. Approve the permanent application ID.
2. Generate a release keystore outside the repository.
3. Store the keystore and passwords in a password manager or CI secret store.
4. Keep only variable names or an ignored local `key.properties` path in build
   configuration; never commit keys or passwords.
5. Configure a dedicated release signing config and register SHA-1/SHA-256
   fingerprints in Firebase and Google Play.
6. Enable Play App Signing and securely retain upload-key recovery material.
7. Build and inspect the AAB on a protected local or CI runner.

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

## Play Store checklist

- Permanent package ID, app name, version code/name, and signing approved.
- Adaptive icon, feature graphic, screenshots, and support contact reviewed.
- Privacy policy URL and Data Safety form match Firebase Auth, Firestore,
  notifications, and account deletion behavior.
- Content rating, target audience, ads declaration, and financial-app answers
  completed accurately.
- Internal and closed testing tracks exercised on supported Android versions.
- Crash reporting, deletion, and Google Sign-In tested on a signed build.

## Store listing draft

**Short description:** Simple budgeting and financial learning for students.

**Full description:** PennyPal helps students understand everyday money without
connecting to bank accounts or moving funds. Track income and expenses, set
budgets, work toward savings goals, review spending reports, and learn practical
financial concepts. Personalise currency and appearance, receive reminders,
and contact support from inside the app. PennyPal is an educational budgeting
tool and does not provide professional financial or investment advice.

Confirm privacy disclosures against the final Firebase configuration and actual
notification choices before submission.
