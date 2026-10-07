import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    _setUpCrashReporting();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FCMService.initialize();
  } catch (e) {
    debugPrint('Firebase/FCM initialization failed: $e');
  }
  runApp(const ProviderScope(child: SmartVanApp()));
}

/// Sends crashes (Flutter framework + uncaught async errors) to Firebase
/// Crashlytics in release builds. Debug builds keep the normal red screen.
void _setUpCrashReporting() {
  final crashlytics = FirebaseCrashlytics.instance;
  crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashlytics.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}

class SmartVanApp extends StatelessWidget {
  const SmartVanApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SmartVan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: appRouter,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}
