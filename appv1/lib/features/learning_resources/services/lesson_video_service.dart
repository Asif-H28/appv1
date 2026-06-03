import 'dart:convert';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';

class LessonVideoService {
  static const String _baseUrl = ApiConstants.apiBaseUrl;

  /// Fetch videos for a class, optionally filtered by type, subject, and lesson
  static Future<Map<String, dynamic>> fetchVideos({
    required String orgId,
    required String classId,
    String? videoType,
    String? subjectId,
    String? lessonId,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'classId': classId,
      };
      if (videoType != null && videoType.isNotEmpty) {
        queryParams['videoType'] = videoType;
      }
      if (subjectId != null && subjectId.isNotEmpty) {
        queryParams['subjectId'] = subjectId;
      }
      if (lessonId != null && lessonId.isNotEmpty) {
        queryParams['lessonId'] = lessonId;
      }

      final uri = Uri.parse('$_baseUrl/lesson-video/org/$orgId').replace(queryParameters: queryParams);
      
      final response = await ApiService.get(uri.toString());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['videos'] ?? data['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': 'Failed to load videos: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Add a new video resource
  static Future<Map<String, dynamic>> addVideo({
    required String url,
    required String videoType,
    required String classId,
    String? subjectId,
    String? lessonId,
    required String teacherId,
    required String teacherName,
    required String orgId,
    required String title,
  }) async {
    try {
      final body = {
        'url': url,
        'videoType': videoType,
        'classId': classId,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'orgId': orgId,
        'title': title,
      };

      if (videoType == 'lesson') {
        body['subjectId'] = subjectId ?? '';
        body['lessonId'] = lessonId ?? '';
      }

      final response = await ApiService.post(
        '$_baseUrl/lesson-video/add',
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Video shared successfully'};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to add video'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
