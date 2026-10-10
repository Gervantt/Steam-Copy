/// A parsed GameVault QR sign-in code.
///
/// Expected format: `gamevault://login?session=<id>&device=<name>`
class QrLoginPayload {
  static const String scheme = 'gamevault';
  static const String host = 'login';
  static const String unknownDevice = 'Unknown device';

  static const int _maxDeviceLength = 64;
  static final RegExp _sessionPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  final String sessionId;
  final String deviceName;

  const QrLoginPayload({required this.sessionId, required this.deviceName});

  /// Returns the payload, or null if [raw] isn't a GameVault sign-in code.
  static QrLoginPayload? tryParse(String? raw) {
    if (raw == null) return null;

    final Uri? uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != scheme ||
        uri.host.toLowerCase() != host) {
      return null;
    }

    final String? sessionId = uri.queryParameters['session'];
    if (sessionId == null || !_sessionPattern.hasMatch(sessionId)) {
      return null;
    }

    String deviceName = (uri.queryParameters['device'] ?? '').trim();
    if (deviceName.isEmpty) deviceName = unknownDevice;
    if (deviceName.length > _maxDeviceLength) {
      deviceName = deviceName.substring(0, _maxDeviceLength);
    }

    return QrLoginPayload(sessionId: sessionId, deviceName: deviceName);
  }

  @override
  bool operator ==(Object other) =>
      other is QrLoginPayload &&
      other.sessionId == sessionId &&
      other.deviceName == deviceName;

  @override
  int get hashCode => Object.hash(sessionId, deviceName);
}
