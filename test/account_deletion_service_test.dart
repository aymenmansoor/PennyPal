import 'package:flutter_test/flutter_test.dart';
import 'package:pennypal/services/account_deletion_service.dart';

class _FakeDeletionAuth implements AccountDeletionAuth {
  Object? reauthError;
  Object? deleteError;
  final calls = <String>[];

  @override
  Future<void> reauthenticate({String? password}) async {
    calls.add('reauth:${password ?? ''}');
    if (reauthError != null) throw reauthError!;
  }

  @override
  Future<void> deleteCurrentUser() async {
    calls.add('delete');
    if (deleteError != null) throw deleteError!;
  }
}

void main() {
  test('does not attempt account deletion when reauthentication fails', () async {
    final auth = _FakeDeletionAuth()..reauthError = StateError('bad password');

    await expectLater(
      AccountDeletionService(auth).delete(password: 'wrong'),
      throwsA(isA<StateError>()),
    );

    expect(auth.calls, ['reauth:wrong']);
  });

  test('deletes Auth only after reauthentication succeeds', () async {
    final auth = _FakeDeletionAuth();

    await AccountDeletionService(auth).delete(password: 'correct');

    expect(auth.calls, ['reauth:correct', 'delete']);
  });

  test('surfaces Auth deletion failure without running client cleanup', () async {
    final auth = _FakeDeletionAuth()..deleteError = StateError('requires recent login');

    await expectLater(
      AccountDeletionService(auth).delete(),
      throwsA(isA<StateError>()),
    );

    expect(auth.calls, ['reauth:', 'delete']);
  });
}
