import 'package:dio/dio.dart';

import '../../api_client.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final AuthEventHandler authHandler;
  final Dio _refreshDio;

  static const int _unAuthCode = 401;
  // Refresh token state
  static Future<void>? _refreshTokenFuture;
  static bool _isRefreshingToken = false;
  static bool _refreshSuccessful = false;
  static int _unauthorizedCount = 0;
  static int _retrySuccessCount = 0;

  AuthInterceptor({
    required this.tokenStorage,
    required this.authHandler,
    required String baseUrl,
    Dio? refreshDio,
  }) : _refreshDio = refreshDio ?? Dio(BaseOptions(baseUrl: baseUrl));

  void _resetTokenRefreshFlags() {
    if (_isRefreshingToken) _isRefreshingToken = false;
    if (_refreshSuccessful) _refreshSuccessful = false;
  }

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await tokenStorage.onGetAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == _unAuthCode) {
      _unauthorizedCount++;
      await _handleUnauthorizedError(err, handler);
      return;
    }
    return super.onError(err, handler);
  }

  Future<void> _handleUnauthorizedError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;

    try {
      await _refreshTokenIfNeeded();

      if (_refreshSuccessful) {
        while (_retrySuccessCount < _unauthorizedCount) {
          final response = await _retryRequest(requestOptions);
          handler.resolve(response);
          break;
        }
        if (_retrySuccessCount >= _unauthorizedCount) {
          _unauthorizedCount = 0;
          _retrySuccessCount = 0;
          _resetTokenRefreshFlags();
        }
      } else {
        await _handleSessionExpired();
      }
    } catch (e) {
      await _handleSessionExpired();
    }
  }

  Future<void> _refreshTokenIfNeeded() async {
    if (_refreshTokenFuture != null) {
      await _refreshTokenFuture;
      return;
    }

    if (_isRefreshingToken && _refreshSuccessful) {
      return;
    }

    _refreshTokenFuture = _performTokenRefresh().catchError((error) {
      _refreshTokenFuture = null;
      throw error;
    });

    await _refreshTokenFuture;
    _refreshTokenFuture = null;
  }

  Future<void> _performTokenRefresh() async {
    _isRefreshingToken = true;

    try {
      final refreshToken = await tokenStorage.onGetRefreshToken();
      if (refreshToken == null) {
        _refreshSuccessful = false;
        await authHandler.onTokenRefreshFailed();
        throw Exception('No refresh token available');
      }

      final response = await _makeRefreshTokenRequest(refreshToken);
      await _extractTokenFromResponse(response);
    } catch (e) {
      _refreshSuccessful = false;
      rethrow;
    } finally {
      _isRefreshingToken = false;
    }
  }

  Future<Response> _makeRefreshTokenRequest(String refreshToken) async {
    return await _refreshDio.post(
      authHandler.refreshTokenRequest(refreshToken).path,
      data: authHandler.refreshTokenRequest(refreshToken).body,
      options: Options(contentType: Headers.jsonContentType),
    );
  }

  Future<void> _extractTokenFromResponse(Response response) async {
    await authHandler.onParsedNewToken(response);
    _refreshSuccessful = true;
  }

  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final accessToken = await tokenStorage.onGetAccessToken();
    if (accessToken == null) {
      throw Exception('No access token available for retrying request');
    }

    return await _refreshDio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer $accessToken',
        },
        contentType: requestOptions.contentType,
      ),
    );
  }

  Future<void> _handleSessionExpired() async {
    await tokenStorage.onClearTokens();
    await authHandler.onSessionExpired();
  }
}
