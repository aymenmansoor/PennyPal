import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserPreferencesService {
  UserPreferencesService._();
  static final instance=UserPreferencesService._();
  String countryCode='US', currencyCode='USD', currencySymbol='\$';
  bool notificationsEnabled=true;
  NumberFormat get money=>NumberFormat.currency(symbol:'$currencySymbol ',decimalDigits:2);
  Future<void> load(String uid) async { final x=(await FirebaseFirestore.instance.collection('users').doc(uid).get()).data()??{}; countryCode=x['countryCode']??'US';currencyCode=x['currencyCode']??'USD';currencySymbol=x['currencySymbol']??'\$';notificationsEnabled=x['notificationsEnabled']??true; }
  Future<void> save(String uid,{required String country,required String currency,required String symbol,required bool notifications}) async {await FirebaseFirestore.instance.collection('users').doc(uid).set({'countryCode':country,'currencyCode':currency,'currencySymbol':symbol,'notificationsEnabled':notifications},SetOptions(merge:true));countryCode=country;currencyCode=currency;currencySymbol=symbol;notificationsEnabled=notifications;}
}
