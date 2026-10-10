import '../models/game.dart';

/// The signed-in user's profile from `users/{uid}`.
class UserProfile {
  final String name;
  final String email;
  final String role;

  const UserProfile({
    required this.name,
    required this.email,
    required this.role,
  });

  String get firstName => name.trim().isEmpty ? email : name.trim().split(' ').first;
}

/// Games plus the signed-in user's wishlist, cart and library.
abstract class StoreRepository {
  Stream<List<Game>> games();

  Stream<UserProfile> profile();

  Stream<Set<String>> wishlistIds();

  /// Game id → quantity.
  Stream<Map<String, int>> cart();

  Stream<Set<String>> libraryIds();

  Future<void> toggleWishlist(String gameId);

  /// Adds one copy, or bumps the quantity if it's already in the cart.
  Future<void> addToCart(String gameId);

  /// Quantity 0 removes the game from the cart.
  Future<void> setQuantity(String gameId, int quantity);

  Future<void> clearCart();

  /// Moves everything in the cart to the library.
  Future<void> checkout(List<Game> games, Map<String, int> cart);

  Future<void> signOut();
}

const int maxCartQuantity = 10;
