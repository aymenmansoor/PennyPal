import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/transaction_entry.dart';
import '../services/ai_assistant_service.dart';
import '../services/firestore_service.dart';

class AiGuidanceScreen extends StatefulWidget { const AiGuidanceScreen({super.key}); @override State<AiGuidanceScreen> createState()=>_AiGuidanceScreenState(); }
class _Message { final bool user; final String text; final bool error; const _Message(this.user,this.text,{this.error=false}); }

class _AiGuidanceScreenState extends State<AiGuidanceScreen> {
  final input=TextEditingController(), scroll=ScrollController();
  final messages=<_Message>[]; List<String> suggestions=const ['How am I doing this month?','How do I create a goal?','How close am I to my budget?'];
  bool sending=false; String? retryText;
  @override void dispose(){input.dispose();scroll.dispose();super.dispose();}
  void _bottom(){WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:250),curve:Curves.easeOut);});}
  Future<void> send(List<TransactionEntry> tx,List<Budget> budgets,List<SavingsGoal> goals,[String? preset]) async {
    final q=(preset??input.text).trim(); if(q.isEmpty||sending)return;
    setState((){messages.add(_Message(true,q));input.clear();sending=true;retryText=null;});_bottom();
    try { final r=await AiAssistantService.instance.reply(q,transactions:tx,budgets:budgets,goals:goals); if(!mounted)return;setState((){messages.add(_Message(false,r.text));suggestions=r.suggestions;sending=false;}); }
    catch(_){if(!mounted)return;setState((){messages.add(const _Message(false,'I could not answer that just now. Your PennyPal data is safe — please retry.',error:true));retryText=q;sending=false;});}
    _bottom();
  }
  @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser!.uid;return Scaffold(
    appBar:AppBar(title:const Row(children:[CircleAvatar(radius:17,backgroundColor:AppTheme.mint,child:Icon(Icons.auto_awesome_rounded,size:18,color:AppTheme.brand)),SizedBox(width:10),Text('PennyPal Guide')]),actions:[IconButton(tooltip:'Clear conversation',onPressed:(){AiAssistantService.instance.reset();setState(()=>messages.clear());},icon:const Icon(Icons.refresh_rounded))]),
    body:StreamBuilder<List<TransactionEntry>>(stream:FirestoreService.instance.transactions(uid),builder:(context,tSnap)=>StreamBuilder<List<Budget>>(stream:FirestoreService.instance.budgets(uid),builder:(context,bSnap)=>StreamBuilder<List<SavingsGoal>>(stream:FirestoreService.instance.goals(uid),builder:(context,gSnap){
      final tx=tSnap.data??const <TransactionEntry>[], budgets=bSnap.data??const <Budget>[], goals=gSnap.data??const <SavingsGoal>[];
      return Column(children:[Expanded(child:messages.isEmpty?_Welcome(onTap:(s)=>send(tx,budgets,goals,s)):ListView.builder(controller:scroll,padding:const EdgeInsets.fromLTRB(16,18,16,12),itemCount:messages.length+(sending?1:0),itemBuilder:(c,i){if(i==messages.length)return const _Typing();final m=messages[i];return _Bubble(message:m);})),
        if(messages.isNotEmpty&&suggestions.isNotEmpty)SizedBox(height:44,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:14),children:suggestions.map((s)=>Padding(padding:const EdgeInsets.only(right:8),child:ActionChip(label:Text(s),onPressed:()=>send(tx,budgets,goals,s)))).toList())),
        if(retryText!=null)TextButton.icon(onPressed:()=>send(tx,budgets,goals,retryText),icon:const Icon(Icons.refresh_rounded),label:const Text('Retry last question')),
        SafeArea(top:false,child:Container(padding:const EdgeInsets.fromLTRB(14,10,14,14),child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:TextField(controller:input,minLines:1,maxLines:4,textInputAction:TextInputAction.send,onSubmitted:(_)=>send(tx,budgets,goals),decoration:const InputDecoration(hintText:'Ask about your spending, budget or goals…',prefixIcon:Icon(Icons.auto_awesome_outlined)))),const SizedBox(width:8),IconButton.filled(tooltip:'Send',onPressed:sending?null:()=>send(tx,budgets,goals),icon:const Icon(Icons.arrow_upward_rounded))])))
      ]);
    }))));}
}
class _Bubble extends StatelessWidget{final _Message message;const _Bubble({required this.message});@override Widget build(BuildContext context)=>Align(alignment:message.user?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.symmetric(horizontal:15,vertical:12),constraints:const BoxConstraints(maxWidth:600),decoration:BoxDecoration(color:message.user?AppTheme.brand:message.error?const Color(0xFFFFF3F1):Theme.of(context).cardColor,borderRadius:BorderRadius.circular(18),boxShadow:const [BoxShadow(color:Color(0x10000000),blurRadius:12,offset:Offset(0,4))]),child:SelectableText(message.text,style:TextStyle(height:1.45,color:message.user?Colors.white:null))));}
class _Typing extends StatelessWidget{const _Typing();@override Widget build(BuildContext context)=>const Align(alignment:Alignment.centerLeft,child:Padding(padding:EdgeInsets.all(16),child:Row(mainAxisSize:MainAxisSize.min,children:[SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)),SizedBox(width:10),Text('PennyPal is thinking…')])));}
class _Welcome extends StatelessWidget{final ValueChanged<String> onTap;const _Welcome({required this.onTap});@override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(24),children:[const SizedBox(height:24),const Center(child:CircleAvatar(radius:34,backgroundColor:AppTheme.mint,child:Icon(Icons.auto_awesome_rounded,size:32,color:AppTheme.brand))),const SizedBox(height:16),Text('Hi, I’m PennyPal',textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:8),const Text('I can explain the app and help you understand the financial information you have recorded.',textAlign:TextAlign.center,style:TextStyle(height:1.45,color:Color(0xFF71807A))),const SizedBox(height:22),...['How am I doing this month?','How do I create a goal?','How close am I to my budget?','Where do I add an expense?'].map((s)=>Padding(padding:const EdgeInsets.only(bottom:8),child:OutlinedButton(onPressed:()=>onTap(s),child:Text(s))))]);}
