import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:appv1/features/main_app/pages/notification_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// â”€â”€ Background handler (must be top-level) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM:BG] ${message.notification?.title}');
}

// â”€â”€ Local notifications plugin â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final FlutterLocalNotificationsPlugin localNotif =
    FlutterLocalNotificationsPlugin();

// âœ… ValueNotifier â€” increments when foreground message arrives
// StudentMainScreen listens to this and re-fetches badge count
final ValueNotifier<int> notifCountNotifier = ValueNotifier<int>(0);

// âœ… Admin-specific notifier â€” fires when a teacher-leave-request FCM arrives
// MainAppScreen listens to this and re-fetches admin leave badge count
final ValueNotifier<int> adminNotifCountNotifier = ValueNotifier<int>(0);

// â”€â”€ Android notification channel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const AndroidNotificationChannel notifChannel = AndroidNotificationChannel(
  'schoolsync_v4_channel',
  'SchoolSync Notifications',
  description: 'Class & personal notifications',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('schoolsync'),
);

class NotificationService {
  static const String _baseUrl = '${ApiConstants.baseUrl}';

  // â”€â”€ Init (call in main.dart) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> initFirebase() async {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // âœ… Create Android channel WITH sound BEFORE plugin init
    await localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(notifChannel);

    // âœ… Android 13+ â€” request POST_NOTIFICATIONS permission
    await localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: (details) {
        _routeFromPayload(details.payload);
      },
    );
  }

  // â”€â”€ Request permission â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
  }

  // â”€â”€ Save FCM token after login â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> saveTokenAfterLogin({
    required String userId,
    required String role,
  }) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcmToken', token);
      await prefs.setString('fcmUserId', userId);
      await prefs.setString('fcmRole', role);

      await _sendTokenToBackend(userId: userId, role: role, token: token);
    } catch (e) {
      debugPrint('[FCM] saveToken error: $e');
    }
  }

  static Future<void> _sendTokenToBackend({
    required String userId,
    required String role,
    required String token,
  }) async {
    final endpoint = role == 'student'
        ? '/api/notification/fcm/student'
        : '/api/notification/fcm/teacher';

    final body = role == 'student'
        ? {'studentId': userId, 'fcmToken': token}
        : {'teacherId': userId, 'fcmToken': token};

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      debugPrint('[FCM] Token saved: ${res.statusCode}');
    } catch (e) {
      debugPrint('[FCM] Token save error: $e');
    }
  }

  // â”€â”€ Save Admin FCM token after admin login â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> saveAdminTokenAfterLogin({
    required String orgId,
  }) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcmToken', token);
      await prefs.setString('fcmRole', 'admin');

      final res = await http.post(
        Uri.parse('$_baseUrl/api/notification/fcm/admin/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orgId': orgId, 'fcmToken': token}),
      );
      debugPrint('[FCM] Admin token saved: ${res.statusCode}');
    } catch (e) {
      debugPrint('[FCM] Admin token save error: $e');
    }
  }

  // â”€â”€ Clear Admin FCM token on admin logout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> clearAdminToken({
    required String orgId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/notification/fcm/admin/clear'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orgId': orgId}),
      );
      debugPrint('[FCM] Admin token cleared: ${res.statusCode}');
    } catch (e) {
      debugPrint('[FCM] Admin token clear error: $e');
    }
  }

  // â”€â”€ Listen for token refresh â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static void listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token refreshed');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('fcmUserId') ?? '';
      final role = prefs.getString('fcmRole') ?? '';
      if (userId.isNotEmpty && role.isNotEmpty) {
        await _sendTokenToBackend(userId: userId, role: role, token: newToken);
      }
    });
  }

  // â”€â”€ Foreground notification listener â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static void listenForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM:FG] title=${message.notification?.title}');
      final notif = message.notification;
      final android = message.notification?.android;
      if (notif == null) return;

      // âœ… Signal students (StudentMainScreen re-fetches badge)
      notifCountNotifier.value += 1;

      // âœ… Signal admin when it's a teacher-leave-request notification
      final route = message.data['route']?.toString() ?? '';
      if (route == 'teacher-leave-requests') {
        adminNotifCountNotifier.value += 1;
        debugPrint('[FCM:FG] Admin leave notifier incremented');
      }

      localNotif.show(
        notif.hashCode,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            notifChannel.id,
            notifChannel.name,
            channelDescription: notifChannel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('schoolsync'),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'schoolsync.aiff',
          ),
        ),
        payload: message.data['route'],
      );
    });
  }

  // â”€â”€ Background tap listener â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static void listenBackgroundTap(BuildContext context) {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] BG tap: ${message.data}');
      _navigateFromData(context, message.data);
    });
  }

  // â”€â”€ Terminated tap (app cold start) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> checkInitialMessage(BuildContext context) async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      debugPrint('[FCM] Terminated tap: ${message.data}');
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateFromData(context, message.data);
    }
  }

  // â”€â”€ Navigation handler â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static void _navigateFromData(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final route = data['route']?.toString();
    _routeFromPayload(route, context: context);
  }

  static void _routeFromPayload(String? route, {BuildContext? context}) {
    if (route == null) return;
    NotificationRouter.handleRoute(route);
  }

  // â”€â”€ Subscribe / Unsubscribe â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('[FCM] Subscribed: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('[FCM] Unsubscribed: $topic');
  }

  // â”€â”€ Manual send methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<bool> sendToClass({
    required String classId,
    required String orgId,
    required String title,
    required String body,
    required String sentBy,
    required String sentByName,
    String type = 'general',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/notification/send/class'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'classId': classId,
          'orgId': orgId,
          'title': title,
          'body': body,
          'type': type,
          'sentBy': sentBy,
          'sentByName': sentByName,
        }),
      );
      debugPrint('[FCM] sendToClass: ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[FCM] sendToClass error: $e');
      return false;
    }
  }

  static Future<bool> sendToStudent({
    required String studentId,
    required String classId,
    required String orgId,
    required String title,
    required String body,
    required String sentBy,
    required String sentByName,
    String type = 'general',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/notification/send/student'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentId': studentId,
          'classId': classId,
          'orgId': orgId,
          'title': title,
          'body': body,
          'type': type,
          'sentBy': sentBy,
          'sentByName': sentByName,
        }),
      );
      debugPrint('[FCM] sendToStudent: ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[FCM] sendToStudent error: $e');
      return false;
    }
  }

  static Future<bool> sendToOrg({
    required String orgId,
    required String title,
    required String body,
    required String sentBy,
    required String sentByName,
    String targetRole = 'student',
    String type = 'announcement',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/notification/send/org'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orgId': orgId,
          'targetRole': targetRole,
          'title': title,
          'body': body,
          'type': type,
          'sentBy': sentBy,
          'sentByName': sentByName,
        }),
      );
      debugPrint('[FCM] sendToOrg: ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[FCM] sendToOrg error: $e');
      return false;
    }
  }

  // â”€â”€ Notification history â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<List<Map<String, dynamic>>> getClassHistory(
    String classId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/notification/class/$classId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['notifications'] ?? []) as List;
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getOrgHistory(String orgId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/notification/org/$orgId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['notifications'] ?? []) as List;
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // â”€â”€ Full init (call once after login) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> initListeners(BuildContext context) async {
    listenForeground();
    listenBackgroundTap(context);
    listenTokenRefresh();
    await checkInitialMessage(context);
  }

  // â”€â”€ Teacher leave request notifications (admin) â”€â”€â”€
  static Future<List<Map<String, dynamic>>> getTeacherLeaveNotifications(
    String orgId,
  ) async {
    final url = '$_baseUrl/api/notification/org/$orgId/teacher-leave-requests';
    debugPrint('â”€â”€ [LeaveNotif:API] GET $url');
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      debugPrint('â”€â”€ [LeaveNotif:API] Status: ${res.statusCode}');
      debugPrint('â”€â”€ [LeaveNotif:API] Body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        debugPrint('â”€â”€ [LeaveNotif:API] Top-level keys: ${data.keys.toList()}');

        final rawList = data['notifications'];
        debugPrint('â”€â”€ [LeaveNotif:API] notifications value: $rawList');
        debugPrint('â”€â”€ [LeaveNotif:API] notifications type: ${rawList.runtimeType}');

        if (rawList == null) {
          debugPrint('â”€â”€ [LeaveNotif:API] âŒ "notifications" key is null');
          return [];
        }

        final list = rawList as List;
        debugPrint('â”€â”€ [LeaveNotif:API] âœ… List length: ${list.length}');
        for (int i = 0; i < list.length; i++) {
          debugPrint('â”€â”€ [LeaveNotif:API] item[$i] type: ${list[i].runtimeType}');
          debugPrint('â”€â”€ [LeaveNotif:API] item[$i]: ${list[i]}');
        }
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      debugPrint('â”€â”€ [LeaveNotif:API] âŒ Non-200 response');
      return [];
    } catch (e, st) {
      debugPrint('â”€â”€ [LeaveNotif:API] âŒ Exception: $e');
      debugPrint('â”€â”€ [LeaveNotif:API] Stack: $st');
      return [];
    }
  }

  /// Mark a single notification as read by this orgId (acts as userId).
  static Future<void> markLeaveNotificationRead({
    required String notificationId,
    required String orgId,
  }) async {
    try {
      await http.put(
        Uri.parse('$_baseUrl/api/notification/$notificationId/read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': orgId}),
      );
    } catch (_) {}
  }

  /// Bulk mark ALL teacher leave notifications for an org as read (single call).
  static Future<void> markAllLeaveNotificationsRead({
    required String orgId,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/api/notification/org/teacher-leave-requests/mark-all-read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orgId': orgId}),
      );
      debugPrint('[LeaveNotif] markAllRead: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[LeaveNotif] markAllRead error: $e');
    }
  }
}

