abstract class TokenStorage extends Object {
  String? onGetAccessToken();
  String? onGetRefreshToken();
  Future<void> onSaveAccessToken(String token);
  Future<void> onClearTokens();
}

class DefaultTokenStorage implements TokenStorage {
  @override
  String? onGetAccessToken() {
    throw UnimplementedError(
        'onGetAccessToken must be implemented to retrieve the access token');
  }

  @override
  String? onGetRefreshToken() {
    throw UnimplementedError(
        'onGetRefreshToken must be implemented to retrieve the refresh token');
  }

  @override
  Future<void> onSaveAccessToken(String token) async {
    throw UnimplementedError(
        'onSaveAccessToken must be implemented to save the access token');
  }

  @override
  Future<void> onClearTokens() async {
    throw UnimplementedError(
        'onClearTokens must be implemented to clear stored tokens');
  }
}
