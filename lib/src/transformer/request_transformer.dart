import 'package:api_client/api_client.dart';

class RequestTransformer {
  static const List<String> _fileKeys = ['file', 'image', 'video'];
  static const List<String> _mediaFileExt = [
    // Images
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.tiff', '.svg',
    // Videos
    '.mp4', '.mov', '.avi', '.wmv', '.flv', '.mkv', '.webm', '.3gp', '.mpeg',
    // Audio
    '.mp3', '.wav', '.aac', '.ogg', '.flac', '.m4a', '.wma',
    // Media files
    '.zip', '.rar', '.7z', '.txt', '.csv', '.json', '.xml',
    // Documents
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'
  ];

  static Future<dynamic> transformRequest(dynamic data) async {
    if (_shouldTransformToFormData(data)) {
      final formData = await _createFormData(data);
      return formData;
    }
    return data;
  }

  static bool _shouldTransformToFormData(dynamic data) {
    return data is Map<String, dynamic> &&
        (_fileKeys.any((key) => data.containsKey(key)) ||
            data.values.any((value) =>
                value is String &&
                _mediaFileExt.any(
                    (ext) => value.toLowerCase().endsWith(ext.toLowerCase()))));
  }

  static Future<FormData> _createFormData(Map<String, dynamic> data) async {
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
}
