import 'package:flutter/material.dart';

import '../data/store_scope.dart';
import '../models/game.dart';
import '../theme/app_colors.dart';
import '../widgets/game_cards.dart';
import 'game_detail_screen.dart';

enum SortOrder {
  topRated('Top rated'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low'),
  discount('Biggest discount');

  final String label;
  const SortOrder(this.label);
}

/// Browse: search, filters, sort and a grid of results.
class SearchTab extends StatefulWidget {
  final FocusNode? focusNode;

  const SearchTab({super.key, this.focusNode});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  static const List<double?> priceLimits = [null, 10, 20, 40];

  final TextEditingController queryController = TextEditingController();

  String? genre;
  double? maxPrice;
  bool onSaleOnly = false;
  SortOrder sort = SortOrder.topRated;

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  List<Game> results(List<Game> games) {
    final String q = queryController.text.trim().toLowerCase();
    final List<Game> found = games.where((g) {
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

  Future<void> pickGenre(List<Game> games) async {
    final List<String> all = {for (final g in games) ...g.genres}.toList()
      ..sort();
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.darkBackground,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const _SheetTitle('Genre'),
            _SheetOption(
              label: 'Any genre',
              selected: genre == null,
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final String g in all)
              _SheetOption(
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
            const _SheetTitle('Price'),
            for (final double? limit in priceLimits)
              _SheetOption(
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
    final List<Game> found = results(store.games);
    final bool filtered = genre != null || maxPrice != null || onSaleOnly;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                'Browse',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
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
                  _FilterChip(
                    label: genre ?? 'Genre',
                    active: genre != null,
                    dropdown: true,
                    onTap: () => pickGenre(store.games),
                  ),
                  _FilterChip(
                    label: maxPrice == null
                        ? 'Price'
                        : 'Under \$${maxPrice!.toInt()}',
                    active: maxPrice != null,
                    dropdown: true,
                    onTap: pickPrice,
                  ),
                  _FilterChip(
                    label: 'On sale',
                    active: onSaleOnly,
                    onTap: () => setState(() => onSaleOnly = !onSaleOnly),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${found.length} results',
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
            ),
            Expanded(child: buildGrid(store, found)),
          ],
        ),
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

  Widget buildGrid(StoreController store, List<Game> found) {
    if (!store.loaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (found.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nothing matches. Try another search or reset the filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: found.length,
      itemBuilder: (context, i) => GameGridCard(
        game: found[i],
        onTap: () => GameDetailScreen.open(context, found[i]),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool dropdown;
  final VoidCallback onTap;

  const _FilterChip({
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

class _SheetTitle extends StatelessWidget {
  final String text;

  const _SheetTitle(this.text);

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

class _SheetOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetOption({
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
