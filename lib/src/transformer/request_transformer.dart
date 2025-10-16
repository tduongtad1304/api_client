import 'package:api_client/api_client.dart';

class RequestTransformer {
  // File detection configuration
  static const List<String> _fileKeys = [
    'file',
    'image',
    'video',
    'document',
    'attachment'
  ];

  static const Map<String, List<String>> _fileExtensionsByType = {
    'image': [
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.bmp',
      '.webp',
      '.tiff',
      '.svg',
      '.ico',
      '.heic'
    ],
    'video': [
      '.mp4',
      '.mov',
      '.avi',
      '.wmv',
      '.flv',
      '.mkv',
      '.webm',
      '.3gp',
      '.mpeg',
      '.mpg',
      '.m4v'
    ],
    'audio': ['.mp3', '.wav', '.aac', '.ogg', '.flac', '.m4a', '.wma', '.opus'],
    'archive': ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'],
    'document': [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt',
      '.csv',
      '.json',
      '.xml'
    ],
  };

  static final List<String> _allFileExtensions =
      _fileExtensionsByType.values.expand((extensions) => extensions).toList();

  /// Transforms request data to FormData ( if `ApiClientBuilder.useFormDataForMedia` is set to true ) if it contains files, otherwise returns original data
  static Future<dynamic> transformRequest(dynamic data) async {
    if (!_shouldTransformToFormData(data)) {
      return data;
    }

    try {
      return await _createFormData(data as Map<String, dynamic>);
    } catch (e) {
      Console.log('Error transforming request to FormData: $e');
      rethrow;
    }
  }

  /// Checks if data should be transformed to FormData
  static bool _shouldTransformToFormData(dynamic data) {
    if (data is! Map<String, dynamic>) return false;

    return _containsFileKeys(data) || _containsFilePaths(data);
  }

  /// Checks if data contains predefined file keys
  static bool _containsFileKeys(Map<String, dynamic> data) {
    return _fileKeys.any((key) => data.containsKey(key));
  }

  /// Checks if data contains file paths based on extensions
  static bool _containsFilePaths(Map<String, dynamic> data) {
    return data.values.any((value) => _isFilePath(value));
  }

  /// Determines if a value is a file path
  static bool _isFilePath(dynamic value) {
    if (value is! String) return false;

    final lowerValue = value.toLowerCase();
    return _allFileExtensions
        .any((ext) => lowerValue.endsWith(ext.toLowerCase()));
  }

  /// Creates FormData from map containing files
  static Future<FormData> _createFormData(Map<String, dynamic> data) async {
    final Map<String, dynamic> formDataMap = {};

    // Process all entries in the data map
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (_shouldProcessAsFile(key, value)) {
        try {
          final multipartFile = await _createMultipartFile(value as String);
          formDataMap[key] = multipartFile;
        } catch (e) {
          Console.log('Error creating MultipartFile for key "$key": $e');
          throw ArgumentError('Failed to create MultipartFile for "$key": $e');
        }
      } else {
        // Keep non-file data as is
        formDataMap[key] = value;
      }
    }

    if (formDataMap.isEmpty) {
      throw ArgumentError('No valid data found for FormData creation');
    }

    return FormData.fromMap(formDataMap);
  }

  /// Determines if a key-value pair should be processed as a file
  static bool _shouldProcessAsFile(String key, dynamic value) {
    return _fileKeys.contains(key) || _isFilePath(value);
  }

  /// Creates a MultipartFile from file path
  static Future<MultipartFile> _createMultipartFile(String filePath) async {
    return await MultipartFile.fromFile(filePath);
  }

  // /// Gets file type based on extension
  // static String? getFileType(String filePath) {
  //   final lowerPath = filePath.toLowerCase();

  //   for (final entry in _fileExtensionsByType.entries) {
  //     if (entry.value.any((ext) => lowerPath.endsWith(ext.toLowerCase()))) {
  //       return entry.key;
  //     }
  //   }

  //   return null;
  // }

  // /// Validates if file extension is supported
  // static bool isSupportedFileType(String filePath) {
  //   return getFileType(filePath) != null;
  // }
}
