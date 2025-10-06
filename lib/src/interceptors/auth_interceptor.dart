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
  static bool _isRefreshingToken = false;
  static bool _refreshSuccessful = false;
  static int _unauthorizedCount = 0;
  static int _retrySuccessCount = 0;

  AuthInterceptor({
    required this.tokenStorage,
    required this.authHandler,
    required String baseUrl,
    this.onUnknownErrors,
    Dio? refreshDio,
  }) : _refreshDio = refreshDio ?? _getRefreshDio(baseUrl);

  void _resetTokenRefreshFlags() {
    if (_isRefreshingToken) _isRefreshingToken = false;
    if (_refreshSuccessful) _refreshSuccessful = false;
  }

  static Dio _getRefreshDio(String baseUrl) {
    final Dio retryDio = Dio(BaseOptions(baseUrl: baseUrl))
      ..interceptors.add(LoggingInterceptor());
    Dio getRetryDioClient() => retryDio;
    return getRetryDioClient();
  }

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = tokenStorage.onGetAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return super.onRequest(options, handler);
  }

  void _logUnknownErrors(DioException err) async {
    if (err.type == DioExceptionType.unknown && !kDebugMode) {
      if (onUnknownErrors != null) {
        onUnknownErrors!(err);
      }
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    _logUnknownErrors(err);
    if (err.response?.statusCode == _unAuthCode) {
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
      final refreshToken = tokenStorage.onGetRefreshToken();
      if (refreshToken == null) {
        _refreshSuccessful = false;
        await authHandler.onSessionExpired();
        throw Exception('No refresh token available');
      }

      final response = await _makeRefreshTokenRequest(refreshToken);
      await _extractTokenFromResponse(response);
    } catch (e) {
      _refreshSuccessful = false;
      rethrow;
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
    final accessToken = tokenStorage.onGetAccessToken();
    if (accessToken == null) {
      throw Exception('No access token available for retrying request');
    }
    try {
      final response = await _refreshDio.request(
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
      _retrySuccessCount++;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleSessionExpired() async {
    await tokenStorage.onClearTokens();
    await authHandler.onSessionExpired();
  }
}
