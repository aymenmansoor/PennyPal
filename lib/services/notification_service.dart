import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  NotificationService._();
  static final instance=NotificationService._();
  Future<void> enablePush() async {
    final user=FirebaseAuth.instance.currentUser; if(user==null)return;
    final messaging=FirebaseMessaging.instance;
    await messaging.requestPermission(alert:true,badge:true,sound:true);
    try {
      final token=await messaging.getToken();
      if(token!=null) await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('devices').doc(token).set({'token':token,'updatedAt':FieldValue.serverTimestamp()});
    } catch (_) { /* Web push can require a VAPID key; in-app alerts still work. */ }
  }
}
