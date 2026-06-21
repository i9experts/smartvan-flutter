import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../network/api_service.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }

    _messaging.onTokenRefresh.listen(_saveFCMToken);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        debugPrint('FCM: ${message.notification!.title}');
      }
    });
  }

  static Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString(AppConstants.tokenKey);
      if (authToken != null) {
        await ApiService.post('/auth/updateFcmToken', {
          'fcmToken': token,
        });
      }
      await prefs.setString('fcm_token', token);
    } catch (e) {
      debugPrint('FCM token save error: $e');
    }
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}