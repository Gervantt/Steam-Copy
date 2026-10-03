import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GenreTags extends StatelessWidget {
  final List<String> genres;

  const GenreTags({super.key, required this.genres});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final String genre in genres)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              genre,
              style: const TextStyle(color: AppColors.accent, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
