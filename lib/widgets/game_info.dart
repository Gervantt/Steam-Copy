import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_colors.dart';

class GameInfo extends StatelessWidget {
  final Game game;

  const GameInfo({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          game.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          game.developer,
          style: const TextStyle(color: AppColors.accent, fontSize: 15),
        ),
        const SizedBox(height: 12),

        // Rating
        Row(
          children: [
            StarRating(rating: game.rating),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${game.rating}  (${game.reviewCount} reviews)',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Price
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              DiscountBadge(discountPercent: game.discountPercent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${game.oldPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '\$${game.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.discountText,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;

  const StarRating({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    List<Widget> stars = [];

    for (int starNumber = 1; starNumber <= 5; starNumber++) {
      IconData icon;
      if (rating >= starNumber) {
        icon = Icons.star;
      } else if (rating >= starNumber - 0.5) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }
      stars.add(Icon(icon, color: AppColors.star, size: 20));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: stars,
    );
  }
}

class DiscountBadge extends StatelessWidget {
  final int discountPercent;

  const DiscountBadge({super.key, required this.discountPercent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.discountBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '-$discountPercent%',
        style: const TextStyle(
          color: AppColors.discountText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
