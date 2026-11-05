import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.from(Object error) {
    if (error is ApiException) {
      return error;
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      // Server-side failures can carry stack traces and SQL in the body, so
      // only the fact that the request failed is passed on to the UI.
      if (statusCode != null && statusCode >= 500) {
        return ApiException(
          'SmartBank could not complete the request. Please try again.',
          statusCode: statusCode,
        );
      }

      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString();
        final validation = data['validationErrors'];
        if (validation is Map && validation.isNotEmpty) {
          final details = validation.values.map((e) => e.toString()).join('\n');
          return ApiException(
            details.isEmpty
                ? (message ?? 'Request validation failed')
                : details,
            statusCode: statusCode,
          );
        }
        if (message != null && message.isNotEmpty) {
          return ApiException(message, statusCode: statusCode);
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return const ApiException(
            'Unable to reach SmartBank. Check your connection and try again.',
          );
        default:
          return ApiException(
            error.message ?? 'Request failed',
            statusCode: statusCode,
          );
      }
    }

    return ApiException(error.toString());
  }

  @override
  String toString() => message;
}
