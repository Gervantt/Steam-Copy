import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pill-shaped filter toggle or dropdown used above the catalog.
class FilterChipButton extends StatelessWidget {
  final String label;
  final bool active;
  final bool dropdown;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.dropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? AppColors.accent.withValues(alpha: 0.15) : AppColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: active ? AppColors.accent : Colors.transparent,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (active && !dropdown) ...[
                  const Icon(Icons.check, size: 16, color: AppColors.accent),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: active ? AppColors.accent : const Color(0xFFC7D5E0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (dropdown)
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: active ? AppColors.accent : AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Heading inside a filter bottom sheet.
class SheetTitle extends StatelessWidget {
  final String text;

  const SheetTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Selectable row inside a filter bottom sheet.
class SheetOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SheetOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.accent)
          : null,
      onTap: onTap,
    );
  }
}
