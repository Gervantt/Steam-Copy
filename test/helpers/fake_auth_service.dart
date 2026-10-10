import 'package:gamevault/auth/auth_service.dart';

class FakeAuthService implements AuthService {
  final List<String> calls = [];

  /// When set, sign-up and sign-in fail with this message.
  String? failWith;

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    calls.add('signUp:$email:$role');
    if (failWith != null) throw AuthException(failWith!);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    calls.add('signIn:$email');
    if (failWith != null) throw AuthException(failWith!);
  }

  @override
  Future<void> signOut() async => calls.add('signOut');
}
