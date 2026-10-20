import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/account_deletion_service.dart';
import '../widgets/responsive_layout.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService.instance.logout();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    await AuthService.instance.sendPasswordReset(email);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Delete account permanently?'),
            content: const Text(
              'This deletes your PennyPal transactions, budgets, goals, categories and profile. This cannot be undone. Firebase may ask you to sign in again for security.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete permanently'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    if (!context.mounted) return;
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final needsPassword = user.providerData.any(
        (provider) => provider.providerId == 'password',
      );
      final password = needsPassword ? await _requestPassword(context) : null;
      if (password == null && needsPassword) return;
      await AccountDeletionService.firebase().delete(password: password);
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'requires-recent-login'
                  ? 'For security, sign out and sign in again before deleting your account.'
                  : (e.message ?? 'Account deletion failed.'),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deletion failed. Please try again.')),
        );
      }
    }
  }

  Future<String?> _requestPassword(BuildContext context) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm your password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(dialogContext, controller.text),
          decoration: const InputDecoration(labelText: 'Current password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return password?.trim();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data() ?? {};
          final name = (data['name'] ?? user.displayName ?? 'Student')
              .toString();
          return SingleChildScrollView(
            child: PageFrame(
              maxWidth: 900,
              child: Column(
                children: [
                  PremiumCard(
                    child: Column(
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.brand, Color(0xFF24B184)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              name.isEmpty
                                  ? 'P'
                                  : name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.email ?? '',
                          style: const TextStyle(color: Color(0xFF71807A)),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            _Pill(
                              Icons.school_outlined,
                              (data['role'] ?? 'student').toString(),
                            ),
                            const _Pill(
                              Icons.shield_outlined,
                              'Private account',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal information',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 14),
                        _Info(
                          icon: Icons.person_outline_rounded,
                          label: 'Full name',
                          value: name,
                        ),
                        const Divider(height: 28),
                        _Info(
                          icon: Icons.alternate_email_rounded,
                          label: 'Email address',
                          value: user.email ?? 'Not provided',
                        ),
                        const Divider(height: 28),
                        _Info(
                          icon: Icons.phone_outlined,
                          label: 'Mobile number',
                          value: (data['mobile'] ?? 'Not provided').toString(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: AppTheme.brand,
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account security',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Your sign-in is protected by Firebase Authentication.',
                                    style: TextStyle(color: Color(0xFF71807A)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _resetPassword(context),
                              icon: const Icon(Icons.password_rounded),
                              label: const Text('Reset password'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _handleLogout(context),
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Sign out'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    color: const Color(0xFFFFF1F1),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delete PennyPal account',
                                  style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF5A1F1F)),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Permanently remove your account and stored finance data.',
                                  style: TextStyle(color: Color(0xFF6B4A4A)),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _deleteAccount(context),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Info({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppTheme.mint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.brand),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF71807A)),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.mint,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.brand),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.brand,
          ),
        ),
      ],
    ),
  );
}
