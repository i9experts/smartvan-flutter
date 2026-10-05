import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // This app has no web push (VAPID) setup or firebase_options.dart for web,
  // so it isn't a supported target for Firebase Messaging there. On web,
  // the JS SDK's dynamic import() hangs the whole app indefinitely on any
  // network/CSP block instead of rejecting (so it can't even be try/caught)
  // — skip it outright rather than risk the entire app never rendering.
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      await FCMService.initialize();
    } catch (e) {
      debugPrint(
          'Firebase init failed, continuing without push notifications: $e');
    }
  }
  runApp(const ProviderScope(child: SmartVanApp()));
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
    );
  }
}
