import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import '../../../../core/constants/app_colors.dart';

class EditTestSheet extends StatefulWidget {
  final Map<String, dynamic> test;
  final List<Map<String, dynamic>> classSubjects;
  final void Function(Map<String, dynamic>) onUpdated;

  const EditTestSheet({
    required this.test,
    required this.classSubjects,
    required this.onUpdated,
  });

  @override
  _EditTestSheetState createState() => _EditTestSheetState();
}

class _EditTestSheetState extends State<EditTestSheet> {
  static const Color _accent = Colors.teal;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _testNameCtrl;
  bool _isLoading = false;
  final List<Map<String, TextEditingController>> _subjectCtrls = [];

  @override
  void initState() {
    super.initState();
    _testNameCtrl = TextEditingController(
      text: widget.test['testModule']?.toString() ?? '',
    );

    final subjects = widget.test['subjects'] as List? ?? [];
    if (subjects.isNotEmpty) {
      for (final s in subjects) {
        final sub = s as Map<String, dynamic>;
        _subjectCtrls.add({
          'name': TextEditingController(
            text: sub['subjectName']?.toString() ?? '',
          ),
          'max': TextEditingController(
            text: sub['maximumScore']?.toString() ?? '100',
          ),
          'min': TextEditingController(
            text: sub['minimumScore']?.toString() ?? '35',
          ),
        });
      }
    } else if (widget.classSubjects.isNotEmpty) {
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
      _addSubjectRow();
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

    final testId = widget.test['testId']?.toString() ?? '';
    final subjects = _subjectCtrls
        .map(
          (row) => {
            'subjectName': row['name']!.text.trim(),
            'maximumScore': int.tryParse(row['max']!.text.trim()) ?? 100,
            'minimumScore': int.tryParse(row['min']!.text.trim()) ?? 35,
          },
        )
        .toList();

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.apiBaseUrl}/test/$testId'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'testModule': _testNameCtrl.text.trim(),
          'subjects': subjects,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final updated =
            body['test'] as Map<String, dynamic>? ??
            body['data'] as Map<String, dynamic>? ??
            {
              ...widget.test,
              'testModule': _testNameCtrl.text.trim(),
              'subjects': subjects,
            };
        setState(() => _isLoading = false);
        Navigator.pop(context);
        widget.onUpdated(updated);
      } else {
        setState(() => _isLoading = false);
        _snack('Failed to update test.', Colors.red[600]!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('No internet connection.', Colors.red[600]!);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      // After
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + bottomInset + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle ──
              Center(
                child: Container(
                  width: 36,
                  height: 3,
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
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Icon(Icons.edit_rounded, color: _accent, size: 16),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Edit Test',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey[500],
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),

              // ── Test Name ──
              _label('Test Name *'),
              SizedBox(height: 5),
              _inputField(
                controller: _testNameCtrl,
                hint: 'e.g. Unit Test 1',
                icon: Icons.bookmark_outline_rounded,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Test name is required'
                    : null,
              ),
              SizedBox(height: 16),

              // ── Subjects header ──
              Row(
                children: [
                  _label('Subjects'),
                  Spacer(),
                  GestureDetector(
                    onTap: _addSubjectRow,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: _accent.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: _accent, size: 13),
                          SizedBox(width: 3),
                          Text(
                            'Add Subject',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              ...List.generate(_subjectCtrls.length, (i) => _subjectRow(i)),
              SizedBox(height: 20),

              // ── Submit ──
              Theme(
                data: ThemeData(
                  colorScheme: ColorScheme.light(
                    primary: _accent,
                    onPrimary: Colors.white,
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _accent.withOpacity(0.4),
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Saving...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // ── Subject name ──
          Container(
            padding: EdgeInsets.fromLTRB(10, 0, 6, 0),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.03),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.subject_rounded, color: _accent, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: row['name'],
                    cursorColor: _accent,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                    decoration: InputDecoration(
                      hintText: 'Subject name',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                      errorStyle: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                if (_subjectCtrls.length > 1)
                  GestureDetector(
                    onTap: () => _removeSubjectRow(index),
                    child: Container(
                      margin: EdgeInsets.only(left: 4),
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.red[400],
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Max / Min ──
          Padding(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: _scoreField(
                    row['max']!,
                    'Max Score',
                    Icons.arrow_upward_rounded,
                    _accent,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _scoreField(
                    row['min']!,
                    'Min Score',
                    Icons.arrow_downward_rounded,
                    Colors.orange[700]!,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreField(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    Color color,
  ) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      cursorColor: _accent,
      style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (int.tryParse(v) == null) return 'Numbers only';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
        prefixIcon: Icon(icon, color: color, size: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: _accent.withOpacity(0.4), width: 1.5),
        ),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        errorStyle: TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.3,
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: TextFormField(
      controller: controller,
      cursorColor: _accent,
      style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: _accent, size: 16),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        errorStyle: TextStyle(color: Colors.red[400], fontSize: 10),
      ),
    ),
  );
}

