import 'dart:io';
import 'package:dio/dio.dart';

/// Error from the backend in the `{ success:false, code, message }` shape.
///
/// This app's Dio client treats every status < 500 as success (it doesn't
/// throw on 4xx), so new code calls [ApiErrors.ensureOk] on the response.
class ApiException implements Exception {
  final int? status;
  final String? code;
  final String message;
  const ApiException(this.message, {this.status, this.code});
  @override
  String toString() => message;
}

class ApiErrors {
  ApiErrors._();

  /// Throws [ApiException] if [res] is a 4xx/5xx.
  static Response ensureOk(Response res, {String fallback = 'Something went wrong. Please try again.'}) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return res;
    final data = res.data;
    String? code;
    String message = fallback;
    if (data is Map) {
      if (data['code'] is String) code = data['code'] as String;
      final m = data['message'];
      if (m is String && m.trim().isNotEmpty) message = m;
      if (m is List && m.isNotEmpty) message = m.first.toString();
    }
    throw ApiException(message, status: status, code: code);
  }

  static bool isNetworkError(Object e) {
    if (e is SocketException) return true;
    if (e is! DioException) return false;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.unknown:
        return e.error is SocketException || e.response == null;
      default:
        return false;
    }
  }

  static String? code(Object e) => e is ApiException ? e.code : null;

  static String message(Object e, {String fallback = 'Something went wrong. Please try again.'}) {
    if (e is ApiException) return e.message;
    if (isNetworkError(e)) return 'No internet connection. Please check your network and try again.';
    if (e is DioException && (e.response?.statusCode ?? 0) >= 500) {
      return 'Server is having trouble right now. Please try again shortly.';
    }
    return fallback;
  }
}
