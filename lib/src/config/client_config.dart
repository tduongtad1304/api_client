import 'dart:developer' as developer;

import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';

class ApiClientBuilder {
  String _baseUrl = '';
  TokenStorage? _tokenStorage;
  AuthEventHandler? _authHandler;
  LogLevel _logLevel = LogLevel.basic;
  LogCallback? _logCallback;
  void Function(DioException error)? _onUnknownErrors;
  final List<Interceptor> _additionalInterceptors = [];
  bool _enableShowErrorMessagesLogs = false;
  Dio? _exposedDio;

  ApiClientBuilder._internal();

  static final ApiClientBuilder _instance = ApiClientBuilder._internal();

  factory ApiClientBuilder() => _instance;

  ApiClientBuilder setBaseUrl(String url) {
    _baseUrl = url;
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

  ApiClientBuilder setShowErrorMessagesLogsEnabled(bool enable) {
    _enableShowErrorMessagesLogs = enable;
    return this;
  }

  Dio? get dio => _exposedDio;

  ApiClientBuilder setDioExposedEnabled([bool enabled = true]) {
    if (enabled) {
      _exposedDio = Dio(BaseOptions());
    } else {
      _exposedDio = null;
    }
    return this;
  }

  ApiClientInterface build([bool forceTransformUploadMediaRequest = true]) {
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));

    if (kDebugMode) {
      final logCallback = _logCallback ?? developer.log;
      dio.interceptors.add(LoggingInterceptor(
        logLevel: _logLevel,
        log: logCallback,
        isShowErrorMessage: _enableShowErrorMessagesLogs,
      ));
    }

    if (_tokenStorage != null && _authHandler != null) {
      dio.interceptors.add(AuthInterceptor(
        tokenStorage: _tokenStorage!,
        authHandler: _authHandler!,
        baseUrl: _baseUrl,
        onUnknownErrors: _onUnknownErrors,
      ));
    }

    for (final interceptor in _additionalInterceptors) {
      dio.interceptors.add(interceptor);
    }
    if (forceTransformUploadMediaRequest) {
      dio.transformer = RequestTransformer();
    }

    return ApiClientImpl(dio: dio);
  }
}
