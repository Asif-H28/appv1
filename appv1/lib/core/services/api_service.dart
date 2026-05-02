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
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/org/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orgName': orgName,
          'adminEmail': adminEmail,
          'adminPassword': adminPassword,
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
}

