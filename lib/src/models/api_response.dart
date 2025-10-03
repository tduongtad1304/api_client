class ApiResponse<T> {
  final T data;
  final int? status;
  final String? message;

  ApiResponse({
    required this.data,
    this.status,
    this.message,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      data: json['data'],
      status: json['status'],
      message: json['message'],
    );
  }
}
