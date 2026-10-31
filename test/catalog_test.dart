import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamevault/data/memory_store_repository.dart';
import 'package:gamevault/data/new_releases.dart';
import 'package:gamevault/models/game.dart';
import 'package:gamevault/widgets/catalog_items.dart';

import 'helpers/pump_home.dart';

Future<void> openBrowse(WidgetTester tester) async {
  await tester.tap(navItem('Search'));
  await tester.pumpAndSettle();
}

Finder row(String title) => find.ancestor(
      of: find.text(title),
      matching: find.byType(CatalogListRow),
    );

void main() {
  testWidgets('List feed uses ListView.separated with dividers',
      (tester) async {
    await pumpHome(tester);
    await openBrowse(tester);

    expect(find.byType(CatalogListRow), findsNWidgets(4));
    expect(find.byType(Divider), findsNWidgets(3));
    expect(find.text('Starfall Colony'), findsNothing); // not released yet
  });

  testWidgets('Toggle switches to a 2-column grid and back', (tester) async {
    await pumpHome(tester);
    await openBrowse(tester);

    await tester.tap(find.byTooltip('Show as grid'));
    await tester.pumpAndSettle();
    final GridView grid = tester.widget(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(delegate.childAspectRatio, 0.72);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Show as list'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogListRow), findsNWidgets(4));
  });

  testWidgets('Pull-to-refresh adds a new release at index 0', (tester) async {
    await pumpHome(tester);
    await openBrowse(tester);

    await tester.fling(row('Ashfall Protocol'), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // still "loading"
    expect(find.text('Starfall Colony'), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final rows = tester.widgetList<CatalogListRow>(find.byType(CatalogListRow));
    expect(rows.first.game.id, 'starfall-colony');
    expect(find.text('5 results'), findsOneWidget);
  });

  testWidgets('Swipe left deletes with a red background, UNDO restores',
      (tester) async {
    await pumpHome(tester);
    await openBrowse(tester);

    await tester.drag(row('Lanterns Below'), const Offset(-150, 0));
    await tester.pump();
    expect(find.byType(SwipeDeleteBackground), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);

    await tester.drag(row('Lanterns Below'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Lanterns Below'), findsNothing);
    expect(find.text('3 results'), findsOneWidget);
    expect(find.text('UNDO'), findsOneWidget);

    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    final rows = tester.widgetList<CatalogListRow>(find.byType(CatalogListRow));
    expect(rows.elementAt(1).game.id, 'lanterns-below'); // original index
  });

  testWidgets('Empty catalog shows a reset button', (tester) async {
    await pumpHome(tester);
    await openBrowse(tester);

    for (final title in [
      'Ashfall Protocol',
      'Lanterns Below',
      'Frostbound Saga',
      'Echo Garden',
    ]) {
      await tester.drag(row(title), const Offset(-500, 0));
      await tester.pumpAndSettle();
    }

    expect(find.text('Catalog is Empty'), findsOneWidget);
    await tester.tap(find.text('Reset Catalog'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogListRow), findsNWidgets(4));
  });

  test('nextNewRelease prefers unreleased, then gives unique copies', () {
    const List<Game> all = sampleGames;
    final List<Game> shown = all.where((g) => !g.newRelease).toList();

    final Game first =
        nextNewRelease(allGames: all, shown: shown, refreshCount: 1);
    expect(first.id, 'starfall-colony');

    final Game copy = nextNewRelease(
      allGames: all,
      shown: [first, ...shown],
      refreshCount: 2,
    );
    expect(copy.id, 'starfall-colony#2');
    expect(copy.catalogId, 'starfall-colony');
  });
}
