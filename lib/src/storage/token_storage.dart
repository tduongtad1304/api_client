abstract class TokenStorage extends Object {
  String? onGetAccessToken();
  String? onGetRefreshToken();
  Future<void> onSaveAccessToken(String token);
  Future<void> onClearTokens();
}

class InMemoryTokenStorage implements TokenStorage {
  @override
  String? onGetAccessToken() {
    throw UnimplementedError();
  }

  @override
  String? onGetRefreshToken() {
    throw UnimplementedError();
  }

  @override
  Future<void> onSaveAccessToken(String token) async {
    throw UnimplementedError();
  }

  @override
  Future<void> onClearTokens() async {
    throw UnimplementedError();
  }
}
