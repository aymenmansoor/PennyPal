import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  bool busy = false;
  String? message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check(silent: true);
    }
  }

  Future<void> _check({bool silent = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      if (!silent) message = null;
    });
    try {
      final verified = await AuthService.instance.refreshEmailVerification();
      if (!mounted) return;
      setState(() {
        busy = false;
        message = verified
            ? 'Email verified. Opening PennyPal…'
            : 'Not verified yet. Open the link in your email, then try again.';
      });
      // AuthGate listens to userChanges and will route automatically once the
      // refreshed Firebase user is verified.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        message = e.message ?? 'Could not check verification. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        busy = false;
        message = 'Could not check verification. Check your connection and retry.';
      });
    }
  }

  Future<void> _resend() async {
    try {
      await AuthService.instance.resendVerification();
      if (!mounted) return;
      setState(() => message = 'A new verification email has been sent.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => message = e.message ?? 'Could not resend verification email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 34,
                        backgroundColor: AppTheme.mint,
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          size: 32,
                          color: AppTheme.brand,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Verify your email',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a verification link to $email. Open the link, then return to PennyPal.',
                        textAlign: TextAlign.center,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.brandDark),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: busy ? null : () => _check(),
                          icon: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                          label: Text(busy ? 'Checking…' : 'I verified my email'),
                        ),
                      ),
                      TextButton(
                        onPressed: busy ? null : _resend,
                        child: const Text('Resend verification email'),
                      ),
                      TextButton(
                        onPressed: busy ? null : AuthService.instance.logout,
                        child: const Text('Use another account'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
