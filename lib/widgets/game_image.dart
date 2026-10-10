import 'package:flutter/material.dart';

import '../models/game.dart';
import 'game_art.dart';

/// The game's real store art from Steam, with the drawn [GameArt] shown
/// while it loads and if it can't be loaded (offline, tests).
class GameImage extends StatelessWidget {
  final Game game;

  /// Wide banner for the detail page instead of the card capsule.
  final bool hero;

  const GameImage({super.key, required this.game, this.hero = false});

  @override
  Widget build(BuildContext context) {
    final String? url = hero ? game.heroUrl : game.headerUrl;
    final Widget placeholder = GameArt(game: game);
    if (url == null) return placeholder;

    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: hero ? Alignment.topCenter : Alignment.center,
      // Cards are small; don't decode the full image.
      cacheWidth: hero ? null : 460,
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded || frame != null) return child;
        return placeholder;
      },
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
