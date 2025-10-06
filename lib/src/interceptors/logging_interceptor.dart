import 'package:dio/dio.dart';
import 'dart:developer' as developer;

enum LogLevel {
  none,
  basic,
  headers,
  body,
  all,
}

typedef LogCallback = void Function(String message);

class LoggingInterceptor extends Interceptor {
  final LogLevel logLevel;
  final LogCallback log;
  final bool isShowErrorMessage;

  LoggingInterceptor({
    this.logLevel = LogLevel.basic,
    this.log = developer.log,
    this.isShowErrorMessage = false,
  });

  static const int _unAuthCode = 401;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (logLevel != LogLevel.none) {
      log('→ [${options.method}] ${options.uri}');

      if (logLevel.index >= LogLevel.headers.index) {
        log('Headers: ${options.headers}');
      }

      if (logLevel.index >= LogLevel.body.index && options.data != null) {
        log('Request data: ${options.data}');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (logLevel != LogLevel.none) {
      log('← [${response.statusCode}] [${response.requestOptions.method}] ${response.requestOptions.uri}');

      if (logLevel.index >= LogLevel.body.index) {
        log('Response data: ${response.data}');
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestOptions = err.response?.requestOptions;
    if (err.response?.statusCode == LoggingInterceptor._unAuthCode) {
      log('🚷 [401 Unauthorized] Request [${requestOptions?.method}] '
          '${requestOptions?.path}');
      return;
    }
    if (logLevel != LogLevel.none) {
      log('⛔️ [${err.response?.statusCode ?? 'ERROR'}] [${requestOptions?.method}] ${requestOptions?.uri}');
      if (isShowErrorMessage) log('Error message: ${err.message}');
    }
    handler.next(err);
  }
}
