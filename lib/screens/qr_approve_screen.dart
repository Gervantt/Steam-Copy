import 'dart:async';

import 'package:flutter/material.dart';

import '../qr_login/qr_login_payload.dart';
import '../qr_login/qr_login_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';

class QrApproveScreen extends StatefulWidget {
  final QrLoginPayload payload;
  final QrLoginService service;
  final Duration expiresIn;

  const QrApproveScreen({
    super.key,
    required this.payload,
    this.service = const FirestoreQrLoginService(),
    this.expiresIn = const Duration(seconds: 60),
  });

  @override
  State<QrApproveScreen> createState() => _QrApproveScreenState();
}

class _QrApproveScreenState extends State<QrApproveScreen> {
  Timer? countdown;
  late int secondsLeft = widget.expiresIn.inSeconds;
  bool approving = false;

  bool get expired => secondsLeft <= 0;
  bool get actionsEnabled => !expired && !approving;

  String get timeLeft {
    final int minutes = secondsLeft ~/ 60;
    final String seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Don't expire a request that's already being approved.
      if (approving) return;
      setState(() => secondsLeft--);
      if (expired) timer.cancel();
    });
  }

  @override
  void dispose() {
    countdown?.cancel();
    super.dispose();
  }

  Future<void> approve() async {
    setState(() => approving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await widget.service.approve(widget.payload);
    } catch (e) {
      if (!mounted) return;
      setState(() => approving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e is QrLoginException
                ? e.message
                : "Couldn't approve sign-in. Try again.",
          ),
        ),
      );
      return;
    }

    countdown?.cancel();
    navigator.popUntil((route) => route.isFirst);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Signed in on ${widget.payload.deviceName}')),
      );
  }

  void deny() {
    unawaited(widget.service.deny(widget.payload).catchError((_) {}));
    countdown?.cancel();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Sign-in request denied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: authBackground,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CircleIconButton(
                        icon: Icons.arrow_back,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            const Center(child: _DeviceBadge()),
                            const SizedBox(height: 24),
                            ...buildHeading(),
                            const SizedBox(height: 28),
                            buildInfoCard(),
                            const SizedBox(height: 20),
                            buildWarning(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildCountdown(),
                    const SizedBox(height: 16),
                    ...buildActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> buildHeading() {
    return const [
      Text(
        'Sign in on another device?',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      SizedBox(height: 10),
      Text(
        'QR code scanned. Approve to sign in to your GameVault account '
        'on this device.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
      ),
    ];
  }

  Widget buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.desktop_windows_outlined,
            label: 'Device',
            value: widget.payload.deviceName,
          ),
          const Divider(height: 1, color: Color(0x1FFFFFFF)),
          const _InfoRow(
            icon: Icons.language,
            label: 'Location',
            value: '[City, Country]',
          ),
          const Divider(height: 1, color: Color(0x1FFFFFFF)),
          const _InfoRow(
            icon: Icons.schedule,
            label: 'Requested',
            value: 'Just now',
          ),
        ],
      ),
    );
  }

  Widget buildWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.accent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Only approve if you are signing in yourself. GameVault will '
              'never ask you to scan a code for someone else.',
              style: TextStyle(color: Color(0xFFC7D5E0), fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCountdown() {
    if (expired) {
      return const Text(
        'Code expired. Scan again.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.error,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        children: [
          const TextSpan(text: 'Code expires in '),
          TextSpan(
            text: timeLeft,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  List<Widget> buildActions() {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const textStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.bold);
    const padding = EdgeInsets.symmetric(vertical: 16);

    return [
      ElevatedButton.icon(
        onPressed: actionsEnabled ? approve : null,
        icon: approving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.darkBackground,
                ),
              )
            : const Icon(Icons.check),
        label: Text(approving ? 'Approving…' : 'Approve sign-in'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.darkBackground,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.35),
          disabledForegroundColor: AppColors.darkBackground,
          padding: padding,
          textStyle: textStyle,
          shape: shape,
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: actionsEnabled ? deny : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(
            color: AppColors.error.withValues(
              alpha: actionsEnabled ? 0.5 : 0.2,
            ),
          ),
          padding: padding,
          textStyle: textStyle,
          shape: shape,
        ),
        child: const Text('Deny'),
      ),
    ];
  }
}

class _DeviceBadge extends StatelessWidget {
  const _DeviceBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 108,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.desktop_windows_outlined,
              size: 44,
              color: AppColors.accent,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.successBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 3),
              ),
              child: const Icon(
                Icons.check,
                size: 18,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
