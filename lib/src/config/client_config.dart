import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';
import '../auth/auth_handler.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/logging_interceptor.dart';
import '../client/api_client.dart';
import '../client/api_client_impl.dart';

class ApiClientBuilder {
  String baseUrl = '';
  TokenStorage? _tokenStorage;
  AuthEventHandler? _authHandler;
  LogLevel _logLevel = LogLevel.basic;
  LogCallback? _logCallback;
  void Function(DioException error)? _onUnknownErrors;
  final List<Interceptor> _additionalInterceptors = [];

  ApiClientBuilder setBaseUrl(String url) {
    baseUrl = url;
    return this;
  }

  ApiClientBuilder setTokenStorage(TokenStorage storage) {
    _tokenStorage = storage;
    return this;
  }

  ApiClientBuilder setAuthHandler(AuthEventHandler handler) {
    _authHandler = handler;
    return this;
  }

  ApiClientBuilder setLogLevel(LogLevel level) {
    _logLevel = level;
    return this;
  }

  ApiClientBuilder setLogCallback(LogCallback callback) {
    _logCallback = callback;
    return this;
  }

  ApiClientBuilder addInterceptor(Interceptor interceptor) {
    _additionalInterceptors.add(interceptor);
    return this;
  }

  ApiClientBuilder setOnUnknownErrors(
      void Function(DioException error)? callback) {
    _onUnknownErrors = callback;
    return this;
  }

  ApiClientInterface build() {
    final dio = Dio(BaseOptions(baseUrl: baseUrl));

    // Add logging interceptor
    if (kDebugMode) {
      final logCallback = _logCallback ?? developer.log;
      dio.interceptors.add(LoggingInterceptor(
        logLevel: _logLevel,
        log: logCallback,
      ));
    }

    // Add auth interceptor if token storage is provided
    if (_tokenStorage != null && _authHandler != null) {
      dio.interceptors.add(AuthInterceptor(
        tokenStorage: _tokenStorage!,
        authHandler: _authHandler!,
        baseUrl: baseUrl,
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
