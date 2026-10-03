class Game {
  final String title;
  final String developer;
  final String imageUrl;
  final String description;
  final double rating;
  final int reviewCount;
  final double price;
  final double oldPrice;
  final int discountPercent;
  final List<String> genres;

  const Game({
    required this.title,
    required this.developer,
    required this.imageUrl,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.oldPrice,
    required this.discountPercent,
    required this.genres,
  });
}

const Game hollowKnight = Game(
  title: 'Hollow Knight',
  developer: 'Team Cherry',
  imageUrl:
      'https://cdn.cloudflare.steamstatic.com/steam/apps/367520/library_hero.jpg',
  description:
      'Hollow Knight is a 2D action adventure set in Hallownest, a ruined '
      'kingdom of insects hidden deep beneath the earth. You play as a small '
      'silent knight who explores caverns, forgotten cities and poisoned '
      'gardens. Fight more than 150 different enemies and over 30 bosses, '
      'learn new abilities to reach new areas, collect charms to build your '
      'own play style and slowly uncover the dark secrets of the fallen '
      'kingdom. The game is known for its hand-drawn art, beautiful music '
      'and challenging but fair combat.',
  rating: 4.9,
  reviewCount: 2549,
  price: 7.49,
  oldPrice: 14.99,
  discountPercent: 50,
  genres: [
    'Action',
    'Adventure',
    'Metroidvania',
    'Indie',
    'Souls-like',
    '2D Platformer',
    'Hand-drawn',
    'Difficult',
  ],
);
