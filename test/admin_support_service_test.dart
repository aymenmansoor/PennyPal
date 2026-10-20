import 'package:flutter_test/flutter_test.dart';
import 'package:pennypal/services/admin_support_service.dart';

class _FakeSupportRepository implements AdminSupportRepository {
  Object? updateError;
  Object? auditError;
  final updates = <Map<String, dynamic>>[];
  final audits = <String>[];

  @override
  Future<void> updateSupport(String id, Map<String, dynamic> values) async {
    if (updateError != null) throw updateError!;
    updates.add({'id': id, ...values});
  }

  @override
  Future<void> writeAudit(String action, String targetId) async {
    if (auditError != null) throw auditError!;
    audits.add('$action:$targetId');
  }
}

void main() {
  test('saves a trimmed reply and writes its audit event', () async {
    final repository = _FakeSupportRepository();

    await AdminSupportService(repository).saveReply(
      supportId: 'support-1',
      reply: '  We have fixed this.  ',
    );

    expect(repository.updates, hasLength(1));
    expect(repository.updates.single['adminReply'], 'We have fixed this.');
    expect(repository.audits, ['reply_support:support-1']);
  });

  test('does not write an audit event when the support update fails', () async {
    final repository = _FakeSupportRepository()..updateError = StateError('offline');

    final error = await captureException(
      AdminSupportService(repository).saveReply(
        supportId: 'support-1',
        reply: 'A reply',
      ),
    );

    expect(error, isA<AdminSupportException>());
    expect((error as AdminSupportException).supportUpdated, isFalse);
    expect(repository.audits, isEmpty);
  });

  test('reports an audit failure without hiding a saved reply', () async {
    final repository = _FakeSupportRepository()..auditError = StateError('rules');

    final error = await captureException(
      AdminSupportService(repository).saveReply(
        supportId: 'support-1',
        reply: 'A reply',
      ),
    );

    expect(error, isA<AdminSupportException>());
    expect((error as AdminSupportException).supportUpdated, isTrue);
    expect(repository.updates, hasLength(1));
  });

  test('rejects an empty reply before touching Firestore', () async {
    final repository = _FakeSupportRepository();

    final error = await captureException(
      AdminSupportService(repository).saveReply(
        supportId: 'support-1',
        reply: '   ',
      ),
    );

    expect(error, isA<AdminSupportException>());
    expect(repository.updates, isEmpty);
    expect(repository.audits, isEmpty);
  });
}

Future<Object?> captureException(Future<void> operation) async {
  try {
    await operation;
    return null;
  } catch (error) {
    return error;
  }
}
