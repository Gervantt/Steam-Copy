import 'package:flutter_test/flutter_test.dart';

import 'package:gamevault/qr_login/qr_login_payload.dart';

void main() {
  group('QrLoginPayload.tryParse', () {
    test('parses a valid code and decodes the device name', () {
      final payload = QrLoginPayload.tryParse(
        'gamevault://login?session=test123&device=Windows%20PC',
      );

      expect(
        payload,
        const QrLoginPayload(sessionId: 'test123', deviceName: 'Windows PC'),
      );
    });

    test('ignores surrounding whitespace', () {
      final payload = QrLoginPayload.tryParse(
        '  gamevault://login?session=abc-1&device=Mac  \n',
      );

      expect(payload?.sessionId, 'abc-1');
    });

    test('falls back to "Unknown device" when device is missing', () {
      final payload = QrLoginPayload.tryParse('gamevault://login?session=abc');

      expect(payload?.deviceName, QrLoginPayload.unknownDevice);
    });

    test('rejects a wrong scheme', () {
      expect(
        QrLoginPayload.tryParse('https://login?session=abc&device=PC'),
        isNull,
      );
      expect(
        QrLoginPayload.tryParse('steam://login?session=abc&device=PC'),
        isNull,
      );
    });

    test('rejects a wrong host', () {
      expect(
        QrLoginPayload.tryParse('gamevault://store?session=abc&device=PC'),
        isNull,
      );
    });

    test('rejects a missing or empty session', () {
      expect(QrLoginPayload.tryParse('gamevault://login?device=PC'), isNull);
      expect(
        QrLoginPayload.tryParse('gamevault://login?session=&device=PC'),
        isNull,
      );
    });

    test('rejects a session with unexpected characters', () {
      expect(
        QrLoginPayload.tryParse('gamevault://login?session=a%20b&device=PC'),
        isNull,
      );
    });

    test('rejects garbage and null', () {
      expect(QrLoginPayload.tryParse(null), isNull);
      expect(QrLoginPayload.tryParse(''), isNull);
      expect(QrLoginPayload.tryParse('hello world'), isNull);
    });

    test('truncates very long device names', () {
      final payload = QrLoginPayload.tryParse(
        'gamevault://login?session=abc&device=${'x' * 200}',
      );

      expect(payload?.deviceName.length, 64);
    });
  });
}
