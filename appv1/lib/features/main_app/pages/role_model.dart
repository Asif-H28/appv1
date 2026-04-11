// role_model.dart
// Data model + API service for School Management Profiles / Roles

import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Model ────────────────────────────────────────────────
class SchoolRole {
  final String id;
  final String orgId;
  final String position;
  final String assignedTo;
  final String createdAt;

  SchoolRole({
    this.id = '',
    this.orgId = '',
    this.position = '',
    this.assignedTo = '',
    this.createdAt = '',
  });

  factory SchoolRole.fromJson(Map<String, dynamic> j) => SchoolRole(
    id: j['_id']?.toString() ?? '',
    orgId: j['orgId']?.toString() ?? '',
    position: j['position']?.toString() ?? '',
    assignedTo: j['assignedTo']?.toString() ?? '',
    createdAt: j['createdAt']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'orgId': orgId,
    'position': position,
    'assignedTo': assignedTo,
  };

  SchoolRole copyWith({
    String? id,
    String? orgId,
    String? position,
    String? assignedTo,
    String? createdAt,
  }) => SchoolRole(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    position: position ?? this.position,
    assignedTo: assignedTo ?? this.assignedTo,
    createdAt: createdAt ?? this.createdAt,
  );
}

// ── API Service ──────────────────────────────────────────
class RoleService {
  static const _base = 'https://appv1backend.onrender.com/api/org/school/roles';

  // GET all
  static Future<List<SchoolRole>> getAll(String orgId) async {
    final res = await http.get(
      Uri.parse('$_base?orgId=$orgId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List<dynamic>)
            .map((e) => SchoolRole.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(jsonDecode(res.body)['message'] ?? 'Failed to load roles.');
  }

  // POST create
  static Future<SchoolRole> create(SchoolRole role) async {
    final res = await http.post(
      Uri.parse(_base),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(role.toJson()),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 201 && body['success'] == true) {
      return SchoolRole.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to create role.');
  }

  // PUT update
  static Future<SchoolRole> update(String id, SchoolRole role) async {
    final res = await http.put(
      Uri.parse('$_base/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(role.toJson()),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return SchoolRole.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to update role.');
  }

  // DELETE
  static Future<void> delete(String id, String orgId) async {
    final res = await http.delete(
      Uri.parse('$_base/$id?orgId=$orgId'),
      headers: {'Content-Type': 'application/json'},
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to delete role.');
    }
  }
}
