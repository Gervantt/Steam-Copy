import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/store_repository.dart';
import '../data/store_scope.dart';
import '../theme/app_colors.dart';
import 'profile_tab.dart';
import 'qr_guard_screen.dart';
import 'search_tab.dart';
import 'store_tab.dart';
import 'wishlist_tab.dart';

enum HomeTab { store, search, wishlist, guard, profile }

/// Signed-in root: tabs in an IndexedStack so each keeps its state
/// (scroll position, search text) while you switch between them.
class HomeScreen extends StatefulWidget {
  final StoreRepository repository;

  /// Scanning a QR code approves another device, so Guard is phone-only.
  final bool showGuardTab;

  const HomeScreen({
    super.key,
    required this.repository,
    this.showGuardTab = !kIsWeb,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final StoreController store = StoreController(widget.repository);
  final FocusNode searchFocus = FocusNode();
  HomeTab tab = HomeTab.store;

  List<HomeTab> get tabs => [
        for (final HomeTab t in HomeTab.values)
          if (t != HomeTab.guard || widget.showGuardTab) t,
      ];

  @override
  void dispose() {
    store.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  void select(HomeTab t) {
    setState(() => tab = t);
    if (t == HomeTab.search) {
      searchFocus.requestFocus();
    } else {
      searchFocus.unfocus();
    }
  }

  Widget page(HomeTab t) {
    switch (t) {
      case HomeTab.store:
        return StoreTab(
          onOpenSearch: () => select(HomeTab.search),
          onOpenCart: () => select(HomeTab.wishlist),
        );
      case HomeTab.search:
        return SearchTab(focusNode: searchFocus);
      case HomeTab.wishlist:
        return const WishlistTab();
      case HomeTab.guard:
        return ListenableBuilder(
          listenable: store,
          builder: (context, _) =>
              QrGuardScreen(name: store.profile?.firstName ?? ''),
        );
      case HomeTab.profile:
        return ProfileTab(
          onOpenGuard: widget.showGuardTab ? () => select(HomeTab.guard) : null,
        );
    }
  }

  BottomNavigationBarItem item(HomeTab t) {
    switch (t) {
      case HomeTab.store:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.storefront_outlined),
          activeIcon: Icon(Icons.storefront),
          label: 'Store',
        );
      case HomeTab.search:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        );
      case HomeTab.wishlist:
        return BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: store.cartCount > 0,
            label: Text('${store.cartCount}'),
            backgroundColor: AppColors.accent,
            textColor: AppColors.darkBackground,
            child: const Icon(Icons.favorite_border),
          ),
          activeIcon: const Icon(Icons.favorite),
          label: 'Wishlist',
        );
      case HomeTab.guard:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_2),
          activeIcon: Icon(Icons.qr_code_scanner),
          label: 'Guard',
        );
      case HomeTab.profile:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<HomeTab> visible = tabs;
    return StoreScope(
      controller: store,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => Scaffold(
          body: IndexedStack(
            index: visible.indexOf(tab),
            children: [for (final HomeTab t in visible) page(t)],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: visible.indexOf(tab),
            onTap: (i) => select(visible[i]),
            backgroundColor: AppColors.darkBackground,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: AppColors.textSecondary,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: [for (final HomeTab t in visible) item(t)],
          ),
        ),
      ),
    );
  }
}
