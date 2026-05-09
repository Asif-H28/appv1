import 'package:flutter/material.dart';
import '../../chat/chat_screen.dart';

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

  static void handleData(Map<String, dynamic> data) {
    debugPrint('[NotifRouter] data: $data');
    final type = data['type']?.toString();
    
    if (type == 'chat') {
      final conversationId = data['conversationId']?.toString();
      final senderName = data['senderName']?.toString() ?? 'Chat';
      final senderId = data['senderId']?.toString() ?? '';
      
      if (conversationId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversationId,
              participantName: senderName,
              participantId: senderId,
            ),
          ),
        );
        return;
      }
    }

    final route = data['route']?.toString();
    if (route != null) handleRoute(route);
  }
}
