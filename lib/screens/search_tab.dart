import 'package:flutter/material.dart';

import '../data/new_releases.dart';
import '../data/store_scope.dart';
import '../models/game.dart';
import '../theme/app_colors.dart';
import '../widgets/catalog_items.dart';
import '../widgets/filter_widgets.dart';
import '../widgets/game_cards.dart';
import 'game_detail_screen.dart';

enum SortOrder {
  newest('Newest'),
  topRated('Top rated'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low'),
  discount('Biggest discount');

  final String label;
  const SortOrder(this.label);
}

/// Browse: the game catalog as a list feed or a 2-column grid.
///
/// Pull down to fetch a new release (added at the top), swipe an item
/// right-to-left to remove it, and undo from the SnackBar.
class SearchTab extends StatefulWidget {
  final FocusNode? focusNode;

  /// Simulated network delay for pull-to-refresh.
  final Duration refreshDelay;

  const SearchTab({
    super.key,
    this.focusNode,
    this.refreshDelay = const Duration(milliseconds: 1500),
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  static const List<double?> priceLimits = [null, 10, 20, 40];

  final TextEditingController queryController = TextEditingController();

  /// The catalog shown on this screen. Starts as a copy of the store's
  /// games; refresh, swipe and undo change only this list.
  List<Game> items = [];
  bool seeded = false;
  bool gridView = false;
  int refreshCount = 0;

  String? genre;
  double? maxPrice;
  bool onSaleOnly = false;
  SortOrder sort = SortOrder.newest;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final StoreController store = StoreScope.of(context);
    if (!seeded && store.loaded) {
      seeded = true;
      items = List.of(store.catalog);
    }
  }

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  List<Game> results() {
    final String q = queryController.text.trim().toLowerCase();
    final List<Game> found = items.where((g) {
      if (q.isNotEmpty &&
          !g.title.toLowerCase().contains(q) &&
          !g.studio.toLowerCase().contains(q) &&
          !g.genres.any((x) => x.toLowerCase().contains(q))) {
        return false;
      }
      if (genre != null && !g.genres.contains(genre)) return false;
      if (maxPrice != null && g.price > maxPrice!) return false;
      if (onSaleOnly && !g.onSale) return false;
      return true;
    }).toList();

    switch (sort) {
      case SortOrder.newest:
        break; // Catalog order: refreshed items are already on top.
      case SortOrder.topRated:
        found.sort((a, b) => b.rating.compareTo(a.rating));
      case SortOrder.priceLow:
        found.sort((a, b) => a.price.compareTo(b.price));
      case SortOrder.priceHigh:
        found.sort((a, b) => b.price.compareTo(a.price));
      case SortOrder.discount:
        found.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    }
    return found;
  }

  /// Pull-to-refresh: waits like a network call, then adds a game at the top.
  Future<void> refresh() async {
    await Future<void>.delayed(widget.refreshDelay);
    if (!mounted) return;
    final StoreController store = StoreScope.of(context);
    if (store.games.isEmpty) return;
    setState(() {
      refreshCount++;
      items.insert(
        0,
        nextNewRelease(
          allGames: store.games,
          shown: items,
          refreshCount: refreshCount,
        ),
      );
    });
  }

  /// Swipe-to-delete: removes the game and offers to put it back.
  void remove(Game game) {
    final int index = items.indexOf(game);
    if (index < 0) return;
    setState(() => items.removeAt(index));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('${game.title} removed'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppColors.accent,
            onPressed: () {
              if (!mounted) return;
              // Back to where it was, even if the list changed meanwhile.
              setState(() => items.insert(index.clamp(0, items.length), game));
            },
          ),
        ),
      );
  }

