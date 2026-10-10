import 'dart:async';

import 'package:flutter/painting.dart';

import '../models/game.dart';
import 'store_repository.dart';

/// In-memory store for widget tests and previews.
class MemoryStoreRepository implements StoreRepository {
  MemoryStoreRepository({List<Game>? games, this.user = sampleUser})
      : _games = games ?? sampleGames;

  static const UserProfile sampleUser = UserProfile(
    name: 'Daulet Ozhanov',
    email: 'daulet@narxoz.kz',
    role: 'Gamer',
  );

  final List<Game> _games;
  final UserProfile user;

  final Set<String> wishlist = {};
  final Map<String, int> cartItems = {};
  final Set<String> library = {};
  bool signedOut = false;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Emits [read] now and again after every change.
  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  void _changed() => _changes.add(null);

  @override
  Stream<List<Game>> games() => Stream.value(_games);

  @override
  Stream<UserProfile> profile() => Stream.value(user);

  @override
  Stream<Set<String>> wishlistIds() => _watch(() => {...wishlist});

  @override
  Stream<Map<String, int>> cart() => _watch(() => {...cartItems});

  @override
  Stream<Set<String>> libraryIds() => _watch(() => {...library});

  @override
  Future<void> toggleWishlist(String gameId) async {
    if (!wishlist.remove(gameId)) wishlist.add(gameId);
    _changed();
  }

  @override
  Future<void> addToCart(String gameId) async {
    final int qty = cartItems[gameId] ?? 0;
    if (qty < maxCartQuantity) cartItems[gameId] = qty + 1;
    _changed();
  }

  @override
  Future<void> setQuantity(String gameId, int quantity) async {
    if (quantity <= 0) {
      cartItems.remove(gameId);
    } else {
      cartItems[gameId] = quantity.clamp(1, maxCartQuantity);
    }
    _changed();
  }

  @override
  Future<void> clearCart() async {
    cartItems.clear();
    _changed();
  }

  @override
  Future<void> checkout(List<Game> games, Map<String, int> cart) async {
    library.addAll(cart.keys);
    cartItems.clear();
    _changed();
  }

  @override
  Future<void> signOut() async => signedOut = true;
}

const List<Game> sampleGames = [
  Game(
    id: 'ashfall-protocol',
    title: 'Ashfall Protocol',
    studio: 'Ember Forge Studios',
    description: 'Lead a strike team across a scorched megacity.',
    genres: ['Action', 'Shooter'],
    price: 35.99,
    oldPrice: 59.99,
    discountPercent: 40,
    rating: 4.6,
    reviewCount: 18452,
    featured: true,
    topSeller: true,
    palette: [Color(0xFF3A1A12), Color(0xFFC2541E), Color(0xFFFFD27A)],
    artStyle: ArtStyle.sun,
  ),
  Game(
    id: 'lanterns-below',
    title: 'Lanterns Below',
    studio: 'Mossbell Studio',
    description: 'A hand-drawn 2D adventure through Duskhollow.',
    genres: ['Action', 'Metroidvania', 'Indie'],
    price: 7.49,
    oldPrice: 14.99,
    discountPercent: 50,
    rating: 4.8,
    reviewCount: 3128,
    featured: true,
    palette: [Color(0xFF3D4A4A), Color(0xFF1F2A2E), Color(0xFFFFB547)],
    artStyle: ArtStyle.lanterns,
  ),
  Game(
    id: 'frostbound-saga',
    title: 'Frostbound Saga',
    studio: 'Northlight Studio',
    description: 'An epic role-playing game across a frozen continent.',
    genres: ['RPG', 'Open World'],
    price: 59.99,
    oldPrice: 59.99,
    discountPercent: 0,
    rating: 4.8,
    reviewCount: 25411,
    topSeller: true,
    palette: [Color(0xFF7FA3C4), Color(0xFFD9E6F2), Color(0xFFFFFFFF)],
    artStyle: ArtStyle.mountains,
  ),
  Game(
    id: 'echo-garden',
    title: 'Echo Garden',
    studio: 'Little Fern',
    description: 'A calm puzzle game about a garden that remembers sound.',
    genres: ['Puzzle', 'Indie'],
    price: 12.99,
    oldPrice: 12.99,
    discountPercent: 0,
    rating: 4.7,
    reviewCount: 1650,
    palette: [Color(0xFF2E6B4A), Color(0xFF8CC7A1), Color(0xFFE8FFD6)],
    artStyle: ArtStyle.glow,
  ),
];
