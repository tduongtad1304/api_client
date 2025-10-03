import 'package:dio/dio.dart';
import '../models/api_request.dart';
import '../models/api_response.dart';
import '../models/api_error.dart';
import './api_client.dart';

class ApiClientImpl implements ApiClient {
  final Dio dio;

  ApiClientImpl({required this.dio});

  @override
  Future<ApiResponse> execute({required ApiRequest request}) async {
    final options = Options(
      method: request.method.value,
      contentType: Headers.jsonContentType,
    );

    try {
      final response = await dio.request(
        request.path,
        queryParameters: request.parameters,
        data: request.body,
        options: options,
        onSendProgress: request.onSendProgress,
      );

      return ApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'An unexpected error occurred: ${e.toString()}');
    }
  }

  ApiError _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode ?? 500;

    try {
      final json = error.response?.data as Map<String, dynamic>;
      return ApiError(
        statusCode: statusCode,
        message: json['message'],
        error: json['error'],
      );
    } catch (e) {
      return ApiError(
        statusCode: statusCode,
        message: error.message ?? 'Unknown error',
        error: error.type.toString(),
      );
    }
  }
}
