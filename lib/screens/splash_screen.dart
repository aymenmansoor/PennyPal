import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/pennypal_widgets.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState()=>_SplashScreenState(); }
class _SplashScreenState extends State<SplashScreen>{
  @override void initState(){ super.initState(); Future.delayed(const Duration(milliseconds:900),(){ if(mounted) Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const AuthGate())); }); }
  @override Widget build(BuildContext context)=>Scaffold(body:Container(
    decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFFF4F7F6),Color(0xFFE8F6F1)],begin:Alignment.topCenter,end:Alignment.bottomCenter)),
    child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
      const PennyPalLogo(size:86),const SizedBox(height:24),
      const Text('PennyPal',style:TextStyle(fontSize:34,fontWeight:FontWeight.w900,color:AppTheme.brandDark,letterSpacing:-1)),
      const SizedBox(height:7),const Text('Learn  •  Budget  •  Save',style:TextStyle(color:Color(0xFF65736E),fontWeight:FontWeight.w600,letterSpacing:.5)),
      const SizedBox(height:34),const SizedBox(width:26,height:26,child:CircularProgressIndicator(strokeWidth:2.5)),
    ])),
  ));
}
