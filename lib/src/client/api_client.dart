import 'package:dio/dio.dart';

abstract class ApiClient {
  Future<void> execute(
      {required String method,
      required String path,
      required Map<String, dynamic> parameters,
      Map<String, dynamic>? body,
      void Function(int, int)? onSendProgress,
      dynamic Function(Response response)? onSuccess,
      dynamic Function(DioException error)? onError});
}
