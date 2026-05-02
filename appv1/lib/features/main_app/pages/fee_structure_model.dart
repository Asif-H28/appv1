import 'package:appv1/core/constants/api_constants.dart';
// fee_structure_model.dart
// Data model + API service for Fee Structures

import 'dart:convert';
import 'package:http/http.dart' as http;

// â”€â”€ Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class BreakdownItem {
  String component;
  double amount;

  BreakdownItem({this.component = '', this.amount = 0});

  factory BreakdownItem.fromJson(Map<String, dynamic> j) => BreakdownItem(
    component: j['component']?.toString() ?? '',
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {'component': component, 'amount': amount};

  BreakdownItem copy() => BreakdownItem(component: component, amount: amount);
}

class FeeStructure {
  String id;
  String orgId;
  String structureName;
  int gradeFrom;
  int gradeTo;
  double feeAmount;
  bool hasBreakdown;
  List<BreakdownItem> breakdown;
  String createdAt;

  FeeStructure({
    this.id = '',
    this.orgId = '',
    this.structureName = '',
    this.gradeFrom = 1,
    this.gradeTo = 1,
    this.feeAmount = 0,
    this.hasBreakdown = false,
    this.breakdown = const [],
    this.createdAt = '',
  });

  factory FeeStructure.fromJson(Map<String, dynamic> j) => FeeStructure(
    id: j['_id']?.toString() ?? '',
    orgId: j['orgId']?.toString() ?? '',
    structureName: j['structureName']?.toString() ?? '',
    gradeFrom: (j['gradeFrom'] as num?)?.toInt() ?? 1,
    gradeTo: (j['gradeTo'] as num?)?.toInt() ?? 1,
    feeAmount: (j['feeAmount'] as num?)?.toDouble() ?? 0,
    hasBreakdown: j['hasBreakdown'] == true,
    breakdown: (j['breakdown'] as List<dynamic>? ?? [])
        .map((e) => BreakdownItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: j['createdAt']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'orgId': orgId,
    'structureName': structureName,
    'gradeFrom': gradeFrom,
    'gradeTo': gradeTo,
    'feeAmount': feeAmount,
    'hasBreakdown': hasBreakdown,
    'breakdown': breakdown.map((b) => b.toJson()).toList(),
  };

  // Computed total from breakdown items
  double get breakdownTotal => breakdown.fold(0, (sum, b) => sum + b.amount);
}

// â”€â”€ API Service â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class FeeStructureService {
  static const _base = '${ApiConstants.apiBaseUrl}/org/school/fee';

  // GET all
  static Future<List<FeeStructure>> getAll(String orgId) async {
    final res = await http.get(
      Uri.parse('$_base?orgId=$orgId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List<dynamic>)
            .map((e) => FeeStructure.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(
      jsonDecode(res.body)['message'] ?? 'Failed to load fee structures.',
    );
  }

  // POST create
  static Future<FeeStructure> create(FeeStructure fs) async {
    final res = await http.post(
      Uri.parse(_base),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fs.toJson()),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 201 && body['success'] == true) {
      return FeeStructure.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to create fee structure.');
  }

  // PUT update
  static Future<FeeStructure> update(String id, FeeStructure fs) async {
    final res = await http.put(
      Uri.parse('$_base/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fs.toJson()),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return FeeStructure.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to update fee structure.');
  }

  // DELETE
  static Future<void> delete(String id, String orgId) async {
    final res = await http.delete(
      Uri.parse('$_base/$id?orgId=$orgId'),
      headers: {'Content-Type': 'application/json'},
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to delete fee structure.');
    }
  }
}

