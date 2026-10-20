import 'package:cloud_firestore/cloud_firestore.dart';
class SavingsGoal {
  final String id,userId,name,status; final double targetAmount,currentAmount,monthlyContribution; final DateTime targetDate;
  const SavingsGoal({required this.id,required this.userId,required this.name,required this.targetAmount,required this.currentAmount,required this.monthlyContribution,required this.targetDate,this.status='active'});
  double get progress=>targetAmount<=0?0:(currentAmount/targetAmount).clamp(0,1);
  double get remaining=>(targetAmount-currentAmount).clamp(0,double.infinity);
  int? get estimatedMonths=>monthlyContribution<=0||remaining<=0?(remaining<=0?0:null):(remaining/monthlyContribution).ceil();
  bool get completed=>status=='completed'||currentAmount>=targetAmount;
  SavingsGoal copyWith({double? currentAmount,String? status,DateTime? targetDate,double? monthlyContribution})=>SavingsGoal(id:id,userId:userId,name:name,targetAmount:targetAmount,currentAmount:currentAmount??this.currentAmount,monthlyContribution:monthlyContribution??this.monthlyContribution,targetDate:targetDate??this.targetDate,status:status??this.status);
  Map<String,dynamic> toMap()=>{'userId':userId,'name':name,'targetAmount':targetAmount,'currentAmount':currentAmount,'monthlyContribution':monthlyContribution,'targetDate':Timestamp.fromDate(targetDate),'status':completed?'completed':status,'updatedAt':FieldValue.serverTimestamp()};
  factory SavingsGoal.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){final x=d.data()!;return SavingsGoal(id:d.id,userId:x['userId']??'',name:x['name']??'',targetAmount:(x['targetAmount']??0).toDouble(),currentAmount:(x['currentAmount']??0).toDouble(),monthlyContribution:(x['monthlyContribution']??0).toDouble(),targetDate:(x['targetDate'] as Timestamp?)?.toDate()??DateTime.now(),status:x['status']??'active');}
}
