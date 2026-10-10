import 'package:flutter/painting.dart';

/// How a game's cover art is drawn (see `GameArt`).
enum ArtStyle { sun, mountains, lanterns, streaks, glow, waves }

class Game {
  final String id;
  final String title;
  final String studio;
  final String description;
  final List<String> genres;

  /// What the player pays now.
  final double price;

  /// Price before the discount; equals [price] when not on sale.
  final double oldPrice;
  final int discountPercent;

  final double rating;
  final int reviewCount;
  final bool featured;
  final bool topSeller;

  /// Steam app id; the store art comes from Steam's CDN. Null means the
  /// cover is drawn from [palette] instead.
  final int? steamAppId;

  /// Drawn cover (and placeholder while the real art loads): sky top,
  /// sky bottom, accent (sun, lights) colours.
  final List<Color> palette;
  final ArtStyle artStyle;

  const Game({
    required this.id,
    required this.title,
    required this.studio,
    required this.description,
    required this.genres,
    required this.price,
    required this.oldPrice,
    required this.discountPercent,
    required this.rating,
    required this.reviewCount,
    required this.palette,
    required this.artStyle,
    this.steamAppId,
    this.featured = false,
    this.topSeller = false,
  });

  bool get onSale => discountPercent > 0;

  static const String _cdn =
      'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps';

  /// 460×215 capsule used on cards.
  String? get headerUrl =>
      steamAppId == null ? null : '$_cdn/$steamAppId/header.jpg';

  /// 1920×620 banner used at the top of the detail page.
  String? get heroUrl =>
      steamAppId == null ? null : '$_cdn/$steamAppId/library_hero.jpg';

  /// "Action · Shooter"
  String get genreLine => genres.take(2).join(' · ');

  factory Game.fromMap(String id, Map<String, dynamic> map) {
    final List<Color> palette = [
      for (final Object? hex in (map['palette'] as List? ?? const []))
        Color(int.parse(hex.toString().replaceFirst('#', 'FF'), radix: 16)),
    ];
    return Game(
      id: id,
      title: map['title'] as String? ?? 'Untitled',
      studio: map['studio'] as String? ?? '',
      description: map['description'] as String? ?? '',
      genres: List<String>.from(map['genres'] as List? ?? const []),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      oldPrice: (map['oldPrice'] as num?)?.toDouble() ??
          (map['price'] as num?)?.toDouble() ??
          0,
      discountPercent: (map['discountPercent'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      steamAppId: (map['steamAppId'] as num?)?.toInt(),
      featured: map['featured'] as bool? ?? false,
      topSeller: map['topSeller'] as bool? ?? false,
      palette: palette.length >= 3
          ? palette
          : const [Color(0xFF2A475E), Color(0xFF1B2838), Color(0xFF66C0F4)],
      artStyle: ArtStyle.values.firstWhere(
        (s) => s.name == map['artStyle'],
        orElse: () => ArtStyle.glow,
      ),
    );
  }

  @override
  bool operator ==(Object other) => other is Game && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
