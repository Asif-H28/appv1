import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = '${ApiConstants.apiBaseUrl}';

  // Create Organization (matches your curl)
  static Future<Map<String, dynamic>> createOrganization({
    required String orgName,
    required String adminEmail,
    required String adminPassword,
    required String licenseKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/org/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orgName': orgName,
          'adminEmail': adminEmail,
          'adminPassword': adminPassword,
          'licenseKey': licenseKey,
        }),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

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
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Classrooms Response Status: ${response.statusCode}');
      print('Classrooms Response Body: ${response.body}');

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

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Attendance Response Status: ${response.statusCode}');
      print('Attendance Response Body: ${response.body}');

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

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Assessments Response Status: ${response.statusCode}');
      print('Assessments Response Body: ${response.body}');

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

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Assessment Results Response Status: ${response.statusCode}');
      print('Assessment Results Response Body: ${response.body}');

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
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
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
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
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
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Failed to reject request'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}


