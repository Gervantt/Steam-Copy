import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/game.dart';
import 'store_repository.dart';

/// Live state of the store for the signed-in user. Subscribes to the
/// repository once, so every tab and the detail screen share the same data.
class StoreController extends ChangeNotifier {
  StoreController(this.repository) {
    _subs = [
      repository.games().listen((v) {
        games = v;
        loaded = true;
        notifyListeners();
      }, onError: _onError),
      repository.profile().listen((v) {
        profile = v;
        notifyListeners();
      }, onError: _onError),
      repository.wishlistIds().listen((v) {
        wishlist = v;
        notifyListeners();
      }, onError: _onError),
      repository.cart().listen((v) {
        cart = v;
        notifyListeners();
      }, onError: _onError),
      repository.libraryIds().listen((v) {
        library = v;
        notifyListeners();
      }, onError: _onError),
    ];
  }

  final StoreRepository repository;
  late final List<StreamSubscription<Object?>> _subs;

  bool loaded = false;
  Object? error;
  List<Game> games = const [];
  UserProfile? profile;
  Set<String> wishlist = const {};
  Map<String, int> cart = const {};
  Set<String> library = const {};

  void _onError(Object e) {
    error = e;
    loaded = true;
    notifyListeners();
  }

  Game? gameById(String id) {
    for (final Game g in games) {
      if (g.id == id) return g;
    }
    return null;
  }

  List<Game> _byIds(Iterable<String> ids) =>
      [for (final id in ids) ?gameById(id)];

  List<Game> get wishlistGames => _byIds(wishlist);
  List<Game> get cartGames => _byIds(cart.keys);
  List<Game> get libraryGames => _byIds(library);

  int get cartCount => cart.values.fold(0, (sum, qty) => sum + qty);

  double get cartSubtotal => cartGames.fold(
        0,
        (sum, g) => sum + g.oldPrice * (cart[g.id] ?? 0),
      );

  double get cartTotal => cartGames.fold(
        0,
        (sum, g) => sum + g.price * (cart[g.id] ?? 0),
      );

  double get cartDiscount => cartSubtotal - cartTotal;

  bool isWishlisted(Game g) => wishlist.contains(g.id);
  bool inCart(Game g) => cart.containsKey(g.id);
  bool owns(Game g) => library.contains(g.id);

  Future<void> toggleWishlist(Game g) => repository.toggleWishlist(g.id);
  Future<void> addToCart(Game g) => repository.addToCart(g.id);
  Future<void> setQuantity(Game g, int qty) =>
      repository.setQuantity(g.id, qty);
  Future<void> clearCart() => repository.clearCart();
  Future<void> checkout() => repository.checkout(cartGames, cart);
  Future<void> signOut() => repository.signOut();

  @override
  void dispose() {
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    super.dispose();
  }
}

class StoreScope extends InheritedNotifier<StoreController> {
  const StoreScope({
    super.key,
    required StoreController controller,
    required super.child,
  }) : super(notifier: controller);

  static StoreController of(BuildContext context) {
    final StoreScope? scope =
        context.dependOnInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'No StoreScope above this widget.');
    return scope!.notifier!;
  }
}
