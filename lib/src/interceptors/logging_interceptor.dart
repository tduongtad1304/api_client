import 'package:dio/dio.dart';

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

  LoggingInterceptor({
    this.logLevel = LogLevel.basic,
    this.log = print,
  });

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
    if (logLevel != LogLevel.none) {
      log('⚠️ [${err.response?.statusCode ?? 'ERROR'}] [${err.requestOptions.method}] ${err.requestOptions.uri}');
      log('Error message: ${err.message}');
    }
    super.onError(err, handler);
  }
}
