import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamevault/screens/qr_scanner_screen.dart';

import 'helpers/pump_home.dart';

void main() {
  testWidgets('Phone shows five tabs, web hides Guard', (tester) async {
    await pumpHome(tester);
    for (final label in ['Store', 'Search', 'Wishlist', 'Guard', 'Profile']) {
      expect(navItem(label), findsOneWidget);
    }

    await pumpHome(tester, guard: false);
    expect(navItem('Guard'), findsNothing);
    expect(navItem('Profile'), findsOneWidget);
  });

  testWidgets('Store shows featured, offers and top sellers', (tester) async {
    await pumpHome(tester);

    expect(find.text('FEATURED'), findsWidgets);
    expect(find.text('Special Offers'), findsOneWidget);
    expect(find.text('Ashfall Protocol'), findsWidgets);

    await tester.dragUntilVisible(
      find.text('Frostbound Saga'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    expect(find.text('Top Sellers'), findsOneWidget);
    expect(find.text('Frostbound Saga'), findsWidgets);
  });

  testWidgets('Search text survives switching tabs', (tester) async {
    await pumpHome(tester);

    await tester.tap(navItem('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'lantern');
    await tester.pumpAndSettle();
    expect(find.text('1 results'), findsOneWidget);

    await tester.tap(navItem('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(navItem('Search'));
    await tester.pumpAndSettle();

    expect(find.text('lantern'), findsOneWidget);
    expect(find.text('1 results'), findsOneWidget);
  });

  testWidgets('Search filters by On sale', (tester) async {
    await pumpHome(tester);
    await tester.tap(navItem('Search'));
    await tester.pumpAndSettle();
    expect(find.text('4 results'), findsOneWidget);

    await tester.tap(find.text('On sale'));
    await tester.pumpAndSettle();
    expect(find.text('2 results'), findsOneWidget);
  });

  testWidgets('Guard tab opens the QR scanner', (tester) async {
    await pumpHome(tester);
    await tester.tap(navItem('Guard'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in on another device'), findsOneWidget);
    await tester.tap(find.text('Scan QR code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(QrScannerScreen), findsOneWidget);
  });

  testWidgets('Profile shows the account and signs out', (tester) async {
    final repo = await pumpHome(tester);
    await tester.tap(navItem('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Daulet Ozhanov'), findsOneWidget);
    expect(find.text('daulet@narxoz.kz'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sign out'), 200);
    await tester.tap(find.text('Sign out'));
    expect(repo.signedOut, isTrue);
  });

  testWidgets('No overflow on a small screen', (tester) async {
    await pumpHome(tester, size: const Size(320, 568));
    for (final label in ['Search', 'Wishlist', 'Guard', 'Profile']) {
      await tester.tap(navItem(label));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
