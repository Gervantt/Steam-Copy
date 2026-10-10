import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_colors.dart';
import 'game_image.dart';

String money(double value) => '\$${value.toStringAsFixed(2)}';

class DiscountBadge extends StatelessWidget {
  final int discountPercent;
  final double fontSize;

  const DiscountBadge({
    super.key,
    required this.discountPercent,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.45,
        vertical: fontSize * 0.2,
      ),
      decoration: BoxDecoration(
        color: AppColors.discountBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '-$discountPercent%',
        style: TextStyle(
          color: AppColors.discountText,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;
  final double size;

  const StarRating({super.key, required this.rating, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int star = 1; star <= 5; star++)
          Icon(
            rating >= star
                ? Icons.star
                : rating >= star - 0.5
                ? Icons.star_half
                : Icons.star_border,
            color: AppColors.star,
            size: size,
          ),
      ],
    );
  }
}

/// Old price struck through, then the current price in green.
class PriceTag extends StatelessWidget {
  final Game game;
  final double fontSize;
  final bool stacked;

  const PriceTag({
    super.key,
    required this.game,
    this.fontSize = 16,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget current = Text(
      money(game.price),
      style: TextStyle(
        color: game.onSale ? AppColors.discountText : AppColors.textPrimary,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
      ),
    );
    if (!game.onSale) return current;

    final Widget old = Text(
      money(game.oldPrice),
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: fontSize * 0.75,
        decoration: TextDecoration.lineThrough,
        decorationColor: AppColors.textSecondary,
      ),
    );
    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [old, current],
      );
    }
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [old, current],
    );
  }
}

/// Cover art with the title in caps along the bottom, like store capsules.
class CapsuleArt extends StatelessWidget {
  final Game game;
  final bool showDiscount;

  const CapsuleArt({super.key, required this.game, this.showDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GameImage(game: game),
        // Real store art already shows the game's logo; only the drawn
        // fallback needs the title written on it.
        if (game.steamAppId == null) ...[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Text(
              game.title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
        if (showDiscount && game.onSale)
          Positioned(
            left: 8,
            top: 8,
            child: DiscountBadge(
              discountPercent: game.discountPercent,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

/// Big card in the Store carousel.
class FeaturedCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const FeaturedCard({super.key, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      radius: 20,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameImage(game: game),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD9000000)],
                stops: [0.35, 1],
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0x99000000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'FEATURED',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        game.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${game.studio} · ${game.genres.first}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC7D5E0),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xB3000000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (game.onSale) ...[
                        DiscountBadge(
                          discountPercent: game.discountPercent,
                          fontSize: 15,
                        ),
                        const SizedBox(width: 8),
                      ],
                      PriceTag(game: game, fontSize: 16, stacked: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card in the horizontal "Special Offers" row.
class OfferCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const OfferCard({super.key, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      child: _Tappable(
        onTap: onTap,
        radius: 14,
        color: AppColors.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: CapsuleArt(game: game)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (game.onSale) ...[
                        DiscountBadge(
                          discountPercent: game.discountPercent,
                          fontSize: 12,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: PriceTag(
                          game: game,
                          fontSize: 14,
                          stacked: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row in "Top Sellers" and the Library.
class GameListTile extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  final Widget? trailing;

  const GameListTile({
    super.key,
    required this.game,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      radius: 14,
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 100,
                height: 47,
                child: GameImage(game: game),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    game.genres.take(3).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ?? PriceTag(game: game, fontSize: 16, stacked: true),
          ],
        ),
      ),
    );
  }
}

/// Card in the Browse grid.
class GameGridCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const GameGridCard({super.key, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      radius: 14,
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: CapsuleArt(game: game, showDiscount: true)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  game.genreLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                PriceTag(game: game, fontSize: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tappable extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double radius;
  final Color color;

  const _Tappable({
    required this.child,
    required this.onTap,
    required this.radius,
    this.color = AppColors.darkBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}
