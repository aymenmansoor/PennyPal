import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/validators.dart';
import '../services/auth_service.dart';
import '../widgets/pennypal_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(), email = TextEditingController(), mobile = TextEditingController(), password = TextEditingController();
  bool busy = false, hide = true;

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await AuthService.instance.register(name: name.text, email: email.text, mobile: mobile.text, password: password.text);
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Registration failed')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(),
    body: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500), child: Column(children: [
        const PennyPalLogo(size: 68),
        const SizedBox(height: 18),
        Text('Create your PennyPal', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('Start tracking smarter and build better money habits.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF68756F))),
        const SizedBox(height: 24),
        Card(child: Padding(padding: const EdgeInsets.all(22), child: Form(key: formKey, child: Column(children: [
          TextFormField(controller: name, validator: (v) => Validators.requiredText(v, 'Name'), textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded))),
          const SizedBox(height: 13),
          TextFormField(controller: email, validator: Validators.email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.alternate_email_rounded))),
          const SizedBox(height: 13),
          TextFormField(controller: mobile, validator: (v) => Validators.requiredText(v, 'Mobile number'), keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 13),
          TextFormField(controller: password, obscureText: hide, validator: Validators.password, decoration: InputDecoration(labelText: 'Password', helperText: 'At least 6 characters', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : register, child: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create account'))),
        ])))),
        const SizedBox(height: 18),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified_user_outlined, size: 16, color: AppTheme.brand), SizedBox(width: 6), Flexible(child: Text('Your financial records stay private to your account.', style: TextStyle(fontSize: 12, color: Color(0xFF71807A))))]),
      ])),
    )),
  );
}
