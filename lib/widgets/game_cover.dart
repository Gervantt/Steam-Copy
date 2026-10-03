import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'game_info.dart';

class GameCover extends StatelessWidget {
  final String imageUrl;
  final int discountPercent;
  final bool isBookmarked;
  final VoidCallback onBookmarkPressed;

  const GameCover({
    super.key,
    required this.imageUrl,
    required this.discountPercent,
    required this.isBookmarked,
    required this.onBookmarkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover Image
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.card,
                child: const Icon(
                  Icons.videogame_asset,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),

          // Dark Gradient
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 100,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.background],
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 12,
            left: 12,
            child: buildRoundButton(
              icon: Icons.arrow_back,
              color: AppColors.textPrimary,
              onPressed: () {
                Navigator.maybePop(context);
              },
            ),
          ),

          // Bookmark Button
          Positioned(
            top: 12,
            right: 12,
            child: buildRoundButton(
              icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppColors.accent : AppColors.textPrimary,
              onPressed: onBookmarkPressed,
            ),
          ),

          // Discount Badge
          Positioned(
            left: 16,
            bottom: 16,
            child: DiscountBadge(discountPercent: discountPercent),
          ),
        ],
      ),
    );
  }

  Widget buildRoundButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}
