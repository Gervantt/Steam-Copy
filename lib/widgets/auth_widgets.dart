import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Background gradient shared by the auth screens.
const BoxDecoration authBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.center,
    colors: [AppColors.headerGlow, AppColors.background],
  ),
);

class GameVaultLogo extends StatelessWidget {
  const GameVaultLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, AppColors.card],
            ),
          ),
          child: const Icon(
            Icons.camera,
            size: 18,
            color: AppColors.darkBackground,
          ),
        ),
        const SizedBox(width: 8),
        const Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                    text: 'Game',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  TextSpan(
                    text: 'Vault',
                    style: TextStyle(color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Round icon button used in the auth headers (back, QR, close, torch).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;
  final Color background;
  final Color foreground;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 40,
    this.background = AppColors.darkBackground,
    this.foreground = AppColors.textPrimary,
  });

  /// Accent-tinted variant, e.g. the QR sign-in button.
  const CircleIconButton.accent({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 40,
  })  : background = const Color(0x2E66C0F4),
        foreground = AppColors.accent;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.5, color: foreground),
          ),
        ),
      ),
    );
  }
}

/// Filled text field with leading icon, label above and error/valid states.
class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final String? errorText;
  final bool showValid;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.errorText,
    this.showValid = false,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null;
    final Color tint = hasError ? AppColors.error : AppColors.textSecondary;

    Widget? suffix;
    if (onToggleObscure != null) {
      suffix = IconButton(
        tooltip: obscure ? 'Show password' : 'Hide password',
        onPressed: onToggleObscure,
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
        ),
      );
    } else if (showValid) {
      suffix = const Icon(Icons.check, color: AppColors.success);
    }

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: hasError ? AppColors.error : const Color(0xFFC7D5E0),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: hasError ? AppColors.errorFill : AppColors.inputFill,
            prefixIcon: Icon(icon, color: tint, size: 20),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: hasError
                ? border(AppColors.error)
                : border(Colors.transparent),
            focusedBorder: border(
              hasError ? AppColors.error : AppColors.accent,
              1.5,
            ),
          ),
        ),
        if (hasError) FieldError(errorText!),
      ],
    );
  }
}

class FieldError extends StatelessWidget {
  final String message;

  const FieldError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: AppColors.error),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
