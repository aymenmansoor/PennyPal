import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/user_preferences_service.dart';
import 'admin_screen.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';
import 'sign_in_screen.dart';
import 'verify_email_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _preparedUid;
  String? _themePreparedFor;

  void _prepare(User user) {
    if (_preparedUid == user.uid) return;
    _preparedUid = user.uid;
    UserPreferencesService.instance.load(user.uid).catchError((_) {});
    FirestoreService.instance.materializeRecurring(user.uid).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authChanges,
      builder: (context, auth) {
        if (auth.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = auth.data;
        if (user == null) {
          if (_themePreparedFor != 'signed-out') {
            _themePreparedFor = 'signed-out';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) PennyPalApp.of(context)?.setSessionThemeMode(ThemeMode.light);
            });
          }
          return const SignInScreen();
        }
        if (_themePreparedFor != user.uid) {
          _themePreparedFor = user.uid;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) PennyPalApp.of(context)?.restoreSavedTheme();
          });
        }
        _prepare(user);
        final passwordUser = user.providerData.any((p) => p.providerId == 'password');
        if (passwordUser && !user.emailVerified) return const VerifyEmailScreen();

        // A snapshot listener can serve the cached profile while offline and
        // automatically refresh it when connectivity returns.
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, profile) {
            if (!profile.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final data = profile.data?.data();
            if (data == null) {
              return const Scaffold(
                body: Center(child: Text('Your PennyPal profile is not available yet. Reconnect once to finish setup.')),
              );
            }
            if (data['onboardingComplete'] != true) return const OnboardingScreen();
            final role = data['role'];
            if (role == 'admin' || role == 'superAdmin') return const AdminScreen();
            return const HomeShell();
          },
        );
      },
    );
  }
}