  void resetCatalog() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      items = List.of(StoreScope.of(context).catalog);
      refreshCount = 0;
    });
  }

  Future<void> pickGenre() async {
    final List<String> all = {for (final g in items) ...g.genres}.toList()
      ..sort();
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.darkBackground,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const SheetTitle('Genre'),
            SheetOption(
              label: 'Any genre',
              selected: genre == null,
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final String g in all)
              SheetOption(
                label: g,
                selected: genre == g,
                onTap: () => Navigator.pop(context, g),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => genre = picked.isEmpty ? null : picked);
  }

  Future<void> pickPrice() async {
    final double? picked = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.darkBackground,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetTitle('Price'),
            for (final double? limit in priceLimits)
              SheetOption(
                label: limit == null ? 'Any price' : 'Under \$${limit.toInt()}',
                selected: maxPrice == limit,
                onTap: () => Navigator.pop(context, limit ?? -1),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => maxPrice = picked < 0 ? null : picked);
  }

  void resetFilters() => setState(() {
        genre = null;
        maxPrice = null;
        onSaleOnly = false;
      });

  @override
  Widget build(BuildContext context) {
    final StoreController store = StoreScope.of(context);
    final List<Game> found = results();
    final bool filtered = genre != null || maxPrice != null || onSaleOnly;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildTitleBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: buildSearchField()),
                  const SizedBox(width: 10),
                  Material(
                    color: filtered ? AppColors.accent : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      tooltip: 'Reset filters',
                      onPressed: filtered ? resetFilters : null,
                      icon: Icon(
                        Icons.tune,
                        color: filtered
                            ? AppColors.darkBackground
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChipButton(
                    label: genre ?? 'Genre',
                    active: genre != null,
                    dropdown: true,
                    onTap: pickGenre,
                  ),
                  FilterChipButton(
                    label: maxPrice == null
                        ? 'Price'
                        : 'Under \$${maxPrice!.toInt()}',
                    active: maxPrice != null,
                    dropdown: true,
                    onTap: pickPrice,
                  ),
                  FilterChipButton(
                    label: 'On sale',
                    active: onSaleOnly,
                    onTap: () => setState(() => onSaleOnly = !onSaleOnly),
                  ),
                ],
              ),
            ),
            buildResultsBar(found.length),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: buildCatalog(store, found),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTitleBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Browse',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: gridView ? 'Show as list' : 'Show as grid',
            onPressed: () => setState(() => gridView = !gridView),
            icon: Icon(
              gridView ? Icons.view_list : Icons.grid_view,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildResultsBar(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count results',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ),
          PopupMenuButton<SortOrder>(
            initialValue: sort,
            color: AppColors.inputFill,
            onSelected: (s) => setState(() => sort = s),
            itemBuilder: (_) => [
              for (final SortOrder s in SortOrder.values)
                PopupMenuItem(value: s, child: Text(s.label)),
            ],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sort: ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    sort.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchField() {
    return TextField(
      controller: queryController,
      focusNode: widget.focusNode,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Search games, studios, tags',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: queryController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => setState(queryController.clear),
              ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget buildCatalog(StoreController store, List<Game> found) {
    if (!store.loaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    // Always scrollable, so pull-to-refresh also works on short lists
    // and on the empty state.
    const ScrollPhysics physics = AlwaysScrollableScrollPhysics();
    final Widget content;
    if (items.isEmpty) {
      content = ListView(
        physics: physics,
        children: [CatalogEmptyState(onReset: resetCatalog)],
      );
    } else if (found.isEmpty) {
      content = ListView(
        physics: physics,
        padding: const EdgeInsets.all(32),
        children: const [
          Text(
            'Nothing matches. Try another search or reset the filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      );
    } else if (gridView) {
      content = GridView.builder(
        physics: physics,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: found.length,
        itemBuilder: (context, i) => dismissible(
          found[i],
          GameGridCard(
            game: found[i],
            onTap: () => GameDetailScreen.open(context, found[i]),
          ),
          radius: BorderRadius.circular(14),
        ),
      );
    } else {
      content = ListView.separated(
        physics: physics,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: found.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          thickness: 0.5,
          indent: 82,
          color: AppColors.card,
        ),
        itemBuilder: (context, i) => dismissible(
          found[i],
          CatalogListRow(
            game: found[i],
            onTap: () => GameDetailScreen.open(context, found[i]),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      child: content,
    );
  }

  Widget dismissible(Game game, Widget child, {BorderRadius? radius}) {
    return Dismissible(
      key: ValueKey(game.id),
      direction: DismissDirection.endToStart,
      background: SwipeDeleteBackground(
        borderRadius: radius ?? BorderRadius.zero,
      ),
      onDismissed: (_) => remove(game),
      child: child,
    );
  }
}
