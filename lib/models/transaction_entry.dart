import 'package:cloud_firestore/cloud_firestore.dart';

const defaultExpenseCategories = ['Food','Transport','Education','Shopping','Entertainment','Bills','Savings','Miscellaneous'];
const defaultIncomeCategories = ['Allowance','Scholarship','Part-time Work','Salary','Gift','Other'];

class TransactionEntry {
  final String id, userId, type, category, description, recurrence;
  final double amount;
  final DateTime date;
  const TransactionEntry({required this.id,required this.userId,required this.type,required this.amount,required this.category,required this.description,required this.date,this.recurrence='none'});
  Map<String,dynamic> toMap()=>{'userId':userId,'type':type,'amount':amount,'category':category,'description':description,'date':Timestamp.fromDate(date),'recurrence':recurrence,'updatedAt':FieldValue.serverTimestamp()};
  factory TransactionEntry.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){final x=d.data()!; return TransactionEntry(id:d.id,userId:x['userId']??'',type:x['type']??'expense',amount:(x['amount']??0).toDouble(),category:x['category']??'Miscellaneous',description:x['description']??'',date:(x['date'] as Timestamp?)?.toDate()??DateTime.now(),recurrence:x['recurrence']??'none');}
}
