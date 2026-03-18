import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class CreateClassroomPage extends StatefulWidget {
  final String teacherId;
  const CreateClassroomPage({required this.teacherId});

  @override
  _CreateClassroomPageState createState() => _CreateClassroomPageState();
}

class _CreateClassroomPageState extends State<CreateClassroomPage> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  bool _isCreating = false;
  String _orgId = '';

  // Subjects list with their lesson controllers
  final List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadOrgId();
    _addSubject(); // start with one subject
  }

  Future<void> _loadOrgId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _orgId = prefs.getString('orgId') ?? '');
  }

  void _addSubject() {
    setState(() {
      _subjects.add({
        'nameController': TextEditingController(),
        'lessons': <TextEditingController>[TextEditingController()],
      });
    });
  }

  void _removeSubject(int index) {
    final sub = _subjects[index];
    (sub['nameController'] as TextEditingController).dispose();
    for (final c in sub['lessons'] as List<TextEditingController>) {
      c.dispose();
    }
    setState(() => _subjects.removeAt(index));
  }

  void _addLesson(int subjectIndex) {
    setState(() {
      (_subjects[subjectIndex]['lessons'] as List<TextEditingController>).add(
        TextEditingController(),
      );
    });
  }

  void _removeLesson(int subjectIndex, int lessonIndex) {
    final lessons =
        _subjects[subjectIndex]['lessons'] as List<TextEditingController>;
    lessons[lessonIndex].dispose();
    setState(() => lessons.removeAt(lessonIndex));
  }

  Future<void> _createClassroom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      final subjects = _subjects
          .map((sub) {
            final name = (sub['nameController'] as TextEditingController).text
                .trim();
            final lessons = (sub['lessons'] as List<TextEditingController>)
                .map((c) => {'name': c.text.trim(), 'completed': false})
                .where((l) => (l['name'] as String).isNotEmpty)
                .toList();
            return {'name': name, 'lessons': lessons};
          })
          .where((s) => (s['name'] as String).isNotEmpty)
          .toList();

      final response = await http.post(
        Uri.parse('https://appv1backend.onrender.com/api/classroom/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teacherId': widget.teacherId,
          'orgId': _orgId,
          'className': _classNameController.text.trim(),
          'subjects': subjects,
        }),
      );

      if (!mounted) return;
      setState(() => _isCreating = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Classroom created successfully! 🎉',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        final body = jsonDecode(response.body);
        _showError(
          body['message']?.toString() ?? 'Failed to create classroom.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      _showError(
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Something went wrong.',
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _classNameController.dispose();
    for (final sub in _subjects) {
      (sub['nameController'] as TextEditingController).dispose();
      for (final c in sub['lessons'] as List<TextEditingController>) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.teal.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Classroom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Set up a new classroom',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 100),
                  children: [
                    // ── Class Name ──
                    _sectionLabel('Classroom Name'),
                    SizedBox(height: 8),
                    _inputCard(
                      child: TextFormField(
                        controller: _classNameController,
                        cursorColor: Colors.teal,
                        style: TextStyle(fontSize: 15),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Classroom name is required'
                            : null,
                        decoration: _inputDeco(
                          'e.g. Class 10-A',
                          Icons.class_rounded,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // ── Subjects ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionLabel('Subjects & Lessons'),
                        TextButton.icon(
                          onPressed: _addSubject,
                          icon: Icon(
                            Icons.add_circle_rounded,
                            color: Colors.teal,
                            size: 18,
                          ),
                          label: Text(
                            'Add Subject',
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    ..._subjects.asMap().entries.map((entry) {
                      final si = entry.key;
                      final sub = entry.value;
                      final lessons =
                          sub['lessons'] as List<TextEditingController>;
                      return _buildSubjectCard(si, sub, lessons);
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _createClassroom,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        disabledElevation: 0,
        elevation: 4,
        icon: _isCreating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(Icons.check_rounded),
        label: Text(
          _isCreating ? 'Creating...' : 'Create Classroom',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(
    int si,
    Map<String, dynamic> sub,
    List<TextEditingController> lessons,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.teal.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject header
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: Colors.teal,
                    size: 16,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Subject ${si + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Spacer(),
                if (_subjects.length > 1)
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_rounded,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    onPressed: () => _removeSubject(si),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Subject name field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: sub['nameController'] as TextEditingController,
              cursorColor: Colors.teal,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Subject name required' : null,
              decoration: _inputDeco(
                'Subject name (e.g. Mathematics)',
                Icons.subject_rounded,
              ),
            ),
          ),
          SizedBox(height: 12),

          // Lessons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Lessons',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () => _addLesson(si),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, color: Colors.teal, size: 16),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6),

          ...lessons.asMap().entries.map((le) {
            final li = le.key;
            final ctrl = le.value;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal.withOpacity(0.5),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: ctrl,
                      cursorColor: Colors.teal,
                      style: TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Lesson ${li + 1} name',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  if (lessons.length > 1)
                    GestureDetector(
                      onTap: () => _removeLesson(si, li),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.5,
    ),
  );

  Widget _inputCard({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: AppColors.textSecondary.withOpacity(0.5),
      fontSize: 14,
    ),
    prefixIcon: Icon(icon, color: Colors.teal, size: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.teal.withOpacity(0.4), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
