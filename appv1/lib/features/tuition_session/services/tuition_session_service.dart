import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/features/tuition_session/models/tuition_session_models.dart';

class TuitionSessionService {
  // 1. Fetch teachers for student portal
  static Future<Map<String, dynamic>> fetchTeachers(String orgId) async {
    try {
      final response = await ApiService.get('/teacher/org/$orgId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final teachersList = (data['teachers'] as List?) ?? [];
        final teachers = teachersList.map((t) => TeacherDTO.fromJson(t)).toList();
        return {'success': true, 'teachers': teachers};
      }
      return {'success': false, 'message': 'Failed to load teachers'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 2. Generate QR from student portal
  static Future<Map<String, dynamic>> generateQr({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String teacherId,
    required String teacherName,
    required String orgId,
  }) async {
    try {
      final response = await ApiService.post(
        '/sessions/generate-qr',
        body: jsonEncode({
          'assignmentId': assignmentId,
          'studentId': studentId,
          'studentName': studentName,
          'teacherId': teacherId,
          'teacherName': teacherName,
          'orgId': orgId,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'qrToken': body['qrToken']};
      }
      return {'success': false, 'message': body['message'] ?? 'Failed to generate QR'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 3. Teacher scans QR and starts session
  static Future<Map<String, dynamic>> checkIn({
    required String qrToken,
    required double teacherLat,
    required double teacherLng,
  }) async {
    try {
      final response = await ApiService.post(
        '/sessions/checkin',
        body: jsonEncode({
          'qrToken': qrToken,
          'teacherLat': teacherLat,
          'teacherLng': teacherLng,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'session': SessionDetailDTO.fromJson(body['session'] ?? body['data'] ?? body)};
      }
      return {'success': false, 'message': body['message'] ?? 'Failed to check in'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 4. Teacher forced check-in without QR
  static Future<Map<String, dynamic>> forceCheckIn({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String orgId,
    required String reason,
    required double teacherLat,
    required double teacherLng,
  }) async {
    try {
      final response = await ApiService.post(
        '/sessions/force-checkin',
        body: jsonEncode({
          'assignmentId': assignmentId,
          'studentId': studentId,
          'studentName': studentName,
          'orgId': orgId,
          'reason': reason,
          'teacherLat': teacherLat,
          'teacherLng': teacherLng,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'session': SessionDetailDTO.fromJson(body['session'] ?? body['data'] ?? body)};
      }
      return {'success': false, 'message': body['message'] ?? 'Failed to force check in'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 5. Teacher updates session activity
  static Future<Map<String, dynamic>> updateActivity({
    required String sessionId,
    required String description,
    required bool homeworkProvided,
    required bool studentCompletedHomework,
    required bool testGiven,
    List<String>? homeworkProvidedFiles,
    List<String>? studentCompletedHomeworkFiles,
    List<String>? testGivenFiles,
    List<String>? additionalFiles,
  }) async {
    try {
      final formDataMap = <String, dynamic>{
        'description': description,
        'homeworkProvided': homeworkProvided.toString(),
        'studentCompletedHomework': studentCompletedHomework.toString(),
        'testGiven': testGiven.toString(),
      };

      final formData = FormData.fromMap(formDataMap);

      if (homeworkProvidedFiles != null) {
        for (var path in homeworkProvidedFiles) {
          formData.files.add(MapEntry(
            'homeworkProvidedFiles',
            await MultipartFile.fromFile(path),
          ));
        }
      }
      if (studentCompletedHomeworkFiles != null) {
        for (var path in studentCompletedHomeworkFiles) {
          formData.files.add(MapEntry(
            'studentCompletedHomeworkFiles',
            await MultipartFile.fromFile(path),
          ));
        }
      }
      if (testGivenFiles != null) {
        for (var path in testGivenFiles) {
          formData.files.add(MapEntry(
            'testGivenFiles',
            await MultipartFile.fromFile(path),
          ));
        }
      }
      if (additionalFiles != null) {
        for (var path in additionalFiles) {
          formData.files.add(MapEntry(
            'additionalFiles',
            await MultipartFile.fromFile(path),
          ));
        }
      }

      final response = await ApiService.dio.put(
        '/sessions/$sessionId/activity',
        data: formData,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Activity updated successfully'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed to update activity'};
    } catch (e) {
      if (e is DioError) {
        return {'success': false, 'message': e.response?.data?['message'] ?? e.message};
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 6. Teacher ends session
  static Future<Map<String, dynamic>> checkoutSession({
    required String sessionId,
    required double teacherLat,
    required double teacherLng,
  }) async {
    try {
      final response = await ApiService.patch(
        '/sessions/$sessionId/checkout',
        body: jsonEncode({
          'teacherLat': teacherLat,
          'teacherLng': teacherLng,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'session': SessionDetailDTO.fromJson(body['session'] ?? body['data'] ?? body)};
      }
      return {'success': false, 'message': body['message'] ?? 'Failed to checkout'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 7. Admin portal fetches all sessions
  static Future<Map<String, dynamic>> fetchOrgSessions(String orgId, {String? status, String? date}) async {
    try {
      String query = '';
      if (status != null || date != null) {
        query = '?';
        if (status != null && status.isNotEmpty) query += 'status=$status&';
        if (date != null && date.isNotEmpty) query += 'date=$date';
        if (query.endsWith('&')) query = query.substring(0, query.length - 1);
      }
      
      final response = await ApiService.get('/sessions/org/$orgId$query');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = (body['sessions'] ?? body['data'] as List?) ?? [];
        return {'success': true, 'sessions': list.map((s) => SessionSummaryDTO.fromJson(s)).toList()};
      }
      return {'success': false, 'message': 'Failed to fetch sessions'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 8. Admin portal fetches a single session
  static Future<Map<String, dynamic>> fetchSessionDetail(String sessionId) async {
    try {
      final response = await ApiService.get('/sessions/$sessionId');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {'success': true, 'session': SessionDetailDTO.fromJson(body['session'] ?? body['data'] ?? body)};
      }
      return {'success': false, 'message': 'Failed to fetch session detail'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  // 9. Admin portal fetches session activity
  static Future<Map<String, dynamic>> fetchSessionActivity(String sessionId) async {
    try {
      final response = await ApiService.get('/session/$sessionId/activity');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {'success': true, 'activity': body['activity'] ?? body['data'] ?? body};
      }
      return {'success': false, 'message': 'Failed to fetch session activity'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
