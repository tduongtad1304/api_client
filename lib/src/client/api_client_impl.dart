import 'package:api_client/api_client.dart';

class ApiClientImpl implements ApiClientInterface {
  final Dio dio;
  final bool useFormDataForMedia;

  ApiClientImpl({required this.dio, required this.useFormDataForMedia});

  @override
  Future<void> execute({
    required String method,
    required String path,
    Map<String, dynamic>? parameters,
    dynamic body,
    void Function(int, int)? onSendProgress,
    dynamic Function(Response response)? onSuccess,
    dynamic Function(DioException error)? onError,
  }) async {
    final options = Options(
      method: method,
      contentType: Headers.jsonContentType,
    );

    if (useFormDataForMedia &&
        method.toUpperCase() == RequestMethod.post.value) {
      body = await RequestTransformer.transformRequest(body);
    }

    try {
      final response = await dio.request(
        path,
        queryParameters: parameters,
        data: body,
        options: options,
        onSendProgress: onSendProgress,
      );

      if (onSuccess != null) {
        onSuccess(response);
      }
    } on DioException catch (e) {
      if (onError != null) {
        onError(_handleDioError(e));
      } else {
        throw _handleDioError(e);
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  _handleDioError(DioException error) {
    try {
      final json = error.response?.data as Map<String, dynamic>;
      return DioException(
        requestOptions: error.response?.requestOptions ?? error.requestOptions,
        response: error.response,
        message: json['message'],
        type: error.type,
        error: error.error,
      );
    } catch (e) {
      return DioException(
        requestOptions: error.response?.requestOptions ?? error.requestOptions,
        response: error.response,
        message: error.message ?? 'Unknown error',
        type: error.type,
        error: error.error,
      );
    }
  }
}
