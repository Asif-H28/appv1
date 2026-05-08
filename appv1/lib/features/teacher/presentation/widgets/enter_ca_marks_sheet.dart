import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

class EnterCaMarksSheet extends StatefulWidget {
  final Map<String, dynamic> assessment;
  final Map<String, dynamic> student;
  final String classId;
  final String orgId;
  final String teacherName;
  final Map<String, dynamic>? existingResult;
  final void Function(Map<String, dynamic>) onSaved;

  const EnterCaMarksSheet({
    Key? key,
    required this.assessment,
    required this.student,
    required this.classId,
    required this.orgId,
    required this.teacherName,
    this.existingResult,
    required this.onSaved,
  }) : super(key: key);

  @override
  _EnterCaMarksSheetState createState() => _EnterCaMarksSheetState();
}

class _EnterCaMarksSheetState extends State<EnterCaMarksSheet> {
  static const Color _accent = Colors.teal;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final Map<String, Map<String, TextEditingController>> _scholasticCtrls = {};
  final Map<String, Map<String, TextEditingController>> _coScholasticCtrls = {};

  List<dynamic> get _scholasticSubjects => widget.assessment['scholasticSubjects'] as List? ?? [];
  List<dynamic> get _coScholasticActivities => widget.assessment['coScholasticActivities'] as List? ?? [];

  @override
  void initState() {
    super.initState();

    final exScholastic = widget.existingResult?['scholasticResults'] as List? ?? [];
    final exCoScholastic = widget.existingResult?['coScholasticResults'] as List? ?? [];

    for (final s in _scholasticSubjects) {
      if (s is Map) {
        final name = s['subjectName']?.toString() ?? '';
        Map<String, dynamic>? existing;
        try {
          existing = exScholastic.firstWhere((x) => x['subjectName'] == name) as Map<String, dynamic>;
        } catch (_) {}
        
        _scholasticCtrls[name] = {
          'internal': TextEditingController(text: existing?['internalMarksScored']?.toString() ?? ''),
          'external': TextEditingController(text: existing?['externalMarksScored']?.toString() ?? ''),
          'grade': TextEditingController(text: existing?['grade']?.toString() ?? ''),
          'remarks': TextEditingController(text: existing?['remarks']?.toString() ?? ''),
        };
      }
    }

    for (final c in _coScholasticActivities) {
      if (c is Map) {
        final name = c['activityName']?.toString() ?? '';
        Map<String, dynamic>? existing;
        try {
          existing = exCoScholastic.firstWhere((x) => x['activityName'] == name) as Map<String, dynamic>;
        } catch (_) {}

        _coScholasticCtrls[name] = {
          'grade': TextEditingController(text: existing?['grade']?.toString() ?? ''),
          'remarks': TextEditingController(text: existing?['remarks']?.toString() ?? ''),
        };
      }
    }
  }

