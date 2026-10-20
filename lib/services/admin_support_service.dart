import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AdminSupportRepository {
  Future<void> updateSupport(String id, Map<String, dynamic> values);

  Future<void> writeAudit(String action, String targetId);
}

class FirestoreAdminSupportRepository implements AdminSupportRepository {
  final FirebaseFirestore db;

  FirestoreAdminSupportRepository({FirebaseFirestore? db})
      : db = db ?? FirebaseFirestore.instance;

  @override
  Future<void> updateSupport(String id, Map<String, dynamic> values) {
    return db.collection('supportQueries').doc(id).update(values);
  }

  @override
  Future<void> writeAudit(String action, String targetId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const AdminSupportException('No administrator session is active.');
    }
    return db.collection('adminAudit').add({
      'adminId': user.uid,
      'action': action,
      'targetId': targetId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

class AdminSupportException implements Exception {
  final String message;
  final Object? cause;
  final bool supportUpdated;

  const AdminSupportException(
    this.message, {
    this.cause,
    this.supportUpdated = false,
  });

  @override
  String toString() => message;
}

class AdminSupportService {
  final AdminSupportRepository repository;

  const AdminSupportService(this.repository);

  factory AdminSupportService.firestore() => AdminSupportService(
        FirestoreAdminSupportRepository(),
      );

  Future<void> saveReply({
    required String supportId,
    required String reply,
  }) async {
    final trimmed = reply.trim();
    if (trimmed.isEmpty) {
      throw const AdminSupportException('Write a reply first.');
    }

    try {
      await repository.updateSupport(supportId, {
        'adminReply': trimmed,
        'repliedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AdminSupportException(
        'The support reply could not be saved. Check your connection and permissions.',
        cause: error,
      );
    }

    try {
      await repository.writeAudit('reply_support', supportId);
    } catch (error) {
      throw AdminSupportException(
        'The reply was saved, but audit logging failed. Please report this to a Super Admin.',
        cause: error,
        supportUpdated: true,
      );
    }
  }
}
