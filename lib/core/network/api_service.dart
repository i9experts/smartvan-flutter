import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  static Future<void> _addAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  static Future<Response> get(String path) async {
    await _addAuthHeader();
    return await _dio.get(path);
  }

  static Future<Response> post(String path, Map<String, dynamic> data) async {
    await _addAuthHeader();
    return await _dio.post(path, data: data);
  }

  static Future<Response> put(String path, Map<String, dynamic> data) async {
    await _addAuthHeader();
    return await _dio.put(path, data: data);
  }

  static Future<Response> delete(String path) async {
    await _addAuthHeader();
    return await _dio.delete(path);
  }
}