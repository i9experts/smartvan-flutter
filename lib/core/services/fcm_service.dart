import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/token_storage.dart';
import '../network/api_service.dart';
import 'notification_router.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _messaging.onTokenRefresh.listen(_saveFCMToken);

    // Not awaited: on iOS this can take a few seconds while APNs registers.
    getToken().then((token) {
      if (token != null) _saveFCMToken(token);
    });

    // App open: show an in-app banner (safety alerts in red).
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      NotificationRouter.showForeground(
        title: message.notification?.title,
        body: message.notification?.body,
        data: message.data,
      );
    });

    // Tapped while the app was in the background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      NotificationRouter.open(message.data);
    });

    // Tapped while the app was closed — splash opens it after login check.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      NotificationRouter.pendingRoute = NotificationRouter.routeFor(initial.data);
    }
  }

  static Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (await TokenStorage.hasToken()) {
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
    if (Platform.isIOS) {
      // On iOS the FCM token is only issued once the APNs token exists.
      String? apns = await _messaging.getAPNSToken();
      for (var i = 0; apns == null && i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        apns = await _messaging.getAPNSToken();
      }
      if (apns == null) {
        debugPrint('FCM: APNs token not available (simulator or push not set up)');
        return null;
      }
    }
    return await _messaging.getToken();
  }
}
