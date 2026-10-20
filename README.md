# PennyPal 💸

### Smart budgeting for student life

**PennyPal** is a cross-platform personal finance application built to make everyday money management easier for students. Track income and expenses, plan budgets, monitor savings goals, and explore spending insights through an intuitive interface.

**Built with:** Flutter · Dart · Firebase Authentication · Cloud Firestore · Firebase Cloud Functions

---

## 📱 App screenshots

*Screenshots of the PennyPal application featuring demonstration data.*

| Student Dashboard | Transactions | Budgets |
| :---: | :---: | :---: |
| <img src="docs/screenshots/01-dashboard.png" alt="PennyPal student dashboard" width="260"> | <img src="docs/screenshots/03-transactions.png" alt="PennyPal transactions" width="260"> | <img src="docs/screenshots/04-budgets.png" alt="PennyPal budgets" width="260"> |

| Spending Reports | Savings Goals | Learning Hub |
| :---: | :---: | :---: |
| <img src="docs/screenshots/05-reports.png" alt="PennyPal spending reports" width="260"> | <img src="docs/screenshots/06-savings-goals.png" alt="PennyPal savings goals" width="260"> | <img src="docs/screenshots/07-learning-hub.png" alt="PennyPal learning hub" width="260"> |

| Admin Dashboard | Learning Content Management |
| :---: | :---: |
| <img src="docs/screenshots/08-admin-dashboard.png" alt="PennyPal admin dashboard" width="330"> | <img src="docs/screenshots/09-admin-learning.png" alt="PennyPal admin learning management" width="330"> |

## ✨ What PennyPal does

- **Income and expense tracking** — Add, edit, search, and filter transactions.
- **Smart budgets** — Set monthly and category spending limits with progress and threshold notifications.
- **Savings goals** — Set targets and track how much has been saved.
- **Visual reports** — Explore balances, spending patterns, and category breakdowns.
- **Financial Learning Hub** — Learn everyday money-management concepts.
- **PennyPal guidance** — Receive context-aware, rule-based financial education tips.
- **Personalisation** — Currency preferences, light/dark themes, and notification settings.
- **Authentication** — Email/password and Google Sign-In, email verification, and password recovery.
- **Administration** — Role-restricted views for managing users, support queries, announcements, and learning content.

## 🛠 Technology

| Component | Stack |
| --- | --- |
| Application UI | Flutter and Dart |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Cloud services | Firebase Cloud Functions and Cloud Messaging |
| Preferences | Shared Preferences |
| Target platforms | Android, iOS, Web |
| Continuous integration | GitHub Actions |

## 🚀 Run the project locally

Install a Flutter SDK compatible with `pubspec.yaml` and set up a Firebase project for your own testing. Firebase Authentication and Firestore require corresponding configuration.

```bash
git clone https://github.com/aymenmansoor/PennyPal.git
cd PennyPal
flutter pub get
flutter run -d chrome
```

To check the project:

```bash
flutter analyze
flutter test
flutter build web --release
```

## 📁 Project structure

```text
lib/                Flutter app screens, models, services and widgets
android/            Android application
ios/                iOS application
web/                Flutter web application
functions/          Firebase Cloud Functions
test/               Flutter and rules tests
docs/screenshots/   Application screenshot gallery
docs/               Additional technical documentation
```

