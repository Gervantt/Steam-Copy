import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamevault/main.dart';
import 'package:gamevault/screens/sign_in_screen.dart';
import 'package:gamevault/screens/sign_up_screen.dart';

import 'helpers/fake_auth_service.dart';

Finder field(String hint) => find.widgetWithText(TextField, hint);

void main() {
  late FakeAuthService auth;

  setUp(() => auth = FakeAuthService());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GameVaultApp(home: SignInScreen(auth: auth, showQrPanel: false)),
    );
  }

  testWidgets('Empty submit shows errors and does not call the server',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email, e.g. name@narxoz.kz'),
        findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('Signs in with email and password', (tester) async {
    await pumpApp(tester);

    await tester.enterText(field('name@narxoz.kz'), 'daniyar@narxoz.kz');
    await tester.enterText(field('Your password'), 'secret123');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(auth.calls, ['signIn:daniyar@narxoz.kz']);
  });

  testWidgets('Shows a wrong-password error', (tester) async {
    auth.failWith = 'Wrong email or password.';
    await pumpApp(tester);

    await tester.enterText(field('name@narxoz.kz'), 'daniyar@narxoz.kz');
    await tester.enterText(field('Your password'), 'nope');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Wrong email or password.'), findsOneWidget);
  });

  testWidgets('Create account opens sign-up', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);
  });

  testWidgets('No overflow on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GameVaultApp(home: SignInScreen(auth: auth, showQrPanel: false)),
    );
    expect(tester.takeException(), isNull);
  });
}
