import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_colors.dart';
import '../widgets/add_to_cart_bar.dart';
import '../widgets/game_cover.dart';
import '../widgets/game_info.dart';
import '../widgets/genre_tags.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  bool isBookmarked = false;

  void toggleBookmark() {
    setState(() {
      isBookmarked = !isBookmarked;
    });
  }

  void addToCart() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        content: Text(
          '${widget.game.title} added to cart',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Game game = widget.game;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cover Image
                  GameCover(
                    imageUrl: game.imageUrl,
                    discountPercent: game.discountPercent,
                    isBookmarked: isBookmarked,
                    onBookmarkPressed: toggleBookmark,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Game Info
                        GameInfo(game: game),
                        const SizedBox(height: 24),

                        // Genre Tags
                        const Text(
                          'Genres',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GenreTags(genres: game.genres),
                        const SizedBox(height: 24),

                        // Description
                        const Text(
                          'About This Game',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Add To Cart Bar
      bottomNavigationBar: AddToCartBar(
        price: game.price,
        onAddToCart: addToCart,
      ),
    );
  }
}
