import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamevault/qr_login/qr_login_payload.dart';
import 'package:gamevault/qr_login/qr_login_service.dart';
import 'package:gamevault/screens/qr_approve_screen.dart';

const payload = QrLoginPayload(sessionId: 'test123', deviceName: 'Windows PC');

class RecordingService extends MockQrLoginService {
  final List<String> calls = [];

  @override
  Future<void> approve(QrLoginPayload p) {
    calls.add('approve:${p.sessionId}');
    return super.approve(p);
  }

  @override
  Future<void> deny(QrLoginPayload p) {
    calls.add('deny:${p.sessionId}');
    return super.deny(p);
  }
}

/// Start screen with a button that pushes the approve screen,
/// so we can check that approve/deny pop back to the start.
Widget harness(QrLoginService service) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  QrApproveScreen(payload: payload, service: service),
            ),
          ),
          child: const Text('start'),
        ),
      ),
    ),
  );
}

Future<void> openApprove(WidgetTester tester, QrLoginService service) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(harness(service));
  await tester.tap(find.text('start'));
  await tester.pumpAndSettle();
}

ButtonStyleButton button(WidgetTester tester, String text) =>
    tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(text),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );

void main() {
  testWidgets('Shows the device from the payload and a countdown',
      (tester) async {
    await openApprove(tester, RecordingService());

    expect(find.text('Sign in on another device?'), findsOneWidget);
    expect(find.text('Windows PC'), findsOneWidget);
    expect(find.text('Code expires in 1:00', findRichText: true), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
    expect(find.text('Code expires in 0:45', findRichText: true), findsOneWidget);
  });

  testWidgets('Expires after 60s and disables the buttons', (tester) async {
    await openApprove(tester, RecordingService());

    await tester.pump(const Duration(seconds: 60));

    expect(find.text('Code expired. Scan again.'), findsOneWidget);
    expect(button(tester, 'Approve sign-in').onPressed, isNull);
    expect(button(tester, 'Deny').onPressed, isNull);
  });

  testWidgets('Approve shows loading, then pops to start with a SnackBar',
      (tester) async {
    final service = RecordingService();
    await openApprove(tester, service);

    await tester.tap(find.text('Approve sign-in'));
    await tester.pump();
    expect(find.text('Approving…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(service.calls, ['approve:test123']);
    expect(find.byType(QrApproveScreen), findsNothing);
    expect(find.text('start'), findsOneWidget);
    expect(find.text('Signed in on Windows PC'), findsOneWidget);
  });

  testWidgets('Deny pops to start with a SnackBar', (tester) async {
    final service = RecordingService();
    await openApprove(tester, service);

    await tester.tap(find.text('Deny'));
    await tester.pumpAndSettle();

    expect(service.calls, ['deny:test123']);
    expect(find.byType(QrApproveScreen), findsNothing);
    expect(find.text('Sign-in request denied'), findsOneWidget);

    // Let the mock deny call finish.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('No overflow on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: QrApproveScreen(payload: payload, service: RecordingService()),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
