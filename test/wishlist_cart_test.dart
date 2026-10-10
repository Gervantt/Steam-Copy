import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_home.dart';

void main() {
  testWidgets('Add to cart, change quantity, checkout to library',
      (tester) async {
    final repo = await pumpHome(tester);

    await tester.tap(navItem('Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanterns Below'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();
    expect(repo.cartItems, {'lanterns-below': 1});
    expect(find.text('Add to Cart (1)'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    // Let the "added to cart" SnackBar time out so it doesn't cover Checkout.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(navItem('Wishlist'));
    await tester.pumpAndSettle();

    expect(find.text('1 item'), findsOneWidget);
    await tester.tap(find.byTooltip('Add one'));
    await tester.pumpAndSettle();
    expect(repo.cartItems['lanterns-below'], 2);
    expect(find.text('\$14.98'), findsOneWidget);

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    expect(repo.library, {'lanterns-below'});
    expect(repo.cartItems, isEmpty);
    expect(find.textContaining('Purchased 1 game'), findsOneWidget);

    await tester.tap(navItem('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Lanterns Below'), findsOneWidget);
  });

  testWidgets('Wishlist row adds to cart and removes', (tester) async {
    final repo = await pumpHome(tester);
    await repo.toggleWishlist('echo-garden');
    await tester.tap(navItem('Wishlist'));
    await tester.pumpAndSettle();

    expect(find.text('Echo Garden'), findsOneWidget);
    await tester.tap(find.byTooltip('Add Echo Garden to cart'));
    await tester.pumpAndSettle();
    expect(repo.cartItems, {'echo-garden': 1});

    await tester.tap(find.byTooltip('Remove Echo Garden from wishlist'));
    await tester.pumpAndSettle();
    expect(repo.wishlist, isEmpty);
    expect(find.text('Echo Garden'), findsOneWidget); // still in the cart
  });
}
