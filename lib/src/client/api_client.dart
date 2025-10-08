import 'package:api_client/api_client.dart';

abstract interface class ApiClientInterface {
  Future<void> execute(
      {required String method,
      required String path,
      Map<String, dynamic>? parameters,
      dynamic body,
      void Function(int, int)? onSendProgress,
      dynamic Function(Response response)? onSuccess,
      dynamic Function(DioException error)? onError});
}
