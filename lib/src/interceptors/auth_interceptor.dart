import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../api_client.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final AuthEventHandler authHandler;
  final Dio _refreshDio;
  final void Function(DioException err)? onUnknownErrors;

  static const int _unAuthCode = 401;
  // Refresh token state
  static Future<void>? _refreshTokenFuture;
  static bool? _isRefreshingToken;
  static bool? _refreshSuccessful;
  static int _unauthorizedCount = 0;
  static int _retrySuccessCount = 0;
  static int _retryFailedCount = 0;

  AuthInterceptor({
    required this.tokenStorage,
    required this.authHandler,
    required String baseUrl,
    this.onUnknownErrors,
    Dio? refreshDio,
  }) : _refreshDio = refreshDio ?? _getRefreshDio(baseUrl);

  void _resetTokenRefreshFlags() {
    if (_isRefreshingToken == true) _isRefreshingToken = null;
    if (_refreshSuccessful == true) _refreshSuccessful = null;
  }

  static Dio _getRefreshDio(String baseUrl) {
    final Dio retryDio = Dio(BaseOptions(baseUrl: baseUrl));
    Dio getRetryDioClient() => retryDio;
    return getRetryDioClient();
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final accessToken = tokenStorage.onGetAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    super.onRequest(options, handler);
  }

  void _logUnknownErrors(DioException err) {
    if (err.type == DioExceptionType.unknown && !kDebugMode) {
      if (onUnknownErrors != null) {
        onUnknownErrors!(err);
      }
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    _logUnknownErrors(err);
    if (_refreshSuccessful != null &&
        (_refreshSuccessful == false || _retryFailedCount == 1)) {
      Console.log('Refresh previously failed or retried, not retrying.');
      return;
    }
    if (err.response?.statusCode == _unAuthCode) {
      Console.log('⛔️ 401 Unauthorized error detected.');
      _unauthorizedCount++;
      await _handleUnauthorizedError(err, handler);
      return;
    }
    handler.next(err);
  }

  Future<void> _handleUnauthorizedError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.response?.requestOptions;

    if (requestOptions == null) {
      await _handleSessionExpired();
      return;
    }

    try {
      await _refreshTokenIfNeeded();

      if (_refreshSuccessful != null && _refreshSuccessful == true) {
        while (_retrySuccessCount < _unauthorizedCount) {
          Console.log('🔄️ Retrying original request...');
          final response = await _retryRequest(requestOptions);
          handler.resolve(response);
          break;
        }
        if (_retrySuccessCount >= _unauthorizedCount) {
          _unauthorizedCount = 0;
          _retrySuccessCount = 0;
          _retryFailedCount = 0;
          _resetTokenRefreshFlags();
          Console.log('🎉 ALL RETRIES successful.');
        }
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

    if (_isRefreshingToken == true) return;

    _refreshTokenFuture = _performTokenRefresh().catchError((error) {
      _refreshTokenFuture = null;
      throw error;
    });

    await _refreshTokenFuture;
    _refreshTokenFuture = null;
  }

  Future<void> _performTokenRefresh() async {
    Console.log('🔄️ Token expired ⇌ Starting token refresh...');
    _isRefreshingToken = true;

    try {
      final refreshToken = tokenStorage.onGetRefreshToken();
      if (refreshToken == null) {
        _refreshSuccessful = false;
        await authHandler.onSessionExpired();
        throw Exception('No refresh token available');
      }

      final response = await _makeRefreshTokenRequest(refreshToken);
      await _extractTokenFromResponse(response);
      Console.log('♻️ Token refresh successful!');
    } catch (e) {
      _refreshSuccessful = false;
      Console.log('⛔️ Token refresh failed.');
      rethrow;
    }
  }

  Future<Response> _makeRefreshTokenRequest(String refreshToken) async {
    final options = Options(
        contentType: Headers.jsonContentType,
        method: authHandler.refreshTokenRequest(refreshToken).method.value);
    Console.log(
        '→ [${options.method}] ${authHandler.refreshTokenRequest(refreshToken).path}');
    final response = await _refreshDio.request(
      authHandler.refreshTokenRequest(refreshToken).path,
      data: authHandler.refreshTokenRequest(refreshToken).body,
      options: options,
    );
    return response;
  }

  Future<void> _extractTokenFromResponse(Response response) async {
    await authHandler.onParsedNewToken(response);
    _refreshSuccessful = true;
  }

  Future<Response> _retryRequest(RequestOptions requestOptions,
      [String? testFailedRetryPath]) async {
    final accessToken = tokenStorage.onGetAccessToken();
    if (accessToken == null) {
      throw Exception('No access token available for retrying request');
    }
    try {
      final response = await _refreshDio.request(
        requestOptions.path + (testFailedRetryPath ?? ''),
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
      _retrySuccessCount++;
      Console.log(
          '✔ RETRY [${response.requestOptions.method}] ${response.requestOptions.path} successful!');
      return response;
    } catch (e) {
      _retryFailedCount++;
      Console.log(
          '✘ RETRY [${requestOptions.method}] ${requestOptions.path} failed.');
      rethrow;
    }
  }

  Future<void> _handleSessionExpired() async {
    final accessToken = tokenStorage.onGetAccessToken();
    if (accessToken == null) return;
    _unauthorizedCount = 0;
    _retrySuccessCount = 0;
    _retryFailedCount = 0;
    _resetTokenRefreshFlags();
    await tokenStorage.onClearTokens();
    await authHandler.onSessionExpired();
  }
}
