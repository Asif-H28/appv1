import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationApiService {
  // Fetch paginated notifications
  Future<Map<String, dynamic>> fetchNotifications({int page = 1, int limit = 20, String? token}) async {
    try {
      final response = await DioClient.instance.get(
        '/notification-studio',
        queryParameters: {'page': page, 'limit': limit},
        // If a token is provided explicitly, we can override/attach it, otherwise interceptor handles it
        options: token != null 
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      
      final List rawList = response.data['notifications'] ?? [];
      final list = rawList.map((e) => NotificationModel.fromJson(e)).toList();
      final unreadCount = response.data['unreadCount'] ?? 0;

      return {
        'notifications': list,
        'unreadCount': unreadCount,
      };
    } catch (e) {
      debugPrint('Error in fetchNotifications: $e');
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead({String? token}) async {
    try {
      await DioClient.instance.put(
        '/notification-studio/mark-all-read',
        options: token != null 
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
    } catch (e) {
      debugPrint('Error in markAllAsRead: $e');
      rethrow;
    }
  }

  // Mark a single notification as read
  Future<void> markSingleAsRead(String id, {String? token}) async {
    try {
      await DioClient.instance.put(
        '/notification-studio/$id/read',
        options: token != null 
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
    } catch (e) {
      debugPrint('Error in markSingleAsRead: $e');
      rethrow;
    }
  }
}
