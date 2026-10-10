import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A sign-up or sign-in failure with a message that can be shown as is.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Email/password accounts.
abstract class AuthService {
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  const FirebaseAuthService();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User user = credential.user!;
      await user.updateDisplayName(name.trim());
      await FirebaseFirestore.instance.doc('users/${user.uid}').set({
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Make the new display name visible to listeners right away.
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  static String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Sign in instead.';
      case 'invalid-email':
        return 'Enter a valid email, e.g. name@narxoz.kz';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Wrong email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return e.message ?? 'Something went wrong. Try again.';
    }
  }
}
