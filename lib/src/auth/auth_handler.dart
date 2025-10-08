import 'package:api_client/api_client.dart';

abstract class AuthEventHandler {
  Future<void> onSessionExpired();
  ApiRequest refreshTokenRequest(String refreshToken);
  String? onParsedNewToken(Response response);
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
  String? onParsedNewToken(Response response) {
    throw UnimplementedError(
        'onParsedNewToken must be implemented to parse and store new tokens');
  }
}
