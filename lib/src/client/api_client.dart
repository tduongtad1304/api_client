import '../models/api_request.dart';
import '../models/api_response.dart';

abstract class ApiClient {
  Future<ApiResponse> execute({required ApiRequest request});
}

abstract class StripeAPIClient {
  Future<dynamic> execute({required ApiRequest request});
}
