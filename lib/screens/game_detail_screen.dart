import 'package:flutter/material.dart';

import '../data/store_scope.dart';
import '../models/game.dart';
import '../theme/app_colors.dart';
import '../widgets/game_image.dart';
import '../widgets/game_cards.dart';

/// Full page for one game. Opened with [GameDetailScreen.open], which passes
/// the whole [Game] as the route's arguments.
class GameDetailScreen extends StatelessWidget {
  static const String routeName = '/game';

  const GameDetailScreen({super.key});

  /// Pushes the detail page for [game]. The store controller is handed over
  /// explicitly because pushed routes sit beside the tabs, not under them.
  static Future<void> open(BuildContext context, Game game) {
    final StoreController store = StoreScope.of(context);
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName, arguments: game),
        builder: (_) => StoreScope(
          controller: store,
          child: const GameDetailScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Game game = ModalRoute.of(context)!.settings.arguments! as Game;
    final StoreController store = StoreScope.of(context);
    final bool wishlisted = store.isWishlisted(game);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.darkBackground,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: _RoundButton(
                icon: Icons.arrow_back,
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: _RoundButton(
                  icon: wishlisted ? Icons.bookmark : Icons.bookmark_border,
                  tooltip: wishlisted ? 'Remove from wishlist' : 'Add to wishlist',
                  color: wishlisted ? AppColors.accent : AppColors.textPrimary,
                  onPressed: () => store.toggleWishlist(game),
                ),
              ),
              const SizedBox(width: 6),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  GameImage(game: game, hero: true),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.background],
                      ),
                    ),
                  ),
                  if (game.onSale)
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: DiscountBadge(discountPercent: game.discountPercent),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: _Details(game: game),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BuyBar(game: game),
    );
  }
}

class _Details extends StatelessWidget {
  final Game game;

  const _Details({required this.game});

  static const TextStyle _heading = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          game.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          game.studio,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            StarRating(rating: game.rating),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${game.rating}  (${_thousands(game.reviewCount)} reviews)',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (game.onSale) ...[
                DiscountBadge(discountPercent: game.discountPercent),
                const SizedBox(width: 16),
              ],
              PriceTag(game: game, fontSize: 26, stacked: true),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Genres', style: _heading),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final String genre in game.genres)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  genre,
                  style: const TextStyle(color: AppColors.accent, fontSize: 14),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('About This Game', style: _heading),
        const SizedBox(height: 8),
        Text(
          game.description,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to store'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.card),
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _thousands(int n) => n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
}

class _BuyBar extends StatelessWidget {
  final Game game;

  const _BuyBar({required this.game});

  void addToCart(BuildContext context, StoreController store) {
    store.addToCart(game);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.card,
          content: Text(
            '${game.title} added to cart',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final StoreController store = StoreScope.of(context);
    final bool owned = store.owns(game);
    final int inCart = store.cart[game.id] ?? 0;

    return Container(
      color: AppColors.darkBackground,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        money(game.price),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: owned ? null : () => addToCart(context, store),
                      icon: Icon(
                        owned ? Icons.check : Icons.shopping_cart_outlined,
                      ),
                      label: Text(
                        owned
                            ? 'In library'
                            : inCart > 0
                                ? 'Add to Cart ($inCart)'
                                : 'Add to Cart',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.darkBackground,
                        disabledBackgroundColor: AppColors.card,
                        disabledForegroundColor: AppColors.success,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x8C000000),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}
