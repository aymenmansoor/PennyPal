import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

abstract class AccountDeletionAuth {
  Future<void> reauthenticate({String? password});

  Future<void> deleteCurrentUser();
}

class FirebaseAccountDeletionAuth implements AccountDeletionAuth {
  @override
  Future<void> reauthenticate({String? password}) {
    return AuthService.instance.reauthenticate(password: password);
  }

  @override
  Future<void> deleteCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in account is available.',
      );
    }
    await user.delete();
  }
}

class AccountDeletionService {
  final AccountDeletionAuth auth;

  const AccountDeletionService(this.auth);

  factory AccountDeletionService.firebase() => AccountDeletionService(
        FirebaseAccountDeletionAuth(),
      );

  Future<void> delete({String? password}) async {
    // Reauthentication must succeed before the Auth deletion is attempted.
    await auth.reauthenticate(password: password);
    await auth.deleteCurrentUser();
  }
}
