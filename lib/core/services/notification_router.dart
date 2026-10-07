import 'package:flutter/material.dart';
import '../router/app_router.dart';

/// Shared keys + routing for push notifications.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class NotificationRouter {
  NotificationRouter._();

  /// Route opened from a notification tapped while the app was closed;
  /// consumed by the splash screen after it decides where to go.
  static String? pendingRoute;

  /// Safety alerts that must stand out even in the foreground.
  static const _urgentTypes = {'driver_sos', 'drop_not_confirmed', 'NO_SHOW'};

  static String? routeFor(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    if (type == 'CHAT_MESSAGE') return '/chats';
    if (type == 'PAYMENT_RECEIVED') return '/payment-history';
    if (type == 'driver_sos' || type == 'ETA_UPDATE' || type == 'VAN_AT_STOP' || type.startsWith('GEOFENCE_')) {
      return '/tracking';
    }
    if (type == 'drop_not_confirmed' || type == 'NO_SHOW') return '/alerts';
    return null;
  }

  static void open(Map<String, dynamic> data) {
    final route = routeFor(data);
    if (route != null) appRouter.push(route);
  }

  /// In-app banner for a push received while the app is open.
  static void showForeground({
    required String? title,
    required String? body,
    required Map<String, dynamic> data,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null || (title == null && body == null)) return;
    final urgent = _urgentTypes.contains(data['type']?.toString());
    final route = routeFor(data);
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: urgent ? const Color(0xFFE53935) : const Color(0xFF1B2B6B),
        duration: Duration(seconds: urgent ? 12 : 5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            if (body != null) Text(body, style: const TextStyle(fontFamily: 'Poppins')),
          ],
        ),
        action: route == null
            ? null
            : SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => appRouter.push(route),
              ),
      ),
    );
  }
}
