import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';

abstract class ApiClientConfig {
  void setBaseUrl(String url);
  void setTokenStorage(TokenStorage storage);
  void setAuthHandler(AuthEventHandler handler);
  void setLogLevel(LogLevel level);
  void setLogCallback(LogCallback callback);
  void addInterceptor(Interceptor interceptor);
  void setOnUnknownErrors(void Function(DioException error)? callback);
  void setEnableShowErrorMessagesLogs(bool enable);
  ApiClientInterface build();
}
