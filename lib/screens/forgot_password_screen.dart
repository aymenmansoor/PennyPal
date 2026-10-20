import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/validators.dart';
import '../services/auth_service.dart';
import '../widgets/pennypal_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  bool busy = false, sent = false;
  @override void dispose(){ email.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(()=>busy=true);
    try { await AuthService.instance.sendPasswordReset(email.text); if(mounted)setState(()=>sent=true); }
    on FirebaseAuthException catch(e){ if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message ?? 'Could not send reset email'))); }
    finally { if(mounted)setState(()=>busy=false); }
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(), body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:460),child:Column(children:[
      const PennyPalLogo(size:68), const SizedBox(height:18),
      Text('Reset your password',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900)),
      const SizedBox(height:8), const Text('Enter your email and we’ll send you a secure password-reset link.',textAlign:TextAlign.center), const SizedBox(height:24),
      Card(child:Padding(padding:const EdgeInsets.all(22),child:sent
        ? Column(children:[const Icon(Icons.mark_email_read_rounded,size:48),const SizedBox(height:12),const Text('Check your inbox',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text('We sent a reset link to ${email.text}.',textAlign:TextAlign.center),const SizedBox(height:18),FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Back to sign in'))])
        : Form(key:formKey,child:Column(children:[TextFormField(controller:email,validator:Validators.email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email address',prefixIcon:Icon(Icons.alternate_email_rounded))),const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:submit,child:Text(busy?'Sending…':'Send reset link')))]))))
    ])))));
}
