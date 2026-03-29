import 'dart:convert';
import 'package:appv1/features/main_app/pages/notification_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── Background handler (must be top-level) ─────────────
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM:BG] ${message.notification?.title}');
}

// ── Local notifications plugin ─────────────────────────
final FlutterLocalNotificationsPlugin localNotif =
    FlutterLocalNotificationsPlugin();

// ✅ ValueNotifier — increments when foreground message arrives
// StudentMainScreen listens to this and re-fetches badge count
final ValueNotifier<int> notifCountNotifier = ValueNotifier<int>(0);

// ── Android notification channel ───────────────────────
const AndroidNotificationChannel notifChannel = AndroidNotificationChannel(
  'schoolsync_v4_channel',
  'SchoolSync Notifications',
  description: 'Class & personal notifications',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('schoolsync'),
);

class NotificationService {
  static const String _baseUrl = 'https://appv1backend.onrender.com';

  // ── Init (call in main.dart) ───────────────────────
  static Future<void> initFirebase() async {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // ✅ Create Android channel WITH sound BEFORE plugin init
    await localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(notifChannel);

    // ✅ Android 13+ — request POST_NOTIFICATIONS permission
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

  // ── Request permission ─────────────────────────────
  static Future<void> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
  }

  // ── Save FCM token after login ─────────────────────
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

  // ── Listen for token refresh ───────────────────────
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

  // ── Foreground notification listener ──────────────
  static void listenForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM:FG] title=${message.notification?.title}');
      final notif = message.notification;
      final android = message.notification?.android;
      if (notif == null) return;

      // ✅ Signal all listeners (StudentMainScreen re-fetches badge)
      notifCountNotifier.value += 1;

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

  // ── Background tap listener ────────────────────────
  static void listenBackgroundTap(BuildContext context) {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] BG tap: ${message.data}');
      _navigateFromData(context, message.data);
    });
  }

  // ── Terminated tap (app cold start) ───────────────
  static Future<void> checkInitialMessage(BuildContext context) async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      debugPrint('[FCM] Terminated tap: ${message.data}');
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateFromData(context, message.data);
    }
  }

  // ── Navigation handler ─────────────────────────────
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

  // ── Subscribe / Unsubscribe ────────────────────────
  static Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('[FCM] Subscribed: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('[FCM] Unsubscribed: $topic');
  }

  // ── Manual send methods ────────────────────────────
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

  // ── Notification history ───────────────────────────
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

  // ── Full init (call once after login) ─────────────
  static Future<void> initListeners(BuildContext context) async {
    listenForeground();
    listenBackgroundTap(context);
    listenTokenRefresh();
    await checkInitialMessage(context);
  }
}
