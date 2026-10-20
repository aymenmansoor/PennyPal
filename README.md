# PennyPal

PennyPal is a Flutter + Firebase student budgeting, saving and financial-learning application.

## Implemented core flows
- Firebase email/password registration and sign-in
- Firestore-backed income/expense CRUD
- Dashboard totals and recent activity
- Search plus type/category/date transaction filters
- Monthly/category budgets and threshold warnings
- Savings goals and progress updates
- Spending reports and visual category breakdown
- Learning Hub
- Educational PennyPal guidance (local fallback guidance; external AI API can be added separately)
- Alerts/reminders derived from budgets and goals
- Profile, support/feedback, role-gated admin overview
- Firestore security rules

## Firebase
The project is configured for project `pennypal-aymen`. If platform configuration is regenerated, run:

`flutterfire configure --project=pennypal-aymen`

Then deploy rules:

`firebase deploy --only firestore:rules`

## Verification
Run on your development machine:

`flutter pub get`

`flutter analyze`

`flutter test`

`flutter run -d chrome`

## Important
PennyPal is educational software. It does not connect to bank accounts, process payments, store card data, provide investments, or provide professional financial advice.
