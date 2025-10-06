import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';

abstract class AuthEventHandler {
  Future<void> onSessionExpired();
  ApiRequest refreshTokenRequest(String refreshToken);
  Future<void> onParsedNewToken(Response response) async {}
}

class DefaultAuthEventHandler implements AuthEventHandler {
  @override
  Future<void> onSessionExpired() async {
    throw UnimplementedError(
        'onSessionExpired must be implemented to handle session expiration');
  }

  @override
  ApiRequest refreshTokenRequest(String refreshToken) {
    throw UnimplementedError(
        'refreshTokenRequest must be implemented to refresh tokens');
  }

  @override
  Future<void> onParsedNewToken(Response response) async {
    throw UnimplementedError(
        'onParsedNewToken must be implemented to parse and store new tokens');
  }
}
