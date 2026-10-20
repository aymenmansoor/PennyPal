import 'package:cloud_firestore/cloud_firestore.dart';
class Budget { final String id,userId,month,category; final double limitAmount; const Budget({required this.id,required this.userId,required this.month,required this.category,required this.limitAmount});
Map<String,dynamic> toMap()=>{'userId':userId,'month':month,'category':category,'limitAmount':limitAmount,'updatedAt':FieldValue.serverTimestamp()};
factory Budget.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){final x=d.data()!;return Budget(id:d.id,userId:x['userId']??'',month:x['month']??'',category:x['category']??'Overall',limitAmount:(x['limitAmount']??0).toDouble());}}