  @override
  void dispose() {
    for (final map in _scholasticCtrls.values) {
      map.values.forEach((c) => c.dispose());
    }
    for (final map in _coScholasticCtrls.values) {
      map.values.forEach((c) => c.dispose());
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final assessmentId = widget.assessment['assessmentId']?.toString() ?? widget.assessment['_id']?.toString() ?? '';
    final studentId = widget.student['studentId']?.toString() ?? widget.student['_id']?.toString() ?? '';
    final studentName = widget.student['studentName']?.toString() ?? widget.student['name']?.toString() ?? 'Unknown';

    final scholasticResults = _scholasticSubjects.map((s) {
      final name = s['subjectName']?.toString() ?? '';
      final ctrls = _scholasticCtrls[name]!;
      final internal = double.tryParse(ctrls['internal']!.text) ?? 0;
      final externalM = double.tryParse(ctrls['external']!.text) ?? 0;
      final total = internal + externalM;
      final minPass = double.tryParse(s['minimumPassScore']?.toString() ?? '33') ?? 33;
      final status = total >= minPass ? 'pass' : 'fail';

      return {
        'subjectName': name,
        'internalMarksScored': internal,
        'externalMarksScored': externalM,
        'totalMarksScored': total,
        'status': status,
        'grade': ctrls['grade']!.text.trim(),
        'remarks': ctrls['remarks']!.text.trim(),
      };
    }).toList();

    final coScholasticResults = _coScholasticActivities.map((c) {
      final name = c['activityName']?.toString() ?? '';
      final ctrls = _coScholasticCtrls[name]!;
      return {
        'activityName': name,
        'grade': ctrls['grade']!.text.trim(),
        'remarks': ctrls['remarks']!.text.trim(),
      };
    }).toList();

    final payload = {
      "studentId": studentId,
      "studentName": studentName,
      "classId": widget.classId,
      "orgId": widget.orgId,
      "className": widget.assessment['className'] ?? '',
      "publishedBy": widget.teacherName,
      "scholasticResults": scholasticResults,
      "coScholasticResults": coScholasticResults,
    };

    print('[EnterCaMarksSheet] Submitting Payload:');
    print('  studentId: "$studentId"');
    print('  studentName: "$studentName"');
    print('  classId: "${widget.classId}"');
    print('  orgId: "${widget.orgId}"');
    print('  publishedBy: "${widget.teacherName}"');

    if (studentId.isEmpty || studentName.isEmpty || widget.classId.isEmpty || widget.orgId.isEmpty || widget.teacherName.isEmpty) {
      print('[EnterCaMarksSheet] ERROR: Missing required fields');
      setState(() => _isLoading = false);
      _snack('Error: Missing required student or class info.', Colors.red[600]!);
      return;
    }

    try {
      final url = '${ApiConstants.apiBaseUrl}/comprehensive-result/assessment/$assessmentId/result';
      final response = await http.post(
        Uri.parse(url),
        headers: await ApiService.getHeaders(),
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? payload;
        setState(() => _isLoading = false);
        Navigator.pop(context);
        widget.onSaved(data is Map<String, dynamic> ? data : payload);
      } else {
        setState(() => _isLoading = false);
        final bodyDecoded = jsonDecode(response.body);
        _snack(bodyDecoded['message']?.toString() ?? 'Failed to save marks.', Colors.red[600]!);
      }
    } catch (e) {
      print('Save CA Marks Error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('No internet connection or server error.', Colors.red[600]!);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final studentName = widget.student['studentName']?.toString() ?? widget.student['name']?.toString() ?? 'Student';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset + MediaQuery.of(context).padding.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36, height: 3,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                  child: Icon(Icons.edit_document, color: _accent, size: 16),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enter Assessment Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                      Text(studentName, style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(3)),
                    child: Icon(Icons.close_rounded, color: Colors.grey[500], size: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),
            
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_scholasticSubjects.isNotEmpty) ...[
                        _sectionHeader('Scholastic Subjects', Icons.book_outlined),
                        SizedBox(height: 10),
                        ..._scholasticSubjects.map((s) => _buildScholasticInput(s as Map<String, dynamic>)),
                        SizedBox(height: 20),
                      ],
                      if (_coScholasticActivities.isNotEmpty) ...[
                        _sectionHeader('Co-Scholastic Activities', Icons.sports_basketball_rounded),
                        SizedBox(height: 10),
                        ..._coScholasticActivities.map((c) => _buildCoScholasticInput(c as Map<String, dynamic>)),
                      ]
                    ],
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            Theme(
              data: ThemeData(colorScheme: ColorScheme.light(primary: _accent, onPrimary: Colors.white)),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _accent.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('Saving...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 7),
                            Text('Save Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _accent),
        SizedBox(width: 6),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildScholasticInput(Map<String, dynamic> s) {
    final name = s['subjectName']?.toString() ?? '';
    final maxInternal = s['internalMaximumScore']?.toString() ?? '20';
    final maxExternal = s['externalMaximumScore']?.toString() ?? '80';
    final ctrls = _scholasticCtrls[name]!;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.textPrimary)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _markField(ctrls['internal']!, 'Internal (/$maxInternal)', maxInternal)),
              SizedBox(width: 8),
              Expanded(child: _markField(ctrls['external']!, 'External (/$maxExternal)', maxExternal)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _textField(ctrls['grade']!, 'Grade (e.g. A1)', false)),
              SizedBox(width: 8),
              Expanded(child: _textField(ctrls['remarks']!, 'Remarks', false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoScholasticInput(Map<String, dynamic> c) {
    final name = c['activityName']?.toString() ?? '';
    final ctrls = _coScholasticCtrls[name]!;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.textPrimary)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _textField(ctrls['grade']!, 'Grade (e.g. A)', true)),
              SizedBox(width: 8),
              Expanded(child: _textField(ctrls['remarks']!, 'Remarks', false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _markField(TextEditingController ctrl, String hint, String maxStr) {
    final maxVal = double.tryParse(maxStr) ?? 100;
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      cursorColor: _accent,
      style: TextStyle(fontSize: 12.5),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        final val = double.tryParse(v);
        if (val == null) return 'Invalid';
        if (val < 0 || val > maxVal) return 'Max: $maxStr';
        return null;
      },
      decoration: _inputDeco(hint),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, bool required) {
    return TextFormField(
      controller: ctrl,
      cursorColor: _accent,
      style: TextStyle(fontSize: 12.5),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return 'Required';
        return null;
      },
      decoration: _inputDeco(hint),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      labelText: hint,
      labelStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: _accent.withOpacity(0.4), width: 1.5)),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      errorStyle: TextStyle(fontSize: 10),
    );
  }
}
