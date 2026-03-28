import 'package:flutter/material.dart';

// ── Global navigator key ───────────────────────────────
// Add this to your MaterialApp: navigatorKey: navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationRouter {
  static void handleRoute(String route) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    debugPrint('[NotifRouter] route: $route');

    switch (route) {
      case '/notices':
        navigatorKey.currentState?.pushNamed('/notices');
        break;
      case '/attendance':
        navigatorKey.currentState?.pushNamed('/attendance');
        break;
      case '/results':
        navigatorKey.currentState?.pushNamed('/results');
        break;
      case '/home':
        navigatorKey.currentState?.popUntil((r) => r.isFirst);
        break;
      default:
        navigatorKey.currentState?.popUntil((r) => r.isFirst);
        break;
    }
  }
}
