import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'qr_login_payload.dart';
import 'qr_login_service.dart';

enum QrSessionStatus { pending, approved, denied, redeemed, missing }

/// The web side of QR sign-in: creates a request in Firestore, shows it as a
/// QR code, and once a signed-in phone approves it, exchanges it for a login
/// via the local QR server (`server/index.js`).
class QrSessionHost {
  static const Duration lifetime = Duration(seconds: 60);

  /// Override with `--dart-define=QR_SERVER_URL=https://...`.
  static const String serverUrl = String.fromEnvironment(
    'QR_SERVER_URL',
    defaultValue: 'http://localhost:8787',
  );
  static const String _alphabet =
      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';

  final Random _random = Random.secure();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      FirebaseFirestore.instance.collection(FirestoreQrLoginService.collection);

  static String get deviceName {
    final String os = switch (defaultTargetPlatform) {
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
    return kIsWeb ? 'Web browser on $os' : '$os app';
  }

  /// Creates a new pending request and returns what goes into the QR code.
  Future<({QrLoginPayload payload, DateTime expiresAt})> create() async {
    // Rules only accept requests from a signed-in (here anonymous) browser,
    // so only this browser can redeem its own request.
    if (_auth.currentUser == null) await _auth.signInAnonymously();

    final String id = List.generate(
      32,
      (_) => _alphabet[_random.nextInt(_alphabet.length)],
    ).join();
    final DateTime expiresAt = DateTime.now().add(lifetime);

    await _sessions.doc(id).set({
      'webUid': _auth.currentUser!.uid,
      'device': deviceName,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });

    return (
      payload: QrLoginPayload(sessionId: id, deviceName: deviceName),
      expiresAt: expiresAt,
    );
  }

  Stream<QrSessionStatus> watch(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map((snapshot) {
      final Object? status = snapshot.data()?['status'];
      return QrSessionStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => QrSessionStatus.missing,
      );
    });
  }

  /// Signs this browser in as the account that approved [sessionId].
  Future<void> redeem(String sessionId) async {
    final String? idToken = await _auth.currentUser?.getIdToken();
    final http.Response response = await http.post(
      Uri.parse('$serverUrl/redeem'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'sessionId': sessionId}),
    );
    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'QR server error ${response.statusCode}');
    }
    await _auth.signInWithCustomToken(body['token'] as String);
  }
}
