import 'package:api_client/api_client.dart';

class RequestTransformer extends Transformer {
  static const List<String> _fileKeys = ['file', 'image', 'video'];

  @override
  Future<String> transformRequest(RequestOptions options) async {
    final data = options.data as Map<String, dynamic>;

    if (_shouldTransformToFormData(data)) {
      final formData = await _createFormData(data);
      options.data = formData;
    }
    return options.data?.toString() ?? '';
  }

  bool _shouldTransformToFormData(dynamic data) {
    return data is Map<String, dynamic> &&
        _fileKeys.any((key) => data.containsKey(key));
  }

  Future<FormData> _createFormData(Map<String, dynamic> data) async {
    for (final key in _fileKeys) {
      if (data.containsKey(key)) {
        try {
          final multiPart = await MultipartFile.fromFile(data[key]);
          return FormData.fromMap({key: multiPart});
        } catch (e) {
          Console.log('Error creating MultipartFile: $e');
          throw ArgumentError('Failed to create MultipartFile: $e');
        }
      }
    }

    throw ArgumentError('No valid file key found in data map');
  }

  @override
  Future transformResponse(RequestOptions options, ResponseBody responseBody) {
    throw UnimplementedError();
  }
}
