import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  static Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  static Future<void> _addAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  static Future<Response> get(String path) async {
    await _addAuthHeader();
    try {
      final response = await _dio.get(path);
      debugPrint('GET $path => ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      debugPrint('GET $path ERROR => ${e.message} | ${e.response?.data}');
      rethrow;
    }
  }

  static Future<Response> post(String path, Map<String, dynamic> data) async {
    await _addAuthHeader();
    try {
      final response = await _dio.post(path, data: data);
      debugPrint('POST $path => ${response.statusCode} | ${response.data}');
      return response;
    } on DioException catch (e) {
      debugPrint('POST $path ERROR => ${e.message} | ${e.response?.data}');
      rethrow;
    }
  }

  static Future<Response> put(String path, Map<String, dynamic> data) async {
    await _addAuthHeader();
    try {
      final response = await _dio.put(path, data: data);
      debugPrint('PUT $path => ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      debugPrint('PUT $path ERROR => ${e.message} | ${e.response?.data}');
      rethrow;
    }
  }

  static Future<Response> patch(String path, Map<String, dynamic> data) async {
    await _addAuthHeader();
    try {
      final response = await _dio.patch(path, data: data);
      debugPrint('PATCH $path => ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      debugPrint('PATCH $path ERROR => ${e.message} | ${e.response?.data}');
      rethrow;
    }
  }

  static Future<Response> delete(String path) async {
    await _addAuthHeader();
    try {
      final response = await _dio.delete(path);
      debugPrint('DELETE $path => ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      debugPrint('DELETE $path ERROR => ${e.message} | ${e.response?.data}');
      rethrow;
    }
  }

  /// Uploads an image file to the dedicated /upload/image endpoint
  /// (multipart field name is 'file') and returns the resulting S3 URL.
  /// Use this BEFORE calling addKid/update-profile/etc — those endpoints
  /// expect `image` as a plain string URL, not a raw file.
  static Future<String?> uploadImage(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);

    final uploadDio = Dio();
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await uploadDio.post(
        '${AppConstants.baseUrl}/upload/image',
        data: formData,
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      debugPrint('POST /upload/image => ${response.statusCode} | ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['url'] as String?;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('POST /upload/image ERROR => ${e.message} | ${e.response?.data}');
      rethrow;
    }
  }
}
