import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_classroom_subjects_tab.dart';
import 'student_classroom_notes_tab.dart';
import 'student_classroom_tests_tab.dart';
import '../quiz/student/student_quiz_list_screen.dart';

const Color _accent = Colors.teal;

class StudentClassroomScreen extends StatefulWidget {
  @override
  _StudentClassroomScreenState createState() => _StudentClassroomScreenState();
}

class _StudentClassroomScreenState extends State<StudentClassroomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String _error = '';
  String _teacherName = '';

  Map<String, dynamic> _classroom = {};
  String _classId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadClassroom();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final className = _classroom['className']?.toString() ?? 'Classroom';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
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
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(14, 12, 16, 12),
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
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),

                          // ── Icon ──
                          Container(
                            padding: EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.class_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 10),

                          // ── Title + teacher tag ──
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isLoading ? 'Loading...' : className,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    // ── Teacher name tag ──
                                    if (_teacherName.isNotEmpty) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.person_rounded,
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              size: 10,
                                            ),
                                            SizedBox(width: 4),
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
                                      SizedBox(width: 6),
                                    ],

                                    // ── Subjects count tag ──
                                    if (!_isLoading &&
                                        _classroom['subjects'] != null) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Text(
                                          '${(_classroom['subjects'] as List).length} Subjects',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.85,
                                            ),
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

                    // ── Tab bar ──
                    Container(
                      margin: EdgeInsets.fromLTRB(14, 0, 14, 12),
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: _accent,
                        unselectedLabelColor: Colors.white.withOpacity(0.85),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 11.5,
                        ),
                        padding: EdgeInsets.all(3),
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'Subjects'),
                          Tab(text: 'Notes'),
                          Tab(text: 'Tests'),
                          Tab(text: 'Quizzes'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body ──
            Expanded(
              child: _isLoading
                  ? _buildLoader()
                  : _error.isNotEmpty
                  ? _buildError()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        StudentClassroomSubjectsTab(classroom: _classroom),
                        StudentClassroomNotesTab(),
                        StudentClassroomTestsTab(),
                        const StudentQuizListScreen(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loader ────────────────────────────────────────────

  Widget _buildLoader() => Center(
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
      padding: EdgeInsets.all(24),
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
          SizedBox(height: 14),
          Text(
            _error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _isLoading = true;
                _error = '';
              });
              _loadClassroom();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
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

