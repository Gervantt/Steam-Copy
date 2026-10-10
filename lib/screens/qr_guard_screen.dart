import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import 'qr_scanner_screen.dart';

/// The "Guard" tab, like Steam Guard: one big action to approve a sign-in
/// on another device by scanning its QR code.
class QrGuardScreen extends StatelessWidget {
  final String name;

  const QrGuardScreen({super.key, required this.name});

  void openScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const QrScannerScreen()),
    );
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const Text(
                    'GameVault Guard',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Signed in as $name',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  buildScanCard(context),
                  const SizedBox(height: 28),
                  const Text(
                    'HOW IT WORKS',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _Step(
                    icon: Icons.computer,
                    text: 'Open GameVault on the computer. The sign-in page '
                        'shows a QR code.',
                  ),
                  const _Step(
                    icon: Icons.qr_code_scanner,
                    text: 'Tap Scan QR code here and point the camera at it.',
                  ),
                  const _Step(
                    icon: Icons.check_circle_outline,
                    text: 'Check the device and tap Approve. The computer '
                        'signs in to your account.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildScanCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_2,
              size: 64,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sign in on another device',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan the QR code shown on the GameVault sign-in page. '
            'No password needed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => openScanner(context),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.darkBackground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Step({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFC7D5E0),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
