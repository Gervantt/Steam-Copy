import 'package:flutter/material.dart';

import '../data/store_repository.dart';
import '../data/store_scope.dart';
import '../models/game.dart';
import '../theme/app_colors.dart';
import '../widgets/game_image.dart';
import '../widgets/game_cards.dart';
import 'game_detail_screen.dart';

/// Tab 2 (Favorites): saved games plus the cart and checkout.
class WishlistTab extends StatefulWidget {
  const WishlistTab({super.key});

  @override
  State<WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends State<WishlistTab> {
  bool checkingOut = false;

  Future<void> checkout(StoreController store) async {
    final int count = store.cartGames.length;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => checkingOut = true);
    try {
      await store.checkout();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              count == 1
                  ? 'Purchased 1 game. Find it in Profile → Library.'
                  : 'Purchased $count games. Find them in Profile → Library.',
            ),
          ),
        );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Checkout failed. Check your connection.")),
      );
    } finally {
      if (mounted) setState(() => checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final StoreController store = StoreScope.of(context);
    final List<Game> wishlist = store.wishlistGames;
    final List<Game> cart = store.cartGames;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text(
              'Wishlist & Cart',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            _Header(title: 'Wishlist', count: '${wishlist.length}'),
            if (wishlist.isEmpty)
              const _Hint(
                'Tap the bookmark on any game to save it here.',
              )
            else
              for (final Game g in wishlist)
                _WishlistRow(game: g, store: store),
            const SizedBox(height: 16),
            _Header(
              title: 'Cart',
              count: store.cartCount == 1 ? '1 item' : '${store.cartCount} items',
              action: cart.isEmpty ? null : 'Clear',
              onAction: store.clearCart,
            ),
            if (cart.isEmpty)
              const _Hint('Your cart is empty. Add games from the store.')
            else ...[
              for (final Game g in cart)
                _CartRow(game: g, qty: store.cart[g.id] ?? 1, store: store),
              const SizedBox(height: 4),
              _Summary(store: store),
            ],
          ],
        ),
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : _CheckoutBar(
              total: store.cartTotal,
              busy: checkingOut,
              onCheckout: () => checkout(store),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String count;
  final String? action;
  final VoidCallback? onAction;

  const _Header({
    required this.title,
    required this.count,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
    );
  }
}

/// Shared row layout: thumbnail, title + price, trailing controls.
class _Row extends StatelessWidget {
  final Game game;
  final Widget price;
  final Widget trailing;

  const _Row({required this.game, required this.price, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => GameDetailScreen.open(context, game),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 84,
                    height: 40,
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
                      price,
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WishlistRow extends StatelessWidget {
  final Game game;
  final StoreController store;

  const _WishlistRow({required this.game, required this.store});

  @override
  Widget build(BuildContext context) {
    final bool owned = store.owns(game);
    return _Row(
      game: game,
      price: Row(
        children: [
          if (game.onSale) ...[
            DiscountBadge(discountPercent: game.discountPercent, fontSize: 11),
            const SizedBox(width: 6),
          ],
          Text(
            money(game.price),
            style: TextStyle(
              color: game.onSale ? AppColors.discountText : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (owned)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Owned',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            _SquareButton(
              icon: store.inCart(game)
                  ? Icons.shopping_cart
                  : Icons.add_shopping_cart,
              tooltip: 'Add ${game.title} to cart',
              accent: true,
              onPressed: () => store.addToCart(game),
            ),
          const SizedBox(width: 8),
          _SquareButton(
            icon: Icons.close,
            tooltip: 'Remove ${game.title} from wishlist',
            onPressed: () => store.toggleWishlist(game),
          ),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final Game game;
  final int qty;
  final StoreController store;

  const _CartRow({required this.game, required this.qty, required this.store});

  @override
  Widget build(BuildContext context) {
    return _Row(
      game: game,
      price: PriceTag(game: game, fontSize: 15),
      trailing: Container(
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Remove one',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove, color: AppColors.textPrimary, size: 18),
              onPressed: () => store.setQuantity(game, qty - 1),
            ),
            Text(
              '$qty',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            IconButton(
              tooltip: 'Add one',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add, color: AppColors.accent, size: 18),
              onPressed:
                  qty >= maxCartQuantity ? null : () => store.setQuantity(game, qty + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final StoreController store;

  const _Summary({required this.store});

  @override
  Widget build(BuildContext context) {
    Widget line(String label, String value, Color color) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary)),
              const Spacer(),
              Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.card),
      ),
      child: Column(
        children: [
          line('Subtotal', money(store.cartSubtotal), AppColors.textPrimary),
          line('Discounts', '−${money(store.cartDiscount)}', AppColors.discountText),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final double total;
  final bool busy;
  final VoidCallback onCheckout;

  const _CheckoutBar({
    required this.total,
    required this.busy,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBackground,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Text(
                money(total),
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
              onPressed: busy ? null : onCheckout,
              icon: const Icon(Icons.lock_outline),
              label: Text(busy ? 'Processing…' : 'Checkout'),
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

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool accent;

  const _SquareButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent
          ? AppColors.accent.withValues(alpha: 0.15)
          : AppColors.darkBackground,
      borderRadius: BorderRadius.circular(10),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          icon,
          size: 20,
          color: accent ? AppColors.accent : AppColors.textSecondary,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
