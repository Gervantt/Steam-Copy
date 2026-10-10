import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/game.dart';
import 'store_repository.dart';

/// Games from `games/*`; per-user data under `users/{uid}/...`.
class FirestoreStoreRepository implements StoreRepository {
  FirestoreStoreRepository({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  User get _user => _auth.currentUser!;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_user.uid);

  CollectionReference<Map<String, dynamic>> _sub(String name) =>
      _userDoc.collection(name);

  @override
  Stream<List<Game>> games() {
    return _db.collection('games').snapshots().map(
          (snapshot) => [
            for (final doc in snapshot.docs) Game.fromMap(doc.id, doc.data()),
          ]..sort((a, b) => b.reviewCount.compareTo(a.reviewCount)),
        );
  }

  @override
  Stream<UserProfile> profile() {
    final User user = _user;
    return _userDoc.snapshots().map((doc) {
      final Map<String, dynamic> data = doc.data() ?? const {};
      return UserProfile(
        name: data['name'] as String? ?? user.displayName ?? '',
        email: data['email'] as String? ?? user.email ?? '',
        role: data['role'] as String? ?? 'Gamer',
      );
    });
  }

  @override
  Stream<Set<String>> wishlistIds() => _sub('wishlist')
      .snapshots()
      .map((s) => {for (final doc in s.docs) doc.id});

  @override
  Stream<Map<String, int>> cart() => _sub('cart').snapshots().map(
        (s) => {
          for (final doc in s.docs)
            doc.id: (doc.data()['qty'] as num?)?.toInt() ?? 1,
        },
      );

  @override
  Stream<Set<String>> libraryIds() => _sub('library')
      .snapshots()
      .map((s) => {for (final doc in s.docs) doc.id});

  @override
  Future<void> toggleWishlist(String gameId) async {
    final ref = _sub('wishlist').doc(gameId);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      await ref.delete();
    } else {
      await ref.set({'addedAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  Future<void> addToCart(String gameId) async {
    final ref = _sub('cart').doc(gameId);
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final int qty = (snapshot.data()?['qty'] as num?)?.toInt() ?? 0;
      if (qty >= maxCartQuantity) return;
      if (snapshot.exists) {
        tx.update(ref, {'qty': qty + 1});
      } else {
        tx.set(ref, {'qty': 1, 'addedAt': FieldValue.serverTimestamp()});
      }
    });
  }

  @override
  Future<void> setQuantity(String gameId, int quantity) async {
    final ref = _sub('cart').doc(gameId);
    if (quantity <= 0) {
      await ref.delete();
    } else {
      await ref.update({'qty': quantity.clamp(1, maxCartQuantity)});
    }
  }

  @override
  Future<void> clearCart() async {
    final snapshot = await _sub('cart').get();
    final WriteBatch batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> checkout(List<Game> games, Map<String, int> cart) async {
    final WriteBatch batch = _db.batch();
    for (final Game game in games) {
      final int? qty = cart[game.id];
      if (qty == null) continue;
      batch.set(_sub('library').doc(game.id), {
        'pricePaid': game.price,
        'purchasedAt': FieldValue.serverTimestamp(),
      });
      batch.delete(_sub('cart').doc(game.id));
    }
    await batch.commit();
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
