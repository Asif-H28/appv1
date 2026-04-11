// view_school_data.dart
// Models + service layer for View My School screen

import 'dart:convert';
import 'package:http/http.dart' as http;

// ── School basic details ──────────────────────────────
class SchoolBasicData {
  final String schoolName;
  final String campusAddress;
  final String schoolEmail;
  final String primaryContact;
  final int studentCount;
  final int facultyCount;

  SchoolBasicData({
    this.schoolName = '',
    this.campusAddress = '',
    this.schoolEmail = '',
    this.primaryContact = '',
    this.studentCount = 0,
    this.facultyCount = 0,
  });

  factory SchoolBasicData.fromJson(Map<String, dynamic> j) => SchoolBasicData(
    schoolName: j['schoolName']?.toString() ?? '',
    campusAddress: j['campusAddress']?.toString() ?? '',
    schoolEmail: j['schoolEmail']?.toString() ?? '',
    primaryContact: j['primaryContact']?.toString() ?? '',
    studentCount: (j['studentCount'] as num?)?.toInt() ?? 0,
    facultyCount: (j['facultyCount'] as num?)?.toInt() ?? 0,
  );
}

// ── Fee structure ─────────────────────────────────────
class FeeItem {
  final String id;
  final String structureName;
  final int gradeFrom;
  final int gradeTo;
  final double feeAmount;
  final bool hasBreakdown;

  FeeItem({
    this.id = '',
    this.structureName = '',
    this.gradeFrom = 1,
    this.gradeTo = 1,
    this.feeAmount = 0,
    this.hasBreakdown = false,
  });

  factory FeeItem.fromJson(Map<String, dynamic> j) => FeeItem(
    id: j['_id']?.toString() ?? '',
    structureName: j['structureName']?.toString() ?? '',
    gradeFrom: (j['gradeFrom'] as num?)?.toInt() ?? 1,
    gradeTo: (j['gradeTo'] as num?)?.toInt() ?? 1,
    feeAmount: (j['feeAmount'] as num?)?.toDouble() ?? 0,
    hasBreakdown: j['hasBreakdown'] == true,
  );

  // Indian number format: 1,15,000
  String get formattedFee {
    final n = feeAmount.toInt();
    if (n < 1000) return n.toString();
    final s = n.toString();
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
      buf.write(rest[i]);
    }
    return '${buf.toString()},$last3';
  }
}

// ── Role ──────────────────────────────────────────────
class RoleItem {
  final String id;
  final String position;
  final String assignedTo;

  RoleItem({this.id = '', this.position = '', this.assignedTo = ''});

  factory RoleItem.fromJson(Map<String, dynamic> j) => RoleItem(
    id: j['_id']?.toString() ?? '',
    position: j['position']?.toString() ?? '',
    assignedTo: j['assignedTo']?.toString() ?? '',
  );
}

// ── Combined view model ───────────────────────────────
class SchoolViewModel {
  final SchoolBasicData basic;
  final List<FeeItem> fees;
  final List<RoleItem> roles;

  SchoolViewModel({
    required this.basic,
    required this.fees,
    required this.roles,
  });
}

// ── Service ───────────────────────────────────────────
class ViewSchoolService {
  static const _base = 'https://appv1backend.onrender.com/api/org';

  static Future<SchoolViewModel> loadAll(String orgId) async {
    final results = await Future.wait([
      _getBasic(orgId),
      _getFees(orgId),
      _getRoles(orgId),
    ]);

    return SchoolViewModel(
      basic: results[0] as SchoolBasicData,
      fees: results[1] as List<FeeItem>,
      roles: results[2] as List<RoleItem>,
    );
  }

  static Future<SchoolBasicData> _getBasic(String orgId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/$orgId/school-details'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? {};
        return SchoolBasicData.fromJson(data);
      }
    } catch (_) {}
    return SchoolBasicData();
  }

  static Future<List<FeeItem>> _getFees(String orgId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/school/fee?orgId=$orgId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return (body['data'] as List<dynamic>)
              .map((e) => FeeItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<RoleItem>> _getRoles(String orgId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/school/roles?orgId=$orgId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return (body['data'] as List<dynamic>)
              .map((e) => RoleItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
