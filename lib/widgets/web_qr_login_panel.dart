import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../qr_login/qr_session_host.dart';
import '../theme/app_colors.dart';

/// "Sign in with QR" panel for the web sign-in page.
///
/// Shows a fresh code, counts down, and signs the browser in once the phone
/// approves. The auth gate then swaps the page for the store.
class WebQrLoginPanel extends StatefulWidget {
  const WebQrLoginPanel({super.key});

  @override
  State<WebQrLoginPanel> createState() => _WebQrLoginPanelState();
}

enum _PanelState { loading, waiting, signingIn, expired, denied, error }

class _WebQrLoginPanelState extends State<WebQrLoginPanel> {
  final QrSessionHost host = QrSessionHost();

  _PanelState state = _PanelState.loading;
  String? qrData;
  String? sessionId;
  DateTime? expiresAt;
  int secondsLeft = 0;
  String errorMessage = '';

  Timer? countdown;
  StreamSubscription<QrSessionStatus>? statusSub;

  @override
  void initState() {
    super.initState();
    unawaited(newCode());
  }

  @override
  void dispose() {
    countdown?.cancel();
    unawaited(statusSub?.cancel());
    super.dispose();
  }

  Future<void> newCode() async {
    countdown?.cancel();
    await statusSub?.cancel();
    setState(() => state = _PanelState.loading);

    try {
      final session = await host.create();
      if (!mounted) return;
      final payload = session.payload;
      setState(() {
        sessionId = payload.sessionId;
        expiresAt = session.expiresAt;
        qrData = 'gamevault://login?session=${payload.sessionId}'
            '&device=${Uri.encodeComponent(payload.deviceName)}';
        state = _PanelState.waiting;
      });
      tick();
      countdown = Timer.periodic(const Duration(seconds: 1), (_) => tick());
      statusSub = host.watch(payload.sessionId).listen(onStatus);
    } catch (e) {
      showError("Couldn't create a sign-in code. Check your connection.");
    }
  }

  void tick() {
    final int left = expiresAt!.difference(DateTime.now()).inSeconds;
    if (left <= 0 && state == _PanelState.waiting) {
      countdown?.cancel();
      setState(() {
        secondsLeft = 0;
        state = _PanelState.expired;
      });
      return;
    }
    setState(() => secondsLeft = left.clamp(0, 999));
  }

  Future<void> onStatus(QrSessionStatus status) async {
    if (status == QrSessionStatus.denied) {
      countdown?.cancel();
      setState(() => state = _PanelState.denied);
    } else if (status == QrSessionStatus.approved &&
        state == _PanelState.waiting) {
      countdown?.cancel();
      setState(() => state = _PanelState.signingIn);
      try {
        await host.redeem(sessionId!);
        // The auth gate replaces this page with the store.
      } catch (e) {
        showError(
          'Approved, but signing in failed. Is the QR server running? '
          'Get a new code and try again.',
        );
      }
    }
  }

  void showError(String message) {
    if (!mounted) return;
    countdown?.cancel();
    setState(() {
      errorMessage = message;
      state = _PanelState.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.card),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SIGN IN WITH QR',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          buildCode(),
          const SizedBox(height: 16),
          buildStatus(),
          const SizedBox(height: 16),
          const Text(
            'Open GameVault on your phone, tap the QR button '
            'and point the camera at this code.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget buildCode() {
    final bool dimmed = state != _PanelState.waiting;
    return Container(
      width: 212,
      height: 212,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (qrData != null)
            AnimatedOpacity(
              opacity: dimmed ? 0.12 : 1,
              duration: const Duration(milliseconds: 200),
              child: QrImageView(
                data: qrData!,
                padding: EdgeInsets.zero,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.darkBackground,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.darkBackground,
                ),
              ),
            ),
          if (state == _PanelState.loading || state == _PanelState.signingIn)
            const CircularProgressIndicator(color: AppColors.background),
          if (state == _PanelState.expired ||
              state == _PanelState.denied ||
              state == _PanelState.error)
            ElevatedButton.icon(
              onPressed: newCode,
              icon: const Icon(Icons.refresh),
              label: const Text('New code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkBackground,
                foregroundColor: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildStatus() {
    const muted = TextStyle(color: AppColors.textSecondary, fontSize: 15);
    switch (state) {
      case _PanelState.loading:
        return const Text('Creating a code…', style: muted);
      case _PanelState.waiting:
        final String time =
            '${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}';
        return Text.rich(
          TextSpan(
            style: muted,
            children: [
              const TextSpan(text: 'Code expires in '),
              TextSpan(
                text: time,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case _PanelState.signingIn:
        return const Text(
          'Approved. Signing you in…',
          style: TextStyle(color: AppColors.success, fontSize: 15),
        );
      case _PanelState.expired:
        return const Text(
          'Code expired.',
          style: TextStyle(color: AppColors.error, fontSize: 15),
        );
      case _PanelState.denied:
        return const Text(
          'Sign-in was denied on the phone.',
          style: TextStyle(color: AppColors.error, fontSize: 15),
        );
      case _PanelState.error:
        return Text(
          errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.error, fontSize: 15),
        );
    }
  }
}
