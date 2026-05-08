import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
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
  static const Color _accent = Colors.teal;

  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  bool _isCreating = false;
  String _orgId = '';

  final List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadOrgId();
    _addSubject();
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

  void _addLesson(int si) {
    setState(() {
      (_subjects[si]['lessons'] as List<TextEditingController>).add(
        TextEditingController(),
      );
    });
  }

  void _removeLesson(int si, int li) {
    final lessons = _subjects[si]['lessons'] as List<TextEditingController>;
    lessons[li].dispose();
    setState(() => lessons.removeAt(li));
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
        Uri.parse('${ApiConstants.apiBaseUrl}/classroom/create'),
        headers: await ApiService.getHeaders(),
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
        _snack('Classroom created successfully!', Colors.green[600]!);
        Navigator.pop(context);
      } else {
        final body = jsonDecode(response.body);
        _snack(
          body['message']?.toString() ?? 'Failed to create classroom.',
          Colors.red[600]!,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      _snack(
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Something went wrong.',
        Colors.red[600]!,
      );
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

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Gradient header ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 12, 16, 14),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Classroom',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Set up a new classroom',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Create button in header
                    GestureDetector(
                      onTap: _isCreating ? null : _createClassroom,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isCreating
                              ? Colors.white.withOpacity(0.5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: _isCreating
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      color: _accent,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Creating...',
                                    style: TextStyle(
                                      color: _accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    color: _accent,
                                    size: 14,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Create',
                                    style: TextStyle(
                                      color: _accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
          ),

          // ── Body ──
          Expanded(
            child: SafeArea(
              top: false,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(14, 14, 14, 40),
                  children: [
                    // ── Classroom name ──
                    _label('CLASSROOM NAME'),
                    SizedBox(height: 6),
                    _inputField(
                      controller: _classNameController,
                      hint: 'e.g. Class 10-A',
                      icon: Icons.class_rounded,
                      capitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Classroom name is required'
                          : null,
                    ),
                    SizedBox(height: 16),

                    // ── Subjects header ──
                    Row(
                      children: [
                        _label('SUBJECTS & LESSONS'),
                        Spacer(),
                        GestureDetector(
                          onTap: _addSubject,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add Subject',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // ── Subject cards ──
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
    );
  }

  // ─────────────────────────────────────────────
  // SUBJECT CARD
  // ─────────────────────────────────────────────

  Widget _buildSubjectCard(
    int si,
    Map<String, dynamic> sub,
    List<TextEditingController> lessons,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Subject header row ──
          Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: _accent,
                    size: 14,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Subject ${si + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Spacer(),
                if (_subjects.length > 1)
                  GestureDetector(
                    onTap: () => _removeSubject(si),
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red[400],
                        size: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Subject name input ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: TextFormField(
              controller: sub['nameController'] as TextEditingController,
              cursorColor: _accent,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(fontSize: 13),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Subject name required' : null,
              decoration: _fieldDeco(
                'Subject name (e.g. Mathematics)',
                Icons.subject_rounded,
              ),
            ),
          ),

          SizedBox(height: 10),

          // ── Lessons header ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  'Lessons',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () => _addLesson(si),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: _accent.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: _accent, size: 11),
                        SizedBox(width: 3),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 6),

          // ── Lesson rows ──
          ...lessons.asMap().entries.map((le) {
            final li = le.key;
            final ctrl = le.value;
            return Padding(
              padding: EdgeInsets.fromLTRB(12, 3, 8, 3),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withOpacity(0.45),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      cursorColor: _accent,
                      style: TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'Lesson ${li + 1} name',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 12.5,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  if (lessons.length > 1)
                    GestureDetector(
                      onTap: () => _removeLesson(si, li),
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),

          SizedBox(height: 10),

          // ── Lesson count badge ──
          Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '${lessons.length} lesson${lessons.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: _accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.6,
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    cursorColor: _accent,
    style: TextStyle(fontSize: 13),
    textCapitalization: capitalization,
    validator: validator,
    decoration: _fieldDeco(hint, icon),
  );

  InputDecoration _fieldDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: AppColors.textSecondary.withOpacity(0.5),
      fontSize: 13,
    ),
    prefixIcon: Icon(icon, color: _accent, size: 16),
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
      borderSide: BorderSide(color: _accent.withOpacity(0.5), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}

