import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';

abstract class AuthEventHandler {
  Future<void> onTokenRefreshed();
  Future<void> onSessionExpired();
  ApiRequest refreshTokenRequest(String refreshToken);
  Future<void> onParsedNewToken(Response response) async {}
}

// Default implementation that does nothing
class DefaultAuthEventHandler implements AuthEventHandler {
  @override
  Future<void> onTokenRefreshed() async {}

  @override
  Future<void> onSessionExpired() async {}

  @override
  ApiRequest refreshTokenRequest(String refreshToken) {
    throw UnimplementedError(
        'refreshTokenRequest must be implemented to refresh tokens');
  }

  @override
  Future<void> onParsedNewToken(Response response) async {}
}
