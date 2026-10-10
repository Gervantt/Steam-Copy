import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom panel of the scanner: title, numbered steps and manual entry.
class QrInstructionsSheet extends StatelessWidget {
  final VoidCallback onEnterManually;
  final VoidCallback? onUseTestCode;

  static const List<String> steps = [
    'Open GameVault on your PC or the website',
    'Choose "Sign in with QR" on the login screen',
    'Scan the code and approve on this phone',
  ];

  const QrInstructionsSheet({
    super.key,
    required this.onEnterManually,
    this.onUseTestCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildTitle(),
              const SizedBox(height: 16),
              for (int i = 0; i < steps.length; i++)
                _Step(number: i + 1, text: steps[i]),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onEnterManually,
                icon: const Icon(Icons.keyboard_outlined),
                label: const Text('Enter code manually'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  backgroundColor: AppColors.inputFill,
                  side: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
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
              if (kDebugMode && onUseTestCode != null)
                TextButton.icon(
                  onPressed: onUseTestCode,
                  icon: const Icon(Icons.bug_report_outlined, size: 18),
                  label: const Text('Use test code (debug)'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTitle() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.desktop_windows_outlined,
              color: AppColors.accent),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign in with QR',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'No password needed on the other device',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.inputFill,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFC7D5E0), fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
