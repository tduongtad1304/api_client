class ApiError implements Exception {
  final int? statusCode;
  final String? error;
  final String message;

  ApiError({
    this.statusCode,
    this.error,
    required this.message,
  });

  @override
  String toString() => 'ApiError: $message';
}
