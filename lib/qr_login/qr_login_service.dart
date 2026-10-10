import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'qr_login_payload.dart';

/// Why a QR sign-in request couldn't be approved, worded for the user.
class QrLoginException implements Exception {
  final String message;

  const QrLoginException(this.message);

  @override
  String toString() => message;
}

/// Approves or denies a QR sign-in request.
abstract class QrLoginService {
  Future<void> approve(QrLoginPayload payload);
  Future<void> deny(QrLoginPayload payload);
}

/// Fake backend for tests.
class MockQrLoginService implements QrLoginService {
  final Duration latency;

  const MockQrLoginService({this.latency = const Duration(seconds: 1)});

  @override
  Future<void> approve(QrLoginPayload payload) => Future.delayed(latency);

  @override
  Future<void> deny(QrLoginPayload payload) => Future.delayed(latency);
}

/// Answers the `qr_sessions/{id}` request created by the web sign-in page.
/// Firestore rules repeat these checks on the server.
class FirestoreQrLoginService implements QrLoginService {
  const FirestoreQrLoginService();

  static const String collection = 'qr_sessions';

  @override
  Future<void> approve(QrLoginPayload payload) => _answer(payload, true);

  @override
  Future<void> deny(QrLoginPayload payload) => _answer(payload, false);

  Future<void> _answer(QrLoginPayload payload, bool approved) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw const QrLoginException('Sign in on this phone first.');
    }

    final FirebaseFirestore db = FirebaseFirestore.instance;
    final DocumentReference<Map<String, dynamic>> ref =
        db.collection(collection).doc(payload.sessionId);

    try {
      await db.runTransaction((tx) async {
        final snapshot = await tx.get(ref);
        final Map<String, dynamic>? data = snapshot.data();
        if (data == null) {
          throw const QrLoginException(
            'This code is not valid. Scan the code on the screen again.',
          );
        }
        final Timestamp? expiresAt = data['expiresAt'] as Timestamp?;
        if (data['status'] != 'pending' ||
            expiresAt == null ||
            expiresAt.toDate().isBefore(DateTime.now())) {
          throw const QrLoginException('Code expired. Scan a new one.');
        }

        tx.update(
          ref,
          approved
              ? {
                  'status': 'approved',
                  'approvedBy': user.uid,
                  'approvedAt': FieldValue.serverTimestamp(),
                }
              : {'status': 'denied'},
        );
      });
    } on FirebaseException catch (e) {
      throw QrLoginException(
        e.code == 'permission-denied'
            ? 'Code expired. Scan a new one.'
            : "Couldn't reach GameVault. Check your connection.",
      );
    }
  }
}
