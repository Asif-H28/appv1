import 'package:appv1/core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:appv1/features/main_app/pages/notification_router.dart';
import 'package:appv1/features/main_app/pages/deactivated_account_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appv1/core/services/token_expiration_handler.dart';

class ApiService {
  static const String _baseUrl = '${ApiConstants.apiBaseUrl}';

  static void checkResponse(http.Response response) {
    // Check for deactivated account FIRST (preserve existing behavior)
    if (response.statusCode == 403) {
      try {
        final body = jsonDecode(response.body);
        final errorMsg = body['error'] ?? body['message'] ?? '';
        if (errorMsg == 'Organization Deactivated' ||
            errorMsg.toString().contains('Deactivated')) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DeactivatedAccountScreen()),
            (route) => false,
          );
          return; // Exit early - don't check for token expiration
        }
      } catch (_) {}
    }

    // Check for token expiration
    if (TokenExpirationHandler.detectTokenExpiration(response.body)) {
      final endpoint = response.request?.url.toString() ?? 'unknown';
      TokenExpirationHandler.handleTokenExpiration(endpoint);
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

  // Fetch Organization Settings
  static Future<Map<String, dynamic>> getOrgSettings() async {
    try {
      final response = await ApiService.get('$_baseUrl/org/settings');
      checkResponse(response);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to load settings'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update Organization Settings
  static Future<Map<String, dynamic>> updateOrgSettings(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.put(
        '$_baseUrl/org/settings',
        body: jsonEncode(data),
      );
      checkResponse(response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Settings updated successfully'};
      } else {
        return {'success': false, 'message': 'Failed to update settings: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
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
        return {'success': true, 'classrooms': data['classrooms'] ?? []};
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
        return {'success': true, 'data': jsonDecode(response.body)};
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
  static Future<Map<String, dynamic>> fetchAssessmentsByClass(
    String classId,
  ) async {
    try {
      final url = '$_baseUrl/comprehensive-assessment/class/$classId';
      print('Fetching assessments from: $url');

      final response = await ApiService.get(url);

      print('Assessments Response Status: ${response.statusCode}');
      print('Assessments Response Body: ${response.body}');
      checkResponse(response);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
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
  static Future<Map<String, dynamic>> fetchAssessmentResults(
    String assessmentId,
  ) async {
    try {
      final url = '$_baseUrl/comprehensive-result/assessment/$assessmentId';
      print('Fetching assessment results from: $url');

      final response = await ApiService.get(url);

      print('Assessment Results Response Status: ${response.statusCode}');
      print('Assessment Results Response Body: ${response.body}');
      checkResponse(response);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message':
              'Failed to load assessment results: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fetch Pending Teacher Join Requests
  static Future<Map<String, dynamic>> fetchTeacherJoinRequests(
    String orgId,
  ) async {
    try {
      final url = '$_baseUrl/teacher/join-requests/$orgId';
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'requests': data['requests'] ?? []};
      } else {
        return {'success': false, 'message': 'Failed to load requests'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Approve Teacher Join Request
  static Future<Map<String, dynamic>> approveTeacherRequest(
    String requestId,
  ) async {
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
  static Future<Map<String, dynamic>> rejectTeacherRequest(
    String requestId,
  ) async {
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

  // Fetch teachers by orgId
  static Future<Map<String, dynamic>> fetchTeachersByOrg(String orgId) async {
    try {
      final url = '/teacher/org/$orgId';
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'teachers': data['teachers'] ?? []};
      }
      return {'success': false, 'message': 'Failed to load teachers'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Remove teacher from organization
  static Future<Map<String, dynamic>> removeTeacher(String teacherId) async {
    try {
      final url = '/teacher/$teacherId';
      final response = await ApiService.delete(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Teacher removed successfully',
        };
      }
      return {'success': false, 'message': 'Failed to remove teacher'};
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

  // Fetch user status (online/offline)
  static Future<Map<String, dynamic>> getUserStatus(String userId) async {
    try {
      final response = await ApiService.get('/chat/user-status/$userId');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to load status'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Create or get existing conversation
  static Future<Map<String, dynamic>> createConversation(
    String senderId,
    String recipientId,
  ) async {
    try {
      final response = await ApiService.post(
        '/chat/conversations',
        body: jsonEncode({
          'participants': [senderId, recipientId],
          'recipientId': recipientId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'conversation': jsonDecode(response.body)};
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

  // Appoint Transport Coordinator
  static Future<Map<String, dynamic>> appointTransportCoordinator({
    required String teacherId,
    required String orgId,
  }) async {
    try {
      final response = await ApiService.post(
        '/transport/coordinators',
        body: jsonEncode({'teacherId': teacherId, 'orgId': orgId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message':
              jsonDecode(response.body)['message'] ??
              'Coordinator appointed successfully',
        };
      }
      return {
        'success': false,
        'message':
            jsonDecode(response.body)['message'] ??
            'Failed to appoint coordinator',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Remove Transport Coordinator
  static Future<Map<String, dynamic>> removeTransportCoordinator({
    required String teacherId,
    required String orgId,
  }) async {
    try {
      final response = await ApiService.delete(
        '/transport/coordinators/$orgId/$teacherId',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message':
              jsonDecode(response.body)['message'] ??
              'Coordinator removed successfully',
        };
      }
      return {
        'success': false,
        'message':
            jsonDecode(response.body)['message'] ??
            'Failed to remove coordinator',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fetch all vehicles in organization
  static Future<Map<String, dynamic>> fetchVehicles(String orgId) async {
    try {
      final url = '/transport/vehicles/$orgId';
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'vehicles': data['vehicles'] ?? []};
      }
      return {'success': false, 'message': 'Failed to load vehicles'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Create a new vehicle
  static Future<Map<String, dynamic>> createVehicle({
    required String orgId,
    required String coordinatorId,
    required String vehicleName,
    required String vehicleNumber,
    required String driverName,
    required String driverPhoneNumber,
  }) async {
    try {
      final response = await ApiService.post(
        '/transport/vehicles',
        body: jsonEncode({
          'orgId': orgId,
          'coordinatorId': coordinatorId,
          'vehicleName': vehicleName,
          'vehicleNumber': vehicleNumber,
          'driverName': driverName,
          'driverPhoneNumber': driverPhoneNumber,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message':
              jsonDecode(response.body)['message'] ??
              'Vehicle created successfully',
        };
      }
      return {
        'success': false,
        'message':
            jsonDecode(response.body)['message'] ?? 'Failed to create vehicle',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateVehicle({
    required String vehicleId,
    required String vehicleName,
    required String vehicleNumber,
    required String driverName,
    required String driverPhoneNumber,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.apiBaseUrl}/transport/vehicles/$vehicleId'),
        headers: await getHeaders(),
        body: jsonEncode({
          'vehicleName': vehicleName,
          'vehicleNumber': vehicleNumber,
          'driverName': driverName,
          'driverPhoneNumber': driverPhoneNumber,
        }),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              jsonDecode(response.body)['message'] ??
              'Vehicle updated successfully',
        };
      }
      return {
        'success': false,
        'message':
            jsonDecode(response.body)['message'] ?? 'Failed to update vehicle',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteVehicle(String vehicleId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.apiBaseUrl}/transport/vehicles/$vehicleId'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              jsonDecode(response.body)['message'] ??
              'Vehicle deleted successfully',
        };
      }
      return {
        'success': false,
        'message':
            jsonDecode(response.body)['message'] ?? 'Failed to delete vehicle',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> setupVehiclePin({
    required String orgId,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/transport/setup-pin'),
        headers: await getHeaders(),
        body: jsonEncode({'orgId': orgId, 'pin': pin}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message':
              jsonDecode(response.body)['message'] ?? 'PIN setup successful',
        };
      }
      return {
        'success': false,
        'message':
            jsonDecode(response.body)['message'] ?? 'Failed to setup PIN',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> driverLogin({
    required String phoneNumber,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/transport/driver/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber, 'pin': pin}),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'vehicle': body['vehicle'],
          'message': body['message'] ?? 'Login successful',
        };
      }
      return {'success': false, 'message': body['message'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateVehicleLocation({
    required String vehicleId,
    required String orgId,
    required double latitude,
    required double longitude,
    required String vehicleName,
    required String driverName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/transport/location/$vehicleId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orgId': orgId,
          'latitude': latitude,
          'longitude': longitude,
          'vehicleName': vehicleName,
          'driverName': driverName,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Location updated'};
      }
      return {'success': false, 'message': 'Failed to update location'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> stopVehicleRoute(String vehicleId) async {
    try {
      final response = await http.patch(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/transport/location/$vehicleId/stop',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Route stopped'};
      }
      return {'success': false, 'message': 'Failed to stop route'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getOrgVehiclesLocation(
    String orgId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/transport/location/org/$orgId'),
        headers: await getHeaders(),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'vehicles': body['vehicles']};
      }
      return {
        'success': false,
        'message': body['message'] ?? 'Failed to fetch vehicles',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getOrgVehicles(String orgId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/transport/vehicles/$orgId'),
        headers: await getHeaders(),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'vehicles': body['vehicles']};
      }
      return {
        'success': false,
        'message': body['message'] ?? 'Failed to fetch vehicles',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getVehicleLocation(
    String vehicleId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/transport/location/$vehicleId'),
        headers: await getHeaders(),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'vehicle': body['vehicle']};
      }
      return {
        'success': false,
        'message': body['error'] ?? body['message'] ?? 'Failed to fetch vehicle location',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── Dio Instance with Interceptor ─────────────────────
  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: ApiConstants.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final headers = await getHeaders();
              options.headers.addAll(headers);
              return handler.next(options);
            },
            onResponse: (response, handler) {
              // Check for token expiration in successful responses
              final responseBody = response.data?.toString() ?? '';
              if (TokenExpirationHandler.detectTokenExpiration(responseBody)) {
                final endpoint = response.requestOptions.uri.toString();
                TokenExpirationHandler.handleTokenExpiration(endpoint);
              }
              return handler.next(response);
            },
            onError: (DioError e, handler) {
              // Check for deactivated account FIRST (preserve existing behavior)
              if (e.response?.statusCode == 403) {
                final data = e.response?.data;
                final errorMsg = (data is Map)
                    ? (data['error'] ?? data['message'] ?? '')
                    : '';
                if (errorMsg == 'Organization Deactivated' ||
                    errorMsg.toString().contains('Deactivated')) {
                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const DeactivatedAccountScreen(),
                    ),
                    (route) => false,
                  );
                  return handler.next(
                    e,
                  ); // Exit early - don't check for token expiration
                }
              }

              // Check for token expiration after deactivation check
              final responseBody = e.response?.data?.toString() ?? '';
              if (TokenExpirationHandler.detectTokenExpiration(responseBody)) {
                final endpoint = e.requestOptions.uri.toString();
                TokenExpirationHandler.handleTokenExpiration(endpoint);
              }

              return handler.next(e);
            },
          ),
        );

  static Dio get dio => _dio;

  // ─── Generic Authenticated Methods (http) ─────────────────────

  static Future<http.Response> get(
    dynamic url, {
    Map<String, String>? headers,
  }) async {
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

  static Future<http.Response> post(
    dynamic url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
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

  static Future<http.Response> put(
    dynamic url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
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

  static Future<http.Response> delete(
    dynamic url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
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

  static Future<http.Response> patch(
    dynamic url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final combinedHeaders = await getHeaders();
    if (headers != null) combinedHeaders.addAll(headers);

    Uri uri;
    if (url is String) {
      final fullUrl = url.startsWith('http') ? url : '$_baseUrl$url';
      uri = Uri.parse(fullUrl);
    } else {
      uri = url as Uri;
    }

    final res = await http.patch(uri, headers: combinedHeaders, body: body);
    checkResponse(res);
    return res;
  }
}
