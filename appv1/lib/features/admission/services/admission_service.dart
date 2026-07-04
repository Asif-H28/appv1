import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../models/admission_model.dart';

class AdmissionService {
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

  Future<List<AdmissionFormTemplateField>> getTemplate() async {
    final url = Uri.parse('${ApiConstants.apiBaseUrl}/admission-forms/template');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null && data['data']['admissionFormTemplate'] != null) {
        final List templatesData = data['data']['admissionFormTemplate'];
        return templatesData.map((e) => AdmissionFormTemplateField.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<bool> updateTemplate(List<AdmissionFormTemplateField> fields) async {
    final url = Uri.parse('${ApiConstants.apiBaseUrl}/admission-forms/template');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'admissionFormTemplate': fields.map((e) => e.toJson()).toList(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<Map<String, dynamic>> getSubmissions({int page = 1, int limit = 10, String? search}) async {
    String urlStr = '${ApiConstants.apiBaseUrl}/admission-forms?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) {
      urlStr += '&search=$search';
    }
    final url = Uri.parse(urlStr);
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List listData = data['data'] ?? [];
        final List<AdmissionForm> forms = listData.map((e) => AdmissionForm.fromJson(e)).toList();
        return {
          'forms': forms,
          'total': data['pagination']?['total'] ?? 0,
          'totalPages': data['pagination']?['totalPages'] ?? 1,
        };
      }
    }
    return {'forms': <AdmissionForm>[], 'total': 0, 'totalPages': 1};
  }

  Future<bool> updateSubmission(String id, Map<String, dynamic> updateData) async {
    final url = Uri.parse('${ApiConstants.apiBaseUrl}/admission-forms/$id');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getTeachers(String orgId) async {
    final url = Uri.parse('${ApiConstants.apiBaseUrl}/teacher/org/$orgId');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['teachers'] != null) {
        return List<Map<String, dynamic>>.from(data['teachers']);
      }
    }
    return [];
  }

  Future<bool> createSubmission(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConstants.apiBaseUrl}/admission-forms');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      final respData = jsonDecode(response.body);
      return respData['success'] == true;
    }
    return false;
  }
}
