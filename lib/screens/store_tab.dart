import 'package:flutter/material.dart';

import '../data/store_scope.dart';
import '../models/game.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/game_cards.dart';
import 'game_detail_screen.dart';

/// Tab 1 (Feed): featured carousel, genre filter, offers and top sellers.
class StoreTab extends StatefulWidget {
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenCart;

  const StoreTab({
    super.key,
    required this.onOpenSearch,
    required this.onOpenCart,
  });

  @override
  State<StoreTab> createState() => _StoreTabState();
}

class _StoreTabState extends State<StoreTab> {
  static const String all = 'All';
  static const List<String> genres = [
    all,
    'Action',
    'RPG',
    'Strategy',
    'Indie',
    'Racing',
    'Adventure',
  ];

  final PageController pageController = PageController(viewportFraction: 0.88);
  int page = 0;
  String genre = all;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  bool matches(Game g) => genre == all || g.genres.contains(genre);

  void open(Game game) => GameDetailScreen.open(context, game);

  @override
  Widget build(BuildContext context) {
    final StoreController store = StoreScope.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            buildHeader(store.cartCount),
            Expanded(child: buildBody(store)),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(int cartCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          // Flexible lets the logo shrink on narrow phones.
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: GameVaultLogo(),
            ),
          ),
          CircleIconButton(
            icon: Icons.search,
            tooltip: 'Search',
            background: AppColors.card,
            size: 44,
            onPressed: widget.onOpenSearch,
          ),
          const SizedBox(width: 10),
          Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            backgroundColor: AppColors.accent,
            textColor: AppColors.darkBackground,
            child: CircleIconButton(
              icon: Icons.shopping_cart_outlined,
              tooltip: 'Cart',
              background: AppColors.card,
              size: 44,
              onPressed: widget.onOpenCart,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBody(StoreController store) {
    if (!store.loaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (store.games.isEmpty) {
      return const _EmptyState(
        icon: Icons.videogame_asset_off_outlined,
        text: 'No games in the store yet.',
      );
    }

    final List<Game> featured = store.games.where((g) => g.featured).toList();
    final List<Game> offers =
        store.games.where((g) => g.onSale && matches(g)).toList();
    final List<Game> top =
        store.games.where((g) => g.topSeller && matches(g)).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (featured.isNotEmpty) ...[
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: pageController,
              padEnds: false,
              itemCount: featured.length,
              onPageChanged: (i) => setState(() => page = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: FeaturedCard(
                  game: featured[i],
                  onTap: () => open(featured[i]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Dots(count: featured.length, active: page),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: genres.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _GenreChip(
              label: genres[i],
              selected: genres[i] == genre,
              onTap: () => setState(() => genre = genres[i]),
            ),
          ),
        ),
        _SectionTitle(title: 'Special Offers', onSeeAll: widget.onOpenSearch),
        if (offers.isEmpty)
          const _EmptyState(text: 'No offers in this genre right now.')
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: offers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) =>
                  OfferCard(game: offers[i], onTap: () => open(offers[i])),
            ),
          ),
        _SectionTitle(title: 'Top Sellers', onSeeAll: widget.onOpenSearch),
        if (top.isEmpty)
          const _EmptyState(text: 'No top sellers in this genre.')
        else
          for (final Game g in top)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: GameListTile(game: g, onTap: () => open(g)),
            ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;

  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active ? AppColors.accent : AppColors.card,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.darkBackground : const Color(0xFFC7D5E0),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionTitle({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              'See all',
              style: TextStyle(
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

class _EmptyState extends StatelessWidget {
  final IconData? icon;
  final String text;

  const _EmptyState({this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
