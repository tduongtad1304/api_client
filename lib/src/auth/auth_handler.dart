import 'package:api_client/api_client.dart';

abstract class AuthEventHandler {
  Future<void> onUnauthorized();
  Future<void> onTokenRefreshed();
  Future<void> onSessionExpired();
  Future<void> onTokenRefreshFailed();
  ApiRequest refreshTokenRequest(String refreshToken);
  Future<void> onParsedNewToken(
      TokenStorage storage, ApiResponse response) async {}
}

// Default implementation that does nothing
class DefaultAuthEventHandler implements AuthEventHandler {
  @override
  Future<void> onUnauthorized() async {}

  @override
  Future<void> onTokenRefreshed() async {}

  @override
  Future<void> onSessionExpired() async {}

  @override
  Future<void> onTokenRefreshFailed() async {}

  @override
  ApiRequest refreshTokenRequest(String refreshToken) {
    throw UnimplementedError(
        'refreshTokenRequest must be implemented to refresh tokens');
  }

  @override
  Future<void> onParsedNewToken(
      TokenStorage storage, ApiResponse response) async {}
}
