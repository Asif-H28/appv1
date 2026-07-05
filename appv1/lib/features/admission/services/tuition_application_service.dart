import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class TuitionApplicationService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getTuitionApplications({int page = 1, int limit = 10, String? search, String? status}) async {
    String urlStr = '${ApiConstants.apiBaseUrl}/tuition-applications?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) {
      urlStr += '&search=$search';
    }
    if (status != null && status.isNotEmpty) {
      urlStr += '&status=$status';
    }
    final url = Uri.parse(urlStr);
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'success': false, 'data': []};
  }

  Future<bool> deleteTuitionApplication(String id) async {
    final url = Uri.parse('${ApiConstants.apiBaseUrl}/tuition-applications/$id');
    final response = await http.delete(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<bool> reviewTuitionApplication(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConstants.apiBaseUrl}/tuition-applications/$id/review');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final respData = jsonDecode(response.body);
      return respData['success'] == true;
    }
    return false;
  }
}
