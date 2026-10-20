import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/validators.dart';
import '../services/auth_service.dart';
import '../widgets/pennypal_widgets.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false, hide = true;

  Future<void> googleSignIn() async {
    setState(() => busy = true);
    try { await AuthService.instance.signInWithGoogle(); }
    on FirebaseAuthException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Google sign-in failed'))); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in could not be completed. Please try again.'))); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await AuthService.instance.login(email.text, password.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Sign in failed')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(children: [
              const PennyPalLogo(size: 76),
              const SizedBox(height: 22),
              Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.ink)),
              const SizedBox(height: 8),
              const Text('Your money, goals and progress — all in one place.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF68756F))),
              const SizedBox(height: 30),
              Card(child: Padding(
                padding: const EdgeInsets.all(22),
                child: Form(key: formKey, child: Column(children: [
                  TextFormField(controller: email, validator: Validators.email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.alternate_email_rounded))),
                  const SizedBox(height: 14),
                  TextFormField(controller: password, obscureText: hide, validator: Validators.password, onFieldSubmitted: (_) => signIn(), decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: busy ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())), child: const Text('Forgot password?'))),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : signIn, child: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in'))),
                  const SizedBox(height: 16),
                  const Row(children:[Expanded(child:Divider()),Padding(padding:EdgeInsets.symmetric(horizontal:12),child:Text('or')),Expanded(child:Divider())]),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: busy ? null : googleSignIn, icon: const Icon(Icons.g_mobiledata_rounded, size: 28), label: const Text('Continue with Google'))),
                ])),
              )),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('New to PennyPal?'),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Create account')),
              ]),
              const SizedBox(height: 14),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shield_outlined, size: 16, color: AppTheme.brand), SizedBox(width: 6), Text('Educational finance tracker • No banking access', style: TextStyle(fontSize: 12, color: Color(0xFF71807A)))])
            ]),
          ),
        ),
      ),
    ),
  );
}
