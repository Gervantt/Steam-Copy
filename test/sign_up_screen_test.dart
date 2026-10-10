import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamevault/main.dart';
import 'package:gamevault/screens/sign_up_screen.dart';

import 'helpers/fake_auth_service.dart';

Finder field(String hint) => find.widgetWithText(TextField, hint);

void main() {
  late FakeAuthService auth;

  setUp(() => auth = FakeAuthService());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GameVaultApp(home: SignUpScreen(auth: auth)));
  }

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(field('Your full name'), 'Daniyar Nurlanov');
    await tester.enterText(field('name@narxoz.kz'), 'daniyar@narxoz.kz');
    await tester.enterText(field('At least 6 characters'), 'secret123');
    await tester.enterText(field('Repeat your password'), 'secret123');
    await tester.tap(find.byType(Checkbox));
  }

  testWidgets('Empty submit shows every validation error', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Enter a valid email, e.g. name@narxoz.kz'),
        findsOneWidget);
    expect(find.text('Password must be at least 6 characters'),
        findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(find.text('You must accept the Terms to continue'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('Valid form creates the account and shows the toast',
      (tester) async {
    await pumpApp(tester);

    await fillValidForm(tester);
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(auth.calls, ['signUp:daniyar@narxoz.kz:Student']);
    expect(find.text('Account created!'), findsOneWidget);
    expect(find.text('Welcome to GameVault, Daniyar'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsNothing);
  });

  testWidgets('Shows the server error when sign-up fails', (tester) async {
    auth.failWith = 'An account with this email already exists. Sign in instead.';
    await pumpApp(tester);

    await fillValidForm(tester);
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(
      find.text('An account with this email already exists. Sign in instead.'),
      findsOneWidget,
    );
    expect(find.text('Account created!'), findsNothing);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('Has no QR button before signing in', (tester) async {
    await pumpApp(tester);

    expect(find.byTooltip('Sign in with QR'), findsNothing);
  });

  testWidgets('No overflow on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(GameVaultApp(home: SignUpScreen(auth: auth)));
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
