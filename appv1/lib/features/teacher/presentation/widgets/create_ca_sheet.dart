import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class CreateCaSheet extends StatefulWidget {
  final String classId;
  final String teacherId;
  final String teacherName;
  final String orgId;
  final String className;
  final List<Map<String, dynamic>> classSubjects;
  final void Function(Map<String, dynamic>) onCreated;

  const CreateCaSheet({
    Key? key,
    required this.classId,
    required this.teacherId,
    required this.teacherName,
    required this.orgId,
    required this.className,
    required this.classSubjects,
    required this.onCreated,
  }) : super(key: key);

  @override
  _CreateCaSheetState createState() => _CreateCaSheetState();
}

class _CreateCaSheetState extends State<CreateCaSheet> {
  static const Color _accent = Colors.teal;
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, TextEditingController>> _scholasticCtrls = [];
  final List<Map<String, TextEditingController>> _coScholasticCtrls = [];

  @override
  void initState() {
    super.initState();
    if (widget.classSubjects.isNotEmpty) {
      for (final sub in widget.classSubjects) {
        final name = sub['subjectName']?.toString() ?? sub['name']?.toString() ?? '';
        _scholasticCtrls.add({
          'name': TextEditingController(text: name),
          'internalMax': TextEditingController(text: '20'),
          'externalMax': TextEditingController(text: '80'),
          'totalMax': TextEditingController(text: '100'),
          'minPass': TextEditingController(text: '33'),
        });
      }
    } else {
      _addScholasticRow();
    }
    
    // Add default co-scholastic subjects
    _coScholasticCtrls.add({
      'name': TextEditingController(text: 'Work Education'),
      'maxScore': TextEditingController(text: '100'),
    });
    _coScholasticCtrls.add({
      'name': TextEditingController(text: 'Art Education'),
      'maxScore': TextEditingController(text: '100'),
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final row in _scholasticCtrls) {
      row['name']!.dispose();
      row['internalMax']!.dispose();
      row['externalMax']!.dispose();
      row['totalMax']!.dispose();
      row['minPass']!.dispose();
    }
    for (final row in _coScholasticCtrls) {
      row['name']!.dispose();
      row['maxScore']!.dispose();
    }
    super.dispose();
  }

  void _addScholasticRow() {
    setState(() {
      _scholasticCtrls.insert(0, {
        'name': TextEditingController(),
        'internalMax': TextEditingController(text: '20'),
        'externalMax': TextEditingController(text: '80'),
        'totalMax': TextEditingController(text: '100'),
        'minPass': TextEditingController(text: '33'),
      });
    });
  }

  void _removeScholasticRow(int index) {
    if (_scholasticCtrls.length <= 1) return;
    _scholasticCtrls[index]['name']!.dispose();
    _scholasticCtrls[index]['internalMax']!.dispose();
    _scholasticCtrls[index]['externalMax']!.dispose();
    _scholasticCtrls[index]['totalMax']!.dispose();
    _scholasticCtrls[index]['minPass']!.dispose();
    setState(() => _scholasticCtrls.removeAt(index));
  }

  void _addCoScholasticRow() {
    setState(() {
      _coScholasticCtrls.insert(0, {
        'name': TextEditingController(),
        'maxScore': TextEditingController(text: '100'),
      });
    });
  }

  void _removeCoScholasticRow(int index) {
    _coScholasticCtrls[index]['name']!.dispose();
    _coScholasticCtrls[index]['maxScore']!.dispose();
    setState(() => _coScholasticCtrls.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final scholasticSubjects = _scholasticCtrls.map((row) {
      return {
        'subjectName': row['name']!.text.trim(),
        'internalMaximumScore': int.tryParse(row['internalMax']!.text.trim()) ?? 20,
        'externalMaximumScore': int.tryParse(row['externalMax']!.text.trim()) ?? 80,
        'totalMaximumScore': int.tryParse(row['totalMax']!.text.trim()) ?? 100,
        'minimumPassScore': int.tryParse(row['minPass']!.text.trim()) ?? 33,
      };
    }).toList();

    final coScholasticActivities = _coScholasticCtrls.map((row) {
      return {
        'activityName': row['name']!.text.trim(),
        'maximumScore': int.tryParse(row['maxScore']!.text.trim()) ?? 100,
      };
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    final teacherId = widget.teacherId.isNotEmpty ? widget.teacherId : prefs.getString('teacherId') ?? '';
    final teacherName = widget.teacherName.isNotEmpty ? widget.teacherName : prefs.getString('teacherName') ?? '';
    final orgId = widget.orgId.isNotEmpty ? widget.orgId : prefs.getString('orgId') ?? '';

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/comprehensive-assessment/create'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'orgId': orgId,
          'classId': widget.classId,
          'teacherName': teacherName,
          'teacherId': teacherId,
          'className': widget.className,
          'title': _titleCtrl.text.trim(),
          'scholasticSubjects': scholasticSubjects,
          'coScholasticActivities': coScholasticActivities,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? body;
        setState(() => _isLoading = false);
        Navigator.pop(context);

        // Ensure missing metadata is present before sending back
        final completeData = Map<String, dynamic>.from(data);
        completeData['title'] ??= _titleCtrl.text.trim();
        completeData['teacherName'] ??= teacherName;
        completeData['className'] ??= widget.className;
        completeData['createdAt'] ??= DateTime.now().toIso8601String();
        completeData['scholasticSubjects'] ??= scholasticSubjects;
        completeData['coScholasticActivities'] ??= coScholasticActivities;

        widget.onCreated(completeData);
      } else {
        final body = _tryDecode(response.body);
        setState(() => _isLoading = false);
        _snack(body['message']?.toString() ?? 'Failed to create assessment.', Colors.red[600]!);
      }
    } catch (_) {
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
            // Handle
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
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(Icons.assignment_turned_in_rounded, color: _accent, size: 16),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Comprehensive Assessment',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      Text(
                        widget.className,
                        style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
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
                      _label('Assessment Title *'),
                      SizedBox(height: 5),
                      _inputField(
                        controller: _titleCtrl,
                        hint: 'e.g. Term 1 Comprehensive Assessment',
                        icon: Icons.bookmark_outline_rounded,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                      ),
                      SizedBox(height: 20),

                      // Scholastic Subjects
                      Row(
                        children: [
                          _label('Scholastic Subjects'),
                          Spacer(),
                          GestureDetector(
                            onTap: _addScholasticRow,
                            child: _addBtn('Add Subject'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ...List.generate(_scholasticCtrls.length, (i) => _scholasticRow(i)),
                      SizedBox(height: 20),

                      // Co-Scholastic Subjects
                      Row(
                        children: [
                          _label('Co-Scholastic Activities'),
                          Spacer(),
                          GestureDetector(
                            onTap: _addCoScholasticRow,
                            child: _addBtn('Add Activity'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ...List.generate(_coScholasticCtrls.length, (i) => _coScholasticRow(i)),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            
            // Submit
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
                            Text('Creating...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 7),
                            Text('Create Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
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

  Widget _addBtn(String label) => Container(
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
          label,
          style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _scholasticRow(int index) {
    final row = _scholasticCtrls[index];
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
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
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    decoration: InputDecoration(
                      hintText: 'Subject name',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                      errorStyle: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                if (_scholasticCtrls.length > 1)
                  GestureDetector(
                    onTap: () => _removeScholasticRow(index),
                    child: Container(
                      margin: EdgeInsets.only(left: 4),
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(Icons.close_rounded, color: Colors.red[400], size: 12),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _scoreField(row['internalMax']!, 'Internal Max', Icons.grade, Colors.blue[600]!)),
                    SizedBox(width: 8),
                    Expanded(child: _scoreField(row['externalMax']!, 'External Max', Icons.grade_outlined, _accent)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _scoreField(row['totalMax']!, 'Total Max', Icons.functions, _accent)),
                    SizedBox(width: 8),
                    Expanded(child: _scoreField(row['minPass']!, 'Min Pass', Icons.done_all, Colors.orange[700]!)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coScholasticRow(int index) {
    final row = _coScholasticCtrls[index];
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(10, 0, 6, 0),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.03),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.sports_basketball_rounded, color: _accent, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: row['name'],
                    cursorColor: _accent,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    decoration: InputDecoration(
                      hintText: 'Activity name',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                      errorStyle: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeCoScholasticRow(index),
                  child: Container(
                    margin: EdgeInsets.only(left: 4),
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.07), borderRadius: BorderRadius.circular(3)),
                    child: Icon(Icons.close_rounded, color: Colors.red[400], size: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: _scoreField(row['maxScore']!, 'Max Score', Icons.functions, _accent)),
                SizedBox(width: 8),
                Expanded(child: SizedBox()), // Placeholder for alignment
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreField(TextEditingController ctrl, String hint, IconData icon, Color color) {
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
        labelText: hint,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 11),
        prefixIcon: Icon(icon, color: color, size: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: _accent.withOpacity(0.4), width: 1.5)),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        errorStyle: TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
  );

  Widget _inputField({required TextEditingController controller, required String hint, required IconData icon, String? Function(String?)? validator}) => Container(
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
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        errorStyle: TextStyle(color: Colors.red[400], fontSize: 10),
      ),
    ),
  );
}

