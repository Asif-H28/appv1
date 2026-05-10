import 'package:flutter/material.dart';
import '../../chat/chat_screen.dart';
import '../../../core/services/chat_socket_service.dart';

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
    // Handle Chat Notifications using the new 'chatnotification' key
    final isChatNotification = data['chatnotification'] == 'true' || type == 'chat';
    
    if (isChatNotification) {
      // Trigger global unread count refresh across the app
      ChatSocketService().triggerUnreadRefresh();

      final conversationId = data['conversationId']?.toString();
      final senderName = data['senderName']?.toString() ?? 'New Message';
      final senderId = data['senderId']?.toString() ?? '';
      
      debugPrint('[ChatNotif] Processing chat notification for $conversationId');

      if (conversationId != null) {
        // Example Action: Only navigate if we aren't already in THAT specific conversation
        // (You can implement more complex state checks here)
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
