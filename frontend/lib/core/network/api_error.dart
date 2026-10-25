import 'package:dio/dio.dart';

String apiErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) return first['msg'].toString();
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your connection and try again.';
      default:
        break;
    }

    final code = error.response?.statusCode;
    if (code == 401) return 'Your session has expired. Please log in again.';
    if (code == 403) return 'You do not have permission to do this.';
    return fallback;
  }

  final text = error.toString();
  if (text.startsWith('Exception: ')) return text.substring('Exception: '.length);
  return fallback;
}