import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class CreateTestSheet extends StatefulWidget {
  final String classId;
  final String teacherId;
  final String teacherName;
  final String orgId;
  final String className;
  final List<Map<String, dynamic>> classSubjects;
  final void Function(Map<String, dynamic>) onCreated;

  const CreateTestSheet({
    required this.classId,
    required this.teacherId,
    required this.teacherName,
    required this.orgId,
    required this.className,
    required this.classSubjects,
    required this.onCreated,
  });

  @override
  _CreateTestSheetState createState() => _CreateTestSheetState();
}

class _CreateTestSheetState extends State<CreateTestSheet> {
  static const Color _accent = Colors.teal;
  final _formKey = GlobalKey<FormState>();
  final _testNameCtrl = TextEditingController(); // ← renamed
  bool _isLoading = false;

  final List<Map<String, TextEditingController>> _subjectCtrls = [];

  @override
  void initState() {
    super.initState();
    // ── Auto-fill subjects from classroom ──
    if (widget.classSubjects.isNotEmpty) {
      for (final sub in widget.classSubjects) {
        final name =
            sub['subjectName']?.toString() ?? sub['name']?.toString() ?? '';
        _subjectCtrls.add({
          'name': TextEditingController(text: name),
          'max': TextEditingController(text: '100'),
          'min': TextEditingController(text: '35'),
        });
      }
    } else {
      _addSubjectRow(); // fallback: one blank row
    }
  }

  @override
  void dispose() {
    _testNameCtrl.dispose();
    for (final row in _subjectCtrls) {
      row['name']!.dispose();
      row['max']!.dispose();
      row['min']!.dispose();
    }
    super.dispose();
  }

  void _addSubjectRow() {
    setState(() {
      _subjectCtrls.add({
        'name': TextEditingController(),
        'max': TextEditingController(text: '100'),
        'min': TextEditingController(text: '35'),
      });
    });
  }

  void _removeSubjectRow(int index) {
    if (_subjectCtrls.length <= 1) return;
    _subjectCtrls[index]['name']!.dispose();
    _subjectCtrls[index]['max']!.dispose();
    _subjectCtrls[index]['min']!.dispose();
    setState(() => _subjectCtrls.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final subjects = _subjectCtrls.map((row) {
      return {
        'subjectName': row['name']!.text.trim(),
        'maximumScore': int.tryParse(row['max']!.text.trim()) ?? 100,
        'minimumScore': int.tryParse(row['min']!.text.trim()) ?? 35,
      };
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    final teacherId = widget.teacherId.isNotEmpty
        ? widget.teacherId
        : prefs.getString('teacherId') ?? '';
    final teacherName = widget.teacherName.isNotEmpty
        ? widget.teacherName
        : prefs.getString('teacherName') ?? '';
    final orgId = widget.orgId.isNotEmpty
        ? widget.orgId
        : prefs.getString('orgId') ?? '';

    try {
      final response = await http.post(
        Uri.parse('https://appv1backend.onrender.com/api/test/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orgId': orgId,
          'classId': widget.classId,
          'teacherName': teacherName,
          'teacherId': teacherId,
          'testModule': _testNameCtrl.text
              .trim(), // field name stays testModule for API
          'subjects': subjects,
        }),
      );

      debugPrint('CREATE TEST STATUS: ${response.statusCode}');
      debugPrint('CREATE TEST BODY: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final test =
            body['test'] as Map<String, dynamic>? ??
            body['data'] as Map<String, dynamic>? ??
            body;
        setState(() => _isLoading = false);
        Navigator.pop(context);
        widget.onCreated(test);
      } else {
        final body = _tryDecode(response.body);
        setState(() => _isLoading = false);
        _snack(
          body['message']?.toString() ?? 'Failed to create test.',
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
              SizedBox(height: 18),

              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accent, _accent.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.quiz_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Test',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.className,
                          style: TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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

              // ── Test Name ──
              _label('Test Name'), // ← renamed label
              SizedBox(height: 6),
              _inputBox(
                child: TextFormField(
                  controller: _testNameCtrl,
                  cursorColor: _accent,
                  style: TextStyle(fontSize: 14),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Test name is required'
                      : null,
                  decoration: _deco(
                    hint: 'e.g. Unit Test 1',
                    icon: Icons.bookmark_outline_rounded,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // ── Subjects ──
              Row(
                children: [
                  Text(
                    'Subjects',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (widget.classSubjects.isNotEmpty) ...[
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Auto-filled',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  Spacer(),
                  GestureDetector(
                    onTap: _addSubjectRow,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: _accent, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Add Subject',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              ...List.generate(_subjectCtrls.length, (i) => _subjectRow(i)),
              SizedBox(height: 24),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
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
                              'Creating...',
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
                            Icon(Icons.check_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Create Test',
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

  Widget _subjectRow(int index) {
    final row = _subjectCtrls[index];
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: row['name'],
                  cursorColor: _accent,
                  style: TextStyle(fontSize: 13),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                  decoration: InputDecoration(
                    hintText: 'Subject name',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    prefixIcon: Icon(
                      Icons.subject_rounded,
                      color: _accent,
                      size: 16,
                    ),
                  ),
                ),
              ),
              if (_subjectCtrls.length > 1)
                GestureDetector(
                  onTap: () => _removeSubjectRow(index),
                  child: Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red[300],
                    size: 18,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _scoreField(
                  row['max']!,
                  'Max Score',
                  Icons.arrow_upward_rounded,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _scoreField(
                  row['min']!,
                  'Min Score',
                  Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreField(TextEditingController ctrl, String hint, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      cursorColor: _accent,
      style: TextStyle(fontSize: 13),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (int.tryParse(v) == null) return 'Number only';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.5),
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: _accent.withOpacity(0.6), size: 14),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _accent.withOpacity(0.4)),
        ),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        errorStyle: TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 13.5,
      color: AppColors.textPrimary,
    ),
  );

  Widget _inputBox({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
      border: Border.all(color: Colors.grey.withOpacity(0.12)),
    ),
    child: child,
  );

  InputDecoration _deco({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.5),
          fontSize: 14,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(icon, color: _accent, size: 18),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: TextStyle(color: Colors.red[400], fontSize: 11),
      );
}
