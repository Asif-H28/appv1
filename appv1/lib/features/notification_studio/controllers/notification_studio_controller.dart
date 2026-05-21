import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';
import '../services/notification_socket_service.dart';
import '../widgets/in_app_notification_overlay.dart';

class NotificationStudioController extends ChangeNotifier {
  static final NotificationStudioController _instance = NotificationStudioController._internal();
  factory NotificationStudioController() => _instance;
  NotificationStudioController._internal();

  final NotificationApiService _apiService = NotificationApiService();
  final NotificationSocketService _socketService = NotificationSocketService();

  int _unreadCount = 0;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _currentToken;

  int get unreadCount => _unreadCount;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  void init(String token) {
    if (_isInitialized && _currentToken == token) return;
    _currentToken = token;
    _isInitialized = true;

    debugPrint('Initializing NotificationStudioController...');

    // 1. Establish real-time connection
    _socketService.connect(ApiConstants.baseUrl, token);

    // 2. Set up event listeners
    _socketService.onUnreadCountChanged = (count) {
      _unreadCount = count;
      _safeNotifyListeners();
    };

    _socketService.onNewNotification = (notification) {
      // Prepend to current list if loaded
      _notifications.insert(0, notification);
      _unreadCount++;
      _safeNotifyListeners();
      
      // Trigger a custom toast message in-app
      InAppNotificationOverlay.show(notification);
    };


    // 3. Perform initial REST pull for history & count
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    if (_currentToken == null) return;
    _isLoading = true;
    _safeNotifyListeners();
    try {
      final data = await _apiService.fetchNotifications(token: _currentToken!);
      _notifications = data['notifications'] ?? [];
      _unreadCount = data['unreadCount'] ?? 0;
    } catch (e) {
      debugPrint('Error loading Notification Studio notifications: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }


  Future<void> markAllNotificationsRead() async {
    if (_currentToken == null) return;
    try {
      await _apiService.markAllAsRead(token: _currentToken!);
      _unreadCount = 0; // Optimistic update
      _notifications = _notifications.map((n) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          body: n.body,
          isRead: true,
          data: n.data,
          createdAt: n.createdAt,
        );
      }).toList();
      _safeNotifyListeners();

    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> markSingleNotificationRead(String id) async {
    if (_currentToken == null) return;
    try {
      await _apiService.markSingleAsRead(id, token: _currentToken!);
      int index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          body: _notifications[index].body,
          isRead: true,
          data: _notifications[index].data,
          createdAt: _notifications[index].createdAt,
        );
        _unreadCount = (_unreadCount - 1).clamp(0, 99999);
        _safeNotifyListeners();
      }

    } catch (e) {
      debugPrint('Error marking single as read: $e');
    }
  }

  void disconnect() {
    _socketService.disconnect();
    _isInitialized = false;
    _currentToken = null;
    _unreadCount = 0;
    _notifications = [];
    _safeNotifyListeners();
    debugPrint('NotificationStudioController disconnected.');
  }

  void _safeNotifyListeners() {
    Future.microtask(() {
      notifyListeners();
    });
  }
}

