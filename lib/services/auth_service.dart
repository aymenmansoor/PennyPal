import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // userChanges also emits after reload()/token/profile changes. This is
  // important for email verification: authStateChanges alone may not rebuild.
  Stream<User?> get authChanges => _auth.userChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name.trim());
    await _ensureUserProfile(user, name: name.trim(), mobile: mobile.trim());
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> _ensureUserProfile(
    User user, {
    String? name,
    String? mobile,
  }) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    final existing = snap.data();

    if (!snap.exists) {
      await ref.set({
        'name': name ?? user.displayName ?? '',
        'email': user.email ?? '',
        'mobile': mobile ?? '',
        'role': 'student',
        'countryCode': 'PK',
        'currencyCode': 'PKR',
        'currencySymbol': 'Rs',
        'notificationsEnabled': true,
        'onboardingComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    // Repair old/partial profiles without overwriting admin roles/preferences.
    final patch = <String, dynamic>{};
    if ((existing?['email'] ?? '').toString().isEmpty && user.email != null) {
      patch['email'] = user.email;
    }
    if ((existing?['name'] ?? '').toString().isEmpty &&
        (name ?? user.displayName ?? '').isNotEmpty) {
      patch['name'] = name ?? user.displayName;
    }
    if ((existing?['mobile'] ?? '').toString().isEmpty &&
        (mobile ?? '').isNotEmpty) {
      patch['mobile'] = mobile;
    }
    if (existing?['role'] == null) patch['role'] = 'student';
    if (existing?['onboardingComplete'] == null) {
      patch['onboardingComplete'] = false;
    }
    if (patch.isNotEmpty) {
      patch['updatedAt'] = FieldValue.serverTimestamp();
      await ref.set(patch, SetOptions(merge: true));
    }
  }

  Future<UserCredential> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (result.user != null) await _ensureUserProfile(result.user!);
    return result;
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> resendVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed != null && !refreshed.emailVerified) {
        await refreshed.sendEmailVerification();
      }
    }
  }

  Future<bool> refreshEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    // Force a fresh ID token as well so listeners/rules see current auth data.
    await _auth.currentUser?.getIdToken(true);
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<UserCredential> signInWithGoogle() async {
    UserCredential result;

    if (kIsWeb) {
      // Firebase popup is the most reliable web flow and avoids coupling the
      // Flutter app to a transient localhost port/GoogleSignIn JS state.
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      result = await _auth.signInWithPopup(provider);
    } else {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      result = await _auth.signInWithCredential(credential);
    }

    final user = result.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'google-user-missing',
        message: 'Google sign-in did not return a user.',
      );
    }
    await _ensureUserProfile(user);
    return result;
  }

  Future<void> logout() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {
        // Firebase sign-out below is authoritative for the app session.
      }
    }
    await _auth.signOut();
  }
}
