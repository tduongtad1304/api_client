import 'http_method.dart';

class ApiRequest {
  ApiRequest({
    required this.method,
    required this.path,
    this.headers,
    this.parameters,
    this.body,
    this.onSendProgress,
  });

  RequestMethod method;
  String path;
  dynamic headers;
  dynamic parameters;
  dynamic body;
  Function(int, int)? onSendProgress;
}
