import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

class EnterMarksSheet extends StatefulWidget {
  final Map<String, dynamic> test;
  final Map<String, dynamic> student;
  final String orgId;
  final String teacherName;
  final Map<String, dynamic>? existingResult;
  final void Function(Map<String, dynamic>) onSaved;

  const EnterMarksSheet({
    required this.test,
    required this.student,
    required this.orgId,
    required this.teacherName,
    required this.onSaved,
    this.existingResult,
  });

  @override
  _EnterMarksSheetState createState() => _EnterMarksSheetState();
}

class _EnterMarksSheetState extends State<EnterMarksSheet> {
  static const Color _accent = Colors.teal;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _subjectRows = [];

  @override
  void initState() {
    super.initState();
    _buildRows();
  }

  void _buildRows() {
    final subjects = widget.test['subjects'] as List? ?? [];
    final existingSubjects =
        widget.existingResult?['subjectResults'] as List? ?? [];

    for (final s in subjects) {
      final sub = s as Map<String, dynamic>;
      final name = sub['subjectName']?.toString() ?? '';
      final max = sub['maximumScore'] ?? 100;
      final min = sub['minimumScore'] ?? 35;

      String existingScore = '';
      String existingRemarks = '';
      try {
        final existing =
            existingSubjects.firstWhere(
                  (e) => (e as Map)['subjectName']?.toString() == name,
                )
                as Map<String, dynamic>;
        existingScore = existing['scoredMarks']?.toString() ?? '';
        existingRemarks = existing['remarks']?.toString() ?? '';
      } catch (_) {}

      _subjectRows.add({
        'name': name,
        'max': max,
        'min': min,
        'scoreCtrl': TextEditingController(text: existingScore),
        'remarksCtrl': TextEditingController(text: existingRemarks),
      });
    }
  }

  @override
  void dispose() {
    for (final row in _subjectRows) {
      (row['scoreCtrl'] as TextEditingController).dispose();
      (row['remarksCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // ── Resolve all IDs safely ──
    final testId =
        widget.test['testId']?.toString() ??
        widget.test['_id']?.toString() ??
        '';
    final studentId =
        widget.student['studentId']?.toString() ??
        widget.student['_id']?.toString() ??
        '';

    // ── publishedBy: use passed name, never empty ──
    final publishedBy = widget.teacherName.isNotEmpty
        ? widget.teacherName
        : 'Teacher';

    final isUpdate = widget.existingResult != null;
    final resultId =
        widget.existingResult?['resultId']?.toString() ??
        widget.existingResult?['_id']?.toString() ??
        '';

    debugPrint('>>> testId: $testId');
    debugPrint('>>> studentId: $studentId');
    debugPrint('>>> publishedBy: $publishedBy');
    debugPrint('>>> isUpdate: $isUpdate  resultId: $resultId');

    if (testId.isEmpty || studentId.isEmpty) {
      setState(() => _isLoading = false);
      _snack('Missing test or student ID. Please retry.', Colors.red[600]!);
      return;
    }

    final subjectResults = _subjectRows.map((row) {
      return {
        'subjectName': row['name'],
        'scoredMarks':
            int.tryParse(
              (row['scoreCtrl'] as TextEditingController).text.trim(),
            ) ??
            0,
        'remarks': (row['remarksCtrl'] as TextEditingController).text.trim(),
      };
    }).toList();

    final payload = isUpdate
        ? {'publishedBy': publishedBy, 'subjectResults': subjectResults}
        : {
            'testId': testId,
            'studentId': studentId,
            'publishedBy': publishedBy,
            'subjectResults': subjectResults,
          };

    debugPrint('>>> PAYLOAD: ${jsonEncode(payload)}');

    try {
      http.Response response;
      if (isUpdate) {
        response = await http.put(
          Uri.parse('${ApiConstants.apiBaseUrl}/result/$resultId'),
          headers: await ApiService.getHeaders(),
          body: jsonEncode(payload),
        );
      } else {
        response = await http.post(
          Uri.parse('${ApiConstants.apiBaseUrl}/result/publish'),
          headers: await ApiService.getHeaders(),
          body: jsonEncode(payload),
        );
      }

      debugPrint('MARKS STATUS: ${response.statusCode}');
      debugPrint('MARKS BODY: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final result =
            body['result'] as Map<String, dynamic>? ??
            body['data'] as Map<String, dynamic>? ??
            body;
        setState(() => _isLoading = false);
        Navigator.pop(context);
        widget.onSaved(result);
      } else {
        final body = _tryDecode(response.body);
        setState(() => _isLoading = false);
        _snack(
          body['message']?.toString() ??
              body['error']?.toString() ??
              'Failed to save marks.',
          Colors.red[600]!,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  Map<String, dynamic> _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final studentName =
        widget.student['studentName']?.toString() ??
        widget.student['name']?.toString() ??
        'Student';
    final testName = widget.test['testModule']?.toString() ?? 'Test';
    final isUpdate = widget.existingResult != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accent, _accent.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          testName,
                          style: TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.teacherName.isNotEmpty)
                          Text(
                            'By: ${widget.teacherName}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isUpdate)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Edit Mode',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // ── Subject rows ──
              if (_subjectRows.isEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.orange[700],
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No subjects found for this test.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._subjectRows.map((row) => _subjectMarkRow(row)).toList(),

              SizedBox(height: 24),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isLoading || _subjectRows.isEmpty)
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _accent.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isUpdate
                                  ? Icons.save_rounded
                                  : Icons.check_rounded,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              isUpdate ? 'Update Marks' : 'Publish Marks',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subjectMarkRow(Map<String, dynamic> row) {
    final name = row['name'] as String;
    final max = row['max'];
    final min = row['min'];
    final scoreCtrl = row['scoreCtrl'] as TextEditingController;
    final remarksCtrl = row['remarksCtrl'] as TextEditingController;
    final maxInt = max is int ? max : int.tryParse(max.toString()) ?? 100;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject name + score range
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.subject_rounded, color: _accent, size: 14),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Max: $max  Pass: $min',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Score + Remarks fields
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: scoreCtrl,
                    keyboardType: TextInputType.number,
                    cursorColor: _accent,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null) return 'Numbers only';
                      if (n < 0) return 'Min 0';
                      if (n > maxInt) return 'Max $maxInt';
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Scored Marks',
                      labelStyle: TextStyle(color: _accent, fontSize: 12),
                      hintText: '0–$max',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.edit_rounded,
                        color: _accent,
                        size: 16,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _accent.withOpacity(0.5)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.red[300]!),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.red[300]!),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      errorStyle: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: remarksCtrl,
                    cursorColor: _accent,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Remarks (optional)',
                      labelStyle: TextStyle(color: _accent, fontSize: 12),
                      hintText: 'e.g. Good performance',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.comment_outlined,
                        color: _accent.withOpacity(0.6),
                        size: 16,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _accent.withOpacity(0.5)),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

