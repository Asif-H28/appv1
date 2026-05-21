import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationSocketService {
  IO.Socket? _socket;
  
  // Callback when a new notification arrives
  Function(NotificationModel)? onNewNotification;
  // Callback when unread count changes
  Function(int)? onUnreadCountChanged;

  void connect(String baseUrl, String jwtToken) {
    if (_socket != null && _socket!.connected) return;

    debugPrint('Connecting to Notification Studio socket namespace `/notifications`...');
    
    // Connect to the "/notifications" namespace
    _socket = IO.io('$baseUrl/notifications', IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': jwtToken})
      .enableForceNew()
      .enableAutoConnect()
      .build()
    );

    _socket!.onConnect((_) {
      debugPrint('💡 Connected to Notification Studio socket namespace `/notifications`.');
    });

    // Listen for real-time count updates
    _socket!.on('unread_count', (data) {
      debugPrint('💡 Notification Studio unread count updated: $data');
      int count = 0;
      if (data is Map) {
        count = data['count'] ?? 0;
      } else if (data is int) {
        count = data;
      }
      if (onUnreadCountChanged != null) {
        onUnreadCountChanged!(count);
      }
    });

    // Listen for new in-app notifications
    _socket!.on('new_notification', (data) {
      debugPrint('💡 Notification Studio new notification event: $data');
      try {
        if (data != null) {
          final notification = NotificationModel.fromJson(Map<String, dynamic>.from(data));
          if (onNewNotification != null) {
            onNewNotification!(notification);
          }
        }
      } catch (e) {
        debugPrint('Error parsing new_notification: $e');
      }
    });

    _socket!.onDisconnect((reason) {
      debugPrint('🔌 Disconnected from Notification Studio. Reason: $reason');
    });

    _socket!.onConnectError((err) {
      debugPrint('❌ Notification Socket Connection Error: $err');
    });

    _socket!.connect();
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }
}
