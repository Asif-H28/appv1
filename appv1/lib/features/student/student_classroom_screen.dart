import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_classroom_subjects_tab.dart';
import 'student_classroom_notes_tab.dart';
import 'student_classroom_tests_tab.dart';
import '../quiz/student/student_quiz_list_screen.dart';
import 'student_classroom_homework_tab.dart';
import 'package:appv1/features/learning_resources/screens/learning_resources_screen.dart';
import 'package:appv1/features/tuition_session/student/student_session_generator_screen.dart';

const Color _accent = Colors.teal;

class StudentClassroomScreen extends StatefulWidget {
  @override
  _StudentClassroomScreenState createState() => _StudentClassroomScreenState();
}

class _StudentClassroomScreenState extends State<StudentClassroomScreen> {
  bool _isLoading = true;
  String _error = '';
  String _teacherName = '';

  Map<String, dynamic> _classroom = {};
  String _classId = '';

  @override
  void initState() {
    super.initState();
    _loadClassroom();
  }

  // ── Step 1: load classroom ─────────────────────────────

  Future<void> _loadClassroom() async {
    final prefs = await SharedPreferences.getInstance();
    _classId = prefs.getString('classId') ?? '';

    if (_classId.isEmpty) {
      setState(() {
        _error = 'No classroom assigned.';
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/classroom/$_classId',
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final classroom = body['classroom'] as Map<String, dynamic>? ?? {};
        setState(() => _classroom = classroom);

        // ── Step 2: fetch teacher name using teacherId ──
        final teacherId = classroom['teacherId']?.toString() ?? '';
        if (teacherId.isNotEmpty) {
          await _loadTeacherName(teacherId);
        }

        setState(() => _isLoading = false);
      } else {
        setState(() {
          _error = 'Failed to load classroom.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No internet connection.';
        _isLoading = false;
      });
    }
  }

  // ── Step 2: fetch teacher by ID ────────────────────────

  Future<void> _loadTeacherName(String teacherId) async {
    try {
      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/teacher/$teacherId/profile',
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final teacher = body['teacher'] as Map<String, dynamic>? ?? {};
        final name = teacher['name']?.toString() ?? '';
        if (name.isNotEmpty) {
          setState(() => _teacherName = name);
        }
      }
    } catch (_) {
      // silently fail — teacher tag just won't show
    }
  }

  // ── Navigate to a detail page wrapped in Scaffold ──────

  void _navigateTo(Widget page, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final className = _classroom['className']?.toString() ?? 'Classroom';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            // ── Gradient header ──
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, Color(0xFF26A69A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 16, 20),
                  child: Row(
                    children: [
                      // ── Back button ──
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // ── Icon ──
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.class_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // ── Title + teacher tag ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLoading ? 'Loading...' : className,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (_teacherName.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person_rounded,
                                          color: Colors.white.withOpacity(0.9),
                                          size: 10,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _teacherName,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (!_isLoading &&
                                    _classroom['subjects'] != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '${(_classroom['subjects'] as List).length} Subjects',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ──
            Expanded(
              child: _isLoading
                  ? _buildLoader()
                  : _error.isNotEmpty
                  ? _buildError()
                  : _buildMenuList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Vertical menu list ─────────────────────────────────

  Widget _buildMenuList() {
    final items = [
      _MenuItem(
        label: 'Subjects',
        icon: Icons.book_rounded,
        iconColor: const Color(0xFF3B7BF6),
        bgColor: const Color(0xFFE8EFFF),
        page: StudentClassroomSubjectsTab(classroom: _classroom),
      ),
      _MenuItem(
        label: 'Notes',
        icon: Icons.sticky_note_2_rounded,
        iconColor: const Color(0xFFFF9800),
        bgColor: const Color(0xFFFFF3E0),
        page: StudentClassroomNotesTab(),
      ),
      _MenuItem(
        label: 'Tests',
        icon: Icons.assignment_rounded,
        iconColor: const Color(0xFF9C27B0),
        bgColor: const Color(0xFFF3E5F5),
        page: StudentClassroomTestsTab(),
      ),
      _MenuItem(
        label: 'Quizzes',
        icon: Icons.quiz_rounded,
        iconColor: const Color(0xFF26A69A),
        bgColor: const Color(0xFFE0F2F1),
        page: const StudentQuizListScreen(),
      ),
      _MenuItem(
        label: 'Homework',
        icon: Icons.home_work_rounded,
        iconColor: const Color(0xFFE53935),
        bgColor: const Color(0xFFFFEBEE),
        page: StudentClassroomHomeworkTab(classroom: _classroom),
      ),
      _MenuItem(
        label: 'Learning Resources',
        icon: Icons.video_library_rounded,
        iconColor: const Color(0xFFE53935),
        bgColor: const Color(0xFFFFEBEE),
        page: LearningResourcesScreen(classData: {..._classroom, 'classId': _classId}),
      ),
      _MenuItem(
        label: 'Generate Session QR',
        icon: Icons.qr_code_2_rounded,
        iconColor: const Color(0xFF009688),
        bgColor: const Color(0xFFE0F2F1),
        page: StudentSessionGeneratorScreen(classId: _classId),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'ACADEMIC MANAGEMENT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 1.1,
            ),
          ),
        ),

        // White card containing the list
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isLast = index == items.length - 1;
              return _buildMenuItem(item, isLast: isLast, onTap: () => _navigateTo(item.page, item.label));
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItem item, {bool isLast = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            // ── Circular icon ──
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.iconColor, size: 22),
            ),
            const SizedBox(width: 14),

            // ── Label ──
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),

            // ── Chevron ──
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Loader ────────────────────────────────────────────

  Widget _buildLoader() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
        SizedBox(height: 14),
        Text(
          'Loading classroom...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );

  // ── Error ─────────────────────────────────────────────

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red[400],
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _isLoading = true;
                _error = '';
              });
              _loadClassroom();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Data model ────────────────────────────────────────────

class _MenuItem {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Widget page;

  const _MenuItem({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.page,
  });
}
