import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  IO.Socket? socket;

  // Streams for real-time updates
  final _onNewMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onTypingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onStopTypingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onStatusUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onOnlineStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onRefreshUnreadController = StreamController<void>.broadcast();

  Stream<Map<String, dynamic>> get onNewMessage =>
      _onNewMessageController.stream;
  Stream<Map<String, dynamic>> get onTyping => _onTypingController.stream;
  Stream<Map<String, dynamic>> get onStopTyping =>
      _onStopTypingController.stream;
  Stream<Map<String, dynamic>> get onStatusUpdate =>
      _onStatusUpdateController.stream;
  Stream<Map<String, dynamic>> get onOnlineStatus =>
      _onOnlineStatusController.stream;
  Stream<void> get onRefreshUnread => _onRefreshUnreadController.stream;

  String? _currentUserId;

  void connect(String userId, String token) {
    if (socket?.connected ?? false) {
      if (_currentUserId == userId) return; // Same user already connected
      disconnect(); // New user, must disconnect old session
    }

    _currentUserId = userId;

    socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token, 'userId': userId})
          .enableForceNew()
          .enableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      print('Connected to Chat Socket');
      socket!.emit('user_online', userId);
      triggerUnreadRefresh();
    });

    socket!.on('new_message', (data) => _onNewMessageController.add(data));
    socket!.on('typing', (data) => _onTypingController.add(data));
    socket!.on('stop_typing', (data) => _onStopTypingController.add(data));
    socket!.on(
      'message_status_update',
      (data) => _onStatusUpdateController.add(data),
    );
    socket!.on('online_status', (data) => _onOnlineStatusController.add(data));

    socket!.onDisconnect((_) => print('Disconnected from Chat Socket'));
    socket!.connect();
  }

  void joinConversation(String conversationId) {
    socket?.emit('join_conversation', conversationId);
  }

  void sendMessage(Map<String, dynamic> payload) {
    socket?.emit('send_message', payload);
  }

  void emitTyping(String conversationId, String userId, String userName) {
    socket?.emit('typing', {
      'conversationId': conversationId,
      'userId': userId,
      'userName': userName,
    });
  }

  void emitStopTyping(String conversationId, String userId) {
    socket?.emit('stop_typing', {
      'conversationId': conversationId,
      'userId': userId,
    });
  }

  void emitDelivered(String messageId, String conversationId) {
    socket?.emit('message_delivered', {
      'messageId': messageId,
      'conversationId': conversationId,
    });
  }

  void emitRead(String conversationId, String userId) {
    socket?.emit('message_read', {
      'conversationId': conversationId,
      'userId': userId,
    });
  }

  void triggerUnreadRefresh() {
    _onRefreshUnreadController.add(null);
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}
