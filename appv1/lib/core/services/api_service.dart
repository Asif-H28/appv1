import 'package:appv1/core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:appv1/features/main_app/pages/notification_router.dart';
import 'package:appv1/features/main_app/pages/deactivated_account_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = '${ApiConstants.apiBaseUrl}';

  static void checkResponse(http.Response response) {
    if (response.statusCode == 403) {
      try {
        final body = jsonDecode(response.body);
        final errorMsg = body['error'] ?? body['message'] ?? '';
        if (errorMsg == 'Organization Deactivated' || errorMsg.toString().contains('Deactivated')) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DeactivatedAccountScreen()),
            (route) => false,
          );
        }
      } catch (_) {}
    }
  }

  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Create Organization (matches your curl)
  static Future<Map<String, dynamic>> createOrganization({
    required String orgName,
    required String adminEmail,
    required String adminPassword,
    required String licenseKey,
  }) async {
    try {
      final response = await ApiService.post(
        '$_baseUrl/org/create',
        body: jsonEncode({
          'orgName': orgName,
          'adminEmail': adminEmail,
          'adminPassword': adminPassword,
          'licenseKey': licenseKey,
        }),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');
      checkResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Organization created successfully!',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print('API Error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  // Fetch Classrooms by Org ID
  static Future<Map<String, dynamic>> fetchClassroomsByOrg(String orgId) async {
    try {
      final url = '$_baseUrl/classroom/list/$orgId';
      print('Fetching classrooms from: $url');
      
      final response = await ApiService.get(url);

      print('Classrooms Response Status: ${response.statusCode}');
      print('Classrooms Response Body: ${response.body}');
      checkResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'classrooms': data['classrooms'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load classrooms: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fetch Attendance by Class and Date
  static Future<Map<String, dynamic>> fetchAttendanceByClass(
    String classId,
    String date,
  ) async {
    try {
      final url = '$_baseUrl/attendance/class/$classId/date/$date';
      print('Fetching attendance from: $url');

      final response = await ApiService.get(url);

      print('Attendance Response Status: ${response.statusCode}');
      print('Attendance Response Body: ${response.body}');
      checkResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load attendance: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fetch Comprehensive Assessments by Class
  static Future<Map<String, dynamic>> fetchAssessmentsByClass(String classId) async {
    try {
      final url = '$_baseUrl/comprehensive-assessment/class/$classId';
      print('Fetching assessments from: $url');

      final response = await ApiService.get(url);

      print('Assessments Response Status: ${response.statusCode}');
      print('Assessments Response Body: ${response.body}');
      checkResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load assessments: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  // Fetch Comprehensive Assessment Results by Assessment ID
  static Future<Map<String, dynamic>> fetchAssessmentResults(String assessmentId) async {
    try {
      final url = '$_baseUrl/comprehensive-result/assessment/$assessmentId';
      print('Fetching assessment results from: $url');

      final response = await ApiService.get(url);

      print('Assessment Results Response Status: ${response.statusCode}');
      print('Assessment Results Response Body: ${response.body}');
      checkResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load assessment results: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fetch Pending Teacher Join Requests
  static Future<Map<String, dynamic>> fetchTeacherJoinRequests(String orgId) async {
    try {
      final url = '$_baseUrl/teacher/join-requests/$orgId';
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'requests': data['requests'] ?? [],
        };
      } else {
        return {'success': false, 'message': 'Failed to load requests'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Approve Teacher Join Request
  static Future<Map<String, dynamic>> approveTeacherRequest(String requestId) async {
    try {
      final url = '$_baseUrl/teacher/join-requests/$requestId/approve';
      final response = await ApiService.put(url);
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Failed to approve request'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Reject Teacher Join Request
  static Future<Map<String, dynamic>> rejectTeacherRequest(String requestId) async {
    try {
      final url = '$_baseUrl/teacher/join-requests/$requestId/reject';
      final response = await ApiService.put(url);
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Failed to reject request'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fetch all active teachers in organization
  static Future<Map<String, dynamic>> fetchTeachers(String orgId) async {
    try {
      final url = '$_baseUrl/teacher/list/$orgId';
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'teachers': data['teachers'] ?? data['data'] ?? [],
        };
      }
      return {'success': false, 'message': 'Failed to load teachers'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fetch all active students in organization
  static Future<Map<String, dynamic>> fetchStudents(String orgId) async {
    try {
      final url = '$_baseUrl/student/list/$orgId';
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'students': data['students'] ?? data['data'] ?? [],
        };
      }
      return {'success': false, 'message': 'Failed to load students'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Create or get existing conversation
  static Future<Map<String, dynamic>> createConversation(String senderId, String recipientId) async {
    try {
      final response = await ApiService.post(
        '/chat/conversations',
        body: jsonEncode({
          'participants': [senderId, recipientId],
          'recipientId': recipientId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'conversation': jsonDecode(response.body),
        };
      }
      return {'success': false, 'message': 'Failed to create conversation'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await ApiService.put('/chat/messages/read/$conversationId', body: '{}');
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // ─── Dio Instance with Interceptor ─────────────────────
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ))..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final headers = await getHeaders();
        options.headers.addAll(headers);
        return handler.next(options);
      },
      onError: (DioError e, handler) {
        if (e.response?.statusCode == 403) {
          final data = e.response?.data;
          final errorMsg = (data is Map) ? (data['error'] ?? data['message'] ?? '') : '';
          if (errorMsg == 'Organization Deactivated' || errorMsg.toString().contains('Deactivated')) {
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DeactivatedAccountScreen()),
              (route) => false,
            );
          }
        }
        return handler.next(e);
      },
    ));

  static Dio get dio => _dio;

  // ─── Generic Authenticated Methods (http) ─────────────────────

  static Future<http.Response> get(dynamic url, {Map<String, String>? headers}) async {
    final combinedHeaders = await getHeaders();
    if (headers != null) combinedHeaders.addAll(headers);
    
    Uri uri;
    if (url is String) {
      final fullUrl = url.startsWith('http') ? url : '$_baseUrl$url';
      uri = Uri.parse(fullUrl);
    } else {
      uri = url as Uri;
    }
    
    final res = await http.get(uri, headers: combinedHeaders);
    checkResponse(res);
    return res;
  }

  static Future<http.Response> post(dynamic url, {Map<String, String>? headers, Object? body}) async {
    final combinedHeaders = await getHeaders();
    if (headers != null) combinedHeaders.addAll(headers);
    
    Uri uri;
    if (url is String) {
      final fullUrl = url.startsWith('http') ? url : '$_baseUrl$url';
      uri = Uri.parse(fullUrl);
    } else {
      uri = url as Uri;
    }
    
    final res = await http.post(uri, headers: combinedHeaders, body: body);
    checkResponse(res);
    return res;
  }

  static Future<http.Response> put(dynamic url, {Map<String, String>? headers, Object? body}) async {
    final combinedHeaders = await getHeaders();
    if (headers != null) combinedHeaders.addAll(headers);
    
    Uri uri;
    if (url is String) {
      final fullUrl = url.startsWith('http') ? url : '$_baseUrl$url';
      uri = Uri.parse(fullUrl);
    } else {
      uri = url as Uri;
    }
    
    final res = await http.put(uri, headers: combinedHeaders, body: body);
    checkResponse(res);
    return res;
  }

  static Future<http.Response> delete(dynamic url, {Map<String, String>? headers, Object? body}) async {
    final combinedHeaders = await getHeaders();
    if (headers != null) combinedHeaders.addAll(headers);
    
    Uri uri;
    if (url is String) {
      final fullUrl = url.startsWith('http') ? url : '$_baseUrl$url';
      uri = Uri.parse(fullUrl);
    } else {
      uri = url as Uri;
    }
    
    final res = await http.delete(uri, headers: combinedHeaders, body: body);
    checkResponse(res);
    return res;
  }
}


