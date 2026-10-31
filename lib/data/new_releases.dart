import '../models/game.dart';

/// Picks the game to prepend when the catalog is refreshed.
///
/// First choice is a new release from the database that isn't shown yet,
/// then any catalog game that was swiped away. If everything is already
/// shown, the newest release comes back as a copy with a `#n` id so
/// every list item keeps a unique key.
Game nextNewRelease({
  required List<Game> allGames,
  required List<Game> shown,
  required int refreshCount,
}) {
  final Set<String> ids = {for (final g in shown) g.id};
  final List<Game> releases = allGames.where((g) => g.newRelease).toList();

  for (final Game g in releases) {
    if (!ids.contains(g.id)) return g;
  }
  for (final Game g in allGames) {
    if (!ids.contains(g.id)) return g;
  }
  final List<Game> source = releases.isNotEmpty ? releases : allGames;
  final Game base = source[refreshCount % source.length];
  return base.withId('${base.catalogId}#$refreshCount');
}
