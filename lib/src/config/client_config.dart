import 'dart:developer' as developer;

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClientBuilder implements ApiClientConfig {
  String _baseUrl = '';
  TokenStorage? _tokenStorage;
  AuthEventHandler? _authHandler;
  LogLevel _logLevel = LogLevel.basic;
  LogCallback? _logCallback;
  void Function(DioException error)? _onUnknownErrors;
  final List<Interceptor> _additionalInterceptors = [];
  bool _enableShowErrorMessagesLogs = false;

  ApiClientBuilder._internal();

  static final ApiClientBuilder _instance = ApiClientBuilder._internal();

  factory ApiClientBuilder() => _instance;

  @override
  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  @override
  void setTokenStorage(TokenStorage storage) {
    _tokenStorage = storage;
  }

  @override
  void setAuthHandler(AuthEventHandler handler) {
    _authHandler = handler;
  }

  @override
  void setLogLevel(LogLevel level) {
    _logLevel = level;
  }

  @override
  void setLogCallback(LogCallback callback) {
    _logCallback = callback;
  }

  @override
  void addInterceptor(Interceptor interceptor) {
    _additionalInterceptors.add(interceptor);
  }

  @override
  void setOnUnknownErrors(void Function(DioException error)? callback) {
    _onUnknownErrors = callback;
  }

  @override
  void setEnableShowErrorMessagesLogs(bool enable) {
    _enableShowErrorMessagesLogs = enable;
  }

  @override
  ApiClientInterface build() {
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));

    // Add logging interceptor
    if (kDebugMode) {
      final logCallback = _logCallback ?? developer.log;
      dio.interceptors.add(LoggingInterceptor(
        logLevel: _logLevel,
        log: logCallback,
        isShowErrorMessage: _enableShowErrorMessagesLogs,
      ));
    }

    // Add auth interceptor if token storage is provided
    if (_tokenStorage != null && _authHandler != null) {
      dio.interceptors.add(AuthInterceptor(
        tokenStorage: _tokenStorage!,
        authHandler: _authHandler!,
        baseUrl: _baseUrl,
        onUnknownErrors: _onUnknownErrors,
      ));
    }

    // Add additional interceptors
    for (final interceptor in _additionalInterceptors) {
      dio.interceptors.add(interceptor);
    }

    return ApiClientImpl(dio: dio);
  }
}
