import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:appv1/features/main_app/pages/notification_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:appv1/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/chat_socket_service.dart';

// ── Background handler (must be top-level) ─────────────
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM:BG] ${message.notification?.title}');
}

// ── Local notifications plugin ──────────────────────────
final FlutterLocalNotificationsPlugin localNotif =
    FlutterLocalNotificationsPlugin();

// ✅ ValueNotifier — increments when foreground message arrives
// StudentMainScreen listens to this and re-fetches badge count
final ValueNotifier<int> notifCountNotifier = ValueNotifier<int>(0);

// ✅ Admin-specific notifier — fires when a teacher-leave-request FCM arrives
// MainAppScreen listens to this and re-fetches admin leave badge count
final ValueNotifier<int> adminNotifCountNotifier = ValueNotifier<int>(0);

// ✅ Teacher-specific notifier — fires for teacher push notifications
final ValueNotifier<int> teacherNotifCountNotifier = ValueNotifier<int>(0);

// ── Android notification channel ────────────────────────
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

  // ⚠️ Set your Firebase Web Push VAPID Key (Web Push certificate) here.
  // This is required for Web and iOS Safari PWA Push notifications.
  static const String? _vapidKey =
      "BKxSUvduULtJygkqISo88m42X1Pd4gKpTeq7ZklmvoLBmk41oPgu9NIJeWPWkUiK1ADoYVxN47MiMCeS7J82774"; // Example: "BJ1..."

  // ── Init (call in main.dart) ─────────────────────────
  static Future<void> initFirebase() async {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return;
    }

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
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!);
            NotificationRouter.handleData(data);
          } catch (_) {
            NotificationRouter.handleRoute(details.payload!);
          }
        }
      },
    );
  }

  // ── Request permission ───────────────────────────────
  static Future<bool> requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('[FCM] Request permission error: $e');
      return false;
    }
  }

  // ── Save FCM token after login ──────────────────────
  static Future<void> saveTokenAfterLogin({
    required String userId,
    required String role,
  }) async {
    try {
      final key = _vapidKey;
      if (kIsWeb && (key == null || key.isEmpty)) {
        debugPrint(
          '⚠️ [FCM WARNING] _vapidKey is not set. iOS Safari / Web push notifications require a public VAPID key configured in the Firebase Console (Project Settings > Cloud Messaging > Web Push certificates). Please set it in notification_service.dart',
        );
      }
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: _vapidKey,
      );
      if (token == null) {
        debugPrint('[FCM] Token is null');
        return;
      }

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
        headers: await ApiService.getHeaders(),
        body: jsonEncode(body),
      );
      debugPrint('[FCM] Token saved: ${res.statusCode}');
    } catch (e) {
      debugPrint('[FCM] Token save error: $e');
    }
  }

  // ── Save Admin FCM token after admin login ──────────
  static Future<void> saveAdminTokenAfterLogin({required String orgId}) async {
    try {
      final key = _vapidKey;
      if (kIsWeb && (key == null || key.isEmpty)) {
        debugPrint(
          '⚠️ [FCM WARNING] _vapidKey is not set. iOS Safari / Web push notifications require a public VAPID key configured in the Firebase Console (Project Settings > Cloud Messaging > Web Push certificates). Please set it in notification_service.dart',
        );
      }
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: _vapidKey,
      );
      if (token == null) {
        debugPrint('[FCM] Admin token is null');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcmToken', token);
      await prefs.setString('fcmRole', 'admin');

      final res = await http.post(
        Uri.parse('$_baseUrl/api/notification/fcm/admin/save'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({'orgId': orgId, 'fcmToken': token}),
      );
      debugPrint('[FCM] Admin token saved: ${res.statusCode}');
    } catch (e) {
      debugPrint('[FCM] Admin token save error: $e');
    }
  }

  // ── Clear Admin FCM token on admin logout ───────────
  static Future<void> clearAdminToken({required String orgId}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/notification/fcm/admin/clear'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({'orgId': orgId}),
      );
      debugPrint('[FCM] Admin token cleared: ${res.statusCode}');
    } catch (e) {
      debugPrint('[FCM] Admin token clear error: $e');
    }
  }

  // ── Listen for token refresh ────────────────────────
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

  // ── Foreground notification listener ───────────────
  static void listenForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM:FG] title=${message.notification?.title}');
      final notif = message.notification;
      final android = message.notification?.android;
      if (notif == null) return;

      // ✅ Signal students (StudentMainScreen re-fetches badge)
      notifCountNotifier.value += 1;

      // ✅ Signal admin when it's a teacher-leave-request notification
      final route = message.data['route']?.toString() ?? '';
      if (route == 'teacher-leave-requests') {
        adminNotifCountNotifier.value += 1;
        debugPrint('[FCM:FG] Admin leave notifier incremented');
      }

      // ✅ Signal teachers
      teacherNotifCountNotifier.value += 1;

      // ✅ Check for chat notification and trigger refresh
      final type = message.data['type']?.toString();
      final isChat =
          message.data['chatnotification'] == 'true' || type == 'chat';
      if (isChat) {
        ChatSocketService().triggerUnreadRefresh();
      }

      if (!kIsWeb) {
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
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  // ── Background tap listener ─────────────────────────
  static void listenBackgroundTap(BuildContext context) {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] BG tap: ${message.data}');
      _navigateFromData(context, message.data);
    });
  }

  // ── Terminated tap (app cold start) ──────────────────
  static Future<void> checkInitialMessage(BuildContext context) async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      debugPrint('[FCM] Terminated tap: ${message.data}');
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateFromData(context, message.data);
    }
  }

  // ── Navigation handler ──────────────────────────────
  static void _navigateFromData(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    NotificationRouter.handleData(data);
  }

  static void _routeFromPayload(String? route, {BuildContext? context}) {
    if (route == null) return;
    NotificationRouter.handleRoute(route);
  }

  // ── Subscribe / Unsubscribe ─────────────────────────
  static Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('[FCM] Subscribed: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('[FCM] Unsubscribed: $topic');
  }

  // ── Manual send methods ─────────────────────────────
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
        headers: await ApiService.getHeaders(),
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
        headers: await ApiService.getHeaders(),
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
        headers: await ApiService.getHeaders(),
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

  // ── Notification history ─────────────────────────────
  static Future<List<Map<String, dynamic>>> getClassHistory(
    String classId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/notification/class/$classId'),
        headers: await ApiService.getHeaders(),
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
        headers: await ApiService.getHeaders(),
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

  // ── Full init (call once after login) ──────────────
  static Future<void> initListeners(BuildContext context) async {
    listenForeground();
    listenBackgroundTap(context);
    listenTokenRefresh();
    await checkInitialMessage(context);
  }

  // ── Teacher leave request notifications (admin) ───
  static Future<List<Map<String, dynamic>>> getTeacherLeaveNotifications(
    String orgId,
  ) async {
    final url = '$_baseUrl/api/notification/org/$orgId/teacher-leave-requests';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: await ApiService.getHeaders(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rawList = data['notifications'];
        if (rawList == null) return [];
        final list = rawList as List;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Mark a single notification as read by this orgId (acts as userId).
  static Future<void> markLeaveNotificationRead({
    required String notificationId,
    required String orgId,
  }) async {
    try {
      await ApiService.put(
        '$_baseUrl/api/notification/$notificationId/read',
        body: jsonEncode({'userId': orgId}),
      );
    } catch (_) {}
  }

  /// Bulk mark ALL teacher leave notifications for an org as read (single call).
  static Future<void> markAllLeaveNotificationsRead({
    required String orgId,
  }) async {
    try {
      final res = await ApiService.put(
        '$_baseUrl/api/notification/org/teacher-leave-requests/mark-all-read',
        body: jsonEncode({'orgId': orgId}),
      );
      debugPrint('[LeaveNotif] markAllRead: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[LeaveNotif] markAllRead error: $e');
    }
  }

  /// Bulk mark ALL student leave requests for a teacher as read.
  static Future<void> markAllStudentLeavesRead({
    required String teacherId,
    required String token,
  }) async {
    try {
      final res = await http.put(
        Uri.parse(
          '$_baseUrl/api/notification/teacher/student-leave-requests/mark-all-read',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'teacherId': teacherId}),
      );
      debugPrint('[StudentNotif] markAllRead: ${res.statusCode}');
    } catch (e) {
      debugPrint('[StudentNotif] markAllRead error: $e');
    }
  }

  /// Bulk mark ALL admin leave reviews for a teacher as read.
  static Future<void> markAllAdminReviewsRead({
    required String teacherId,
    required String token,
  }) async {
    try {
      final res = await ApiService.put(
        '$_baseUrl/api/notification/teacher/admin-leave-reviews/mark-all-read',
        body: jsonEncode({'teacherId': teacherId}),
      );
      debugPrint('[AdminReviewNotif] markAllRead: ${res.statusCode}');
    } catch (e) {
      debugPrint('[AdminReviewNotif] markAllRead error: $e');
    }
  }

  /// Mark a single notification as read by this teacherId.
  static Future<void> markAsRead({
    required String notificationId,
    required String teacherId,
    required String token,
  }) async {
    try {
      await ApiService.put(
        '$_baseUrl/api/notification/$notificationId/read',
        body: jsonEncode({'userId': teacherId}),
      );
    } catch (_) {}
  }

  /// Fetches total unread notifications for a teacher (Admin Reviews + Student Requests)
  static Future<int> getTeacherNotificationCount({
    required String teacherId,
    required String token,
  }) async {
    int totalUnread = 0;
    try {
      // 1. Fetch Admin Leave Reviews
      final resOrg = await ApiService.get(
        '$_baseUrl/api/notification/teacher/$teacherId/admin-leave-reviews',
      );
      if (resOrg.statusCode == 200) {
        final body = jsonDecode(resOrg.body) as Map;
        final list = (body['notifications'] ?? []) as List;
        totalUnread += list.where((n) {
          final readBy = (n['readBy'] as List? ?? []);
          return !readBy.any((r) => r.toString() == teacherId);
        }).length;
      }

      // 2. Fetch Student Leave Requests
      final resStudent = await ApiService.get(
        '$_baseUrl/api/notification/teacher/$teacherId/student-leave-requests',
      );
      if (resStudent.statusCode == 200) {
        final body = jsonDecode(resStudent.body) as Map;
        final list = (body['notifications'] ?? []) as List;
        totalUnread += list.where((n) {
          final readBy = (n['readBy'] as List? ?? []);
          return !readBy.any((r) => r.toString() == teacherId);
        }).length;
      }
    } catch (_) {}
    return totalUnread;
  }

  // ── Check if notifications are enabled ────────────────
  static Future<bool> isNotificationEnabled() async {
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }
}
