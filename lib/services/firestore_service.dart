import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_entry.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();
  final db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _tx(String uid) =>
      db.collection('users').doc(uid).collection('transactions');
  CollectionReference<Map<String, dynamic>> _budgets(String uid) =>
      db.collection('users').doc(uid).collection('budgets');
  CollectionReference<Map<String, dynamic>> _goals(String uid) =>
      db.collection('users').doc(uid).collection('savingsGoals');
  Stream<List<TransactionEntry>> transactions(String uid) => _tx(uid)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TransactionEntry.fromDoc).toList());
  Future<void> saveTransaction(TransactionEntry t) async {
    if (t.id.isEmpty) {
      await _tx(t.userId).add(t.toMap());
    } else {
      await _tx(t.userId).doc(t.id).set(t.toMap());
    }
    await db.collection('activityEvents').add({
      'userId': t.userId,
      'event': 'transaction_${t.id.isEmpty ? 'created' : 'updated'}',
      'transactionType': t.type,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTransaction(String uid, String id) async {
    await _tx(uid).doc(id).delete();
    await _activity(uid, 'transaction_deleted');
  }

  Stream<List<Budget>> budgets(String uid) =>
      _budgets(uid).snapshots().map((s) => s.docs.map(Budget.fromDoc).toList());
  Future<void> saveBudget(Budget b) async {
    await _budgets(b.userId).doc('${b.month}_${b.category}').set(b.toMap());
    await _activity(b.userId, 'budget_saved');
  }

  Future<void> deleteBudget(String uid, String id) async {
    await _budgets(uid).doc(id).delete();
    await _activity(uid, 'budget_deleted');
  }

  Stream<List<SavingsGoal>> goals(String uid) => _goals(
    uid,
  ).snapshots().map((s) => s.docs.map(SavingsGoal.fromDoc).toList());
  Future<void> saveGoal(SavingsGoal g) async {
    if (g.id.isEmpty) {
      await _goals(g.userId).add(g.toMap());
    } else {
      await _goals(g.userId).doc(g.id).set(g.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteGoal(String uid, String id) async {
    await _goals(uid).doc(id).delete();
    await _activity(uid, 'savings_goal_deleted');
  }

  Future<void> _activity(String uid, String event) =>
      db.collection('activityEvents').add({
        'userId': uid,
        'event': event,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<List<String>> customCategories(String uid, String type) => db
      .collection('users')
      .doc(uid)
      .collection('categories')
      .where('type', isEqualTo: type)
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => (d.data()['name'] ?? '').toString())
            .where((x) => x.isNotEmpty)
            .toList(),
      );
  Future<void> addCategory(
    String uid, {
    required String type,
    required String name,
    int colorValue = 0xFF0F6B52,
    String iconName = 'category',
  }) => db.collection('users').doc(uid).collection('categories').add({
    'type': type,
    'name': name.trim(),
    'colorValue': colorValue,
    'iconName': iconName,
    'createdAt': FieldValue.serverTimestamp(),
  });
  Future<void> deleteCategory(String uid, String id) =>
      db.collection('users').doc(uid).collection('categories').doc(id).delete();

  Future<void> materializeRecurring(String uid) async {
    final snap = await _tx(
      uid,
    ).where('recurrence', whereIn: ['weekly', 'monthly']).get();
    final now = DateTime.now();
    for (final doc in snap.docs) {
      final source = TransactionEntry.fromDoc(doc);
      var next = source.recurrence == 'weekly'
          ? source.date.add(const Duration(days: 7))
          : DateTime(source.date.year, source.date.month + 1, source.date.day);
      var guard = 0;
      while (!next.isAfter(now) && guard++ < 120) {
        final key = '${doc.id}_${next.year}_${next.month}_${next.day}';
        final ref = _tx(uid).doc(key);
        final existing = await ref.get();
        if (!existing.exists) {
          await ref.set(
            TransactionEntry(
              id: key,
              userId: uid,
              type: source.type,
              amount: source.amount,
              category: source.category,
              description: source.description,
              date: next,
              recurrence: 'none',
            ).toMap(),
          );
        }
        next = source.recurrence == 'weekly'
            ? next.add(const Duration(days: 7))
            : DateTime(next.year, next.month + 1, next.day);
      }
    }
  }

  Future<void> deleteAllUserData(String uid) async {
    for (final name in [
      'transactions',
      'budgets',
      'savingsGoals',
      'categories',
      'devices',
    ]) {
      final snap = await db.collection('users').doc(uid).collection(name).get();
      for (var i = 0; i < snap.docs.length; i += 400) {
        final batch = db.batch();
        for (final d in snap.docs.skip(i).take(400)) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }
    final support = await db
        .collection('supportQueries')
        .where('userId', isEqualTo: uid)
        .get();
    for (final d in support.docs) {
      await d.reference.delete();
    }
    await db.collection('users').doc(uid).delete();
  }

  Future<void> sendSupport(
    String uid, {
    required String type,
    required String name,
    required String email,
    required String subject,
    required String message,
    int? rating,
  }) => db.collection('supportQueries').add({
    'userId': uid,
    'type': type,
    'name': name,
    'email': email,
    'subject': subject,
    'message': message,
    'rating': rating,
    'status': 'open',
    'createdAt': FieldValue.serverTimestamp(),
  });
}
