abstract class TokenStorage extends Object {
  Future<String?> onGetAccessToken();
  Future<String?> onGetRefreshToken();
  Future<void> onSaveAccessToken(String token);
  Future<void> onClearTokens();
}

// Default implementation using in-memory storage
class InMemoryTokenStorage implements TokenStorage {
  @override
  Future<String?> onGetAccessToken() async {
    throw UnimplementedError();
  }

  @override
  Future<String?> onGetRefreshToken() async {
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
