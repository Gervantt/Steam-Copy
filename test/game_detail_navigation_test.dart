import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamevault/models/game.dart';
import 'package:gamevault/screens/game_detail_screen.dart';

import 'helpers/pump_home.dart';

Future<void> openLanterns(WidgetTester tester) async {
  await tester.tap(navItem('Search'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lanterns Below'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Tapping a game passes the whole object to the detail screen',
      (tester) async {
    await pumpHome(tester);
    await openLanterns(tester);

    expect(find.byType(GameDetailScreen), findsOneWidget);
    final route = ModalRoute.of(tester.element(find.byType(GameDetailScreen)))!;
    expect(route.settings.name, GameDetailScreen.routeName);
    expect((route.settings.arguments! as Game).id, 'lanterns-below');

    expect(find.text('Lanterns Below'), findsWidgets);
    expect(find.text('Mossbell Studio'), findsOneWidget);
    expect(find.text('\$7.49'), findsWidgets);
    expect(find.text('A hand-drawn 2D adventure through Duskhollow.'),
        findsOneWidget);
  });

  testWidgets('AppBar back returns to the same tab with state intact',
      (tester) async {
    await pumpHome(tester);
    await tester.tap(navItem('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'lan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanterns Below'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(GameDetailScreen), findsNothing);
    expect(find.text('lan'), findsOneWidget);
  });

  testWidgets('In-body "Back to store" button pops', (tester) async {
    await pumpHome(tester);
    await openLanterns(tester);

    await tester.scrollUntilVisible(
      find.text('Back to store'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(GameDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Back to store'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to store'));
    await tester.pumpAndSettle();

    expect(find.byType(GameDetailScreen), findsNothing);
    expect(find.text('Browse'), findsOneWidget);
  });

  testWidgets('Bookmark adds the game to the wishlist', (tester) async {
    final repo = await pumpHome(tester);
    await openLanterns(tester);

    await tester.tap(find.byTooltip('Add to wishlist'));
    await tester.pumpAndSettle();

    expect(repo.wishlist, {'lanterns-below'});
    expect(find.byTooltip('Remove from wishlist'), findsOneWidget);
  });
}
