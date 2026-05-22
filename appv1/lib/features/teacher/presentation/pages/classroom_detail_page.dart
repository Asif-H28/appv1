import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/features/quiz/teacher/teacher_quiz_list_screen.dart';
import 'dart:convert';
import 'package:appv1/features/teacher/presentation/pages/classroom_timetable_tab.dart';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'year_rollover_page.dart';
import '../widgets/subject_lessons_tab.dart';
import '../widgets/classroom_students_tab.dart';
import '../widgets/classroom_notices_tab.dart';
import '../widgets/classroom_notes_tab.dart';
import '../widgets/classroom_requests_tab.dart';
import '../widgets/classroom_tests_tab.dart';

class ClassroomDetailPage extends StatefulWidget {
  final String classId;
  final String className;

  const ClassroomDetailPage({required this.classId, required this.className});

  @override
  _ClassroomDetailPageState createState() => _ClassroomDetailPageState();
}

class _ClassroomDetailPageState extends State<ClassroomDetailPage> {
  final Color _accent = Colors.teal;

  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic> _classroom = {};
  String _teacherNameFromPrefs = '';

  bool _isEditingName = false;
  final _nameController = TextEditingController();
  bool _isSavingName = false;

  // -1 means showing the main menu, otherwise showing the specific feature
  int _selectedFeatureIndex = -1;

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.menu_book_rounded,
      'label': 'Subjects',
      'color': Colors.blue[600],
      'group': 0,
    },
    {
      'icon': Icons.calendar_month_rounded,
      'label': 'Class Timetable',
      'color': Colors.orange[600],
      'group': 0,
    },
    {
      'icon': Icons.quiz_rounded,
      'label': 'Examinations',
      'color': Colors.purple[600],
      'group': 0,
    },
    {
      'icon': Icons.people_rounded,
      'label': 'Attendance',
      'color': Colors.indigo[600],
      'group': 0,
    },
    {
      'icon': Icons.campaign_rounded,
      'label': 'Notice Board',
      'color': Colors.amber[700],
      'group': 1,
    },
    {
      'icon': Icons.person_add_rounded,
      'label': 'Join Requests',
      'color': Colors.green[600],
      'group': 1,
    },
    {
      'icon': Icons.description_rounded,
      'label': 'Class Notes',
      'color': Colors.teal[600],
      'group': 1,
    },
    {
      'icon': Icons.trending_up_rounded,
      'label': 'Class Promotion',
      'color': Colors.pink[600],
      'group': 0,
    },
    {
      'icon': Icons.assignment_rounded,
      'label': 'Quizzes',
      'color': Colors.teal[600],
      'group': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
    _fetchClassroom();
  }

  Future<void> _loadTeacherName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teacherNameFromPrefs = prefs.getString('teacherName') ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchClassroom() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/classroom/${widget.classId}'),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        dynamic data;
        if (body['classroom'] != null) {
          data = body['classroom'];
        } else if (body['classrooms'] is List && (body['classrooms'] as List).isNotEmpty) {
          data = (body['classrooms'] as List).first;
        } else {
          data = body['data'] ?? body;
        }
        setState(() {
          _classroom = Map<String, dynamic>.from(data as Map);
          _nameController.text =
              _classroom['className']?.toString() ?? widget.className;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _saveClassName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    setState(() => _isSavingName = true);
    try {
      final res = await http.put(
        Uri.parse('${ApiConstants.apiBaseUrl}/classroom/${widget.classId}'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({'className': newName}),
      );
      if (!mounted) return;
      setState(() {
        _isSavingName = false;
        _isEditingName = false;
      });
      if (res.statusCode == 200) {
        setState(() => _classroom['className'] = newName);
        _snack('Classroom name updated!', Colors.green[600]!);
      } else {
        _snack('Failed to update name.', Colors.red[600]!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSavingName = false);
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _selectedFeatureIndex == -1) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Center(
          child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
        ),
      );
    }

    if (_hasError && _selectedFeatureIndex == -1) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: _buildError(),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_selectedFeatureIndex != -1) {
          setState(() => _selectedFeatureIndex = -1);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: _buildAppBar(),
        body: _selectedFeatureIndex == -1
            ? _buildMainMenu()
            : _buildFeatureContent(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final className = _classroom['className']?.toString() ?? widget.className;
    final isDetailView = _selectedFeatureIndex != -1;
    final title = isDetailView
        ? _features[_selectedFeatureIndex]['label']
        : className;
    final subtitle = isDetailView ? className : 'Manage your class activities';

    return AppBar(
      backgroundColor: Colors.teal,
      elevation: 1,
      centerTitle: false,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: GestureDetector(
            onTap: () {
              if (isDetailView) {
                setState(() => _selectedFeatureIndex = -1);
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isEditingName && !isDetailView
              ? SizedBox(
                  height: 24,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: const TextSelectionThemeData(
                        selectionHandleColor: Colors.white,
                        selectionColor: Colors.white30,
                        cursorColor: Colors.white,
                      ),
                    ),
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      cursorColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        filled: false,
                        fillColor: Colors.transparent,
                      ),
                      onSubmitted: (_) => _saveClassName(),
                    ),
                  ),
                )
              : Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
      actions: [
        if (!isDetailView) ...[
          if (_isEditingName)
            _appBarAction(
              _isSavingName ? null : Icons.check_rounded,
              _saveClassName,
              color: Colors.tealAccent,
              isLoading: _isSavingName,
            )
          else
            _appBarAction(
              Icons.edit_outlined,
              () => setState(() => _isEditingName = true),
            ),
          _appBarAction(Icons.refresh_rounded, _fetchClassroom),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _appBarAction(
    IconData? icon,
    VoidCallback onTap, {
    Color? color,
    bool isLoading = false,
  }) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(icon, color: color ?? Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildMainMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Grouped Menu Items ──
          _buildGroupTitle('ACADEMIC MANAGEMENT'),
          _buildMenuGroup([0, 1, 2, 3, 7, 8]),

          const SizedBox(height: 24),
          _buildGroupTitle('COMMUNICATION'),
          _buildMenuGroup([4, 5, 6]),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<int> indices) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(indices.length, (i) {
          final index = indices[i];
          final feature = _features[index];
          final isLast = i == indices.length - 1;

          return Column(
            children: [
              _buildMenuItem(
                icon: feature['icon'],
                label: feature['label'],
                color: feature['color'],
                onTap: () => setState(() => _selectedFeatureIndex = index),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Divider(height: 1, color: Colors.grey[100]),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[300],
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureContent() {
    final className = _classroom['className']?.toString() ?? widget.className;
    final subjects = _classroom['subjects'] as List? ?? [];
    final typedSubjects = subjects
        .map((s) => s as Map<String, dynamic>)
        .toList();
    final students = _classroom['students'] as List? ?? [];

    switch (_selectedFeatureIndex) {
      case 0: // Subjects
        return SubjectLessonsTab(
          classId: widget.classId,
          subjects: typedSubjects,
          onRefresh: _fetchClassroom,
        );
      case 1: // Timetable
        return ClassroomTimetableTab(
          classId: widget.classId,
          orgId: _classroom['orgId']?.toString() ?? '',
          teacherId: _classroom['teacherId']?.toString() ?? '',
          teacherName: _teacherNameFromPrefs.isNotEmpty
              ? _teacherNameFromPrefs
              : (_classroom['teacherName']?.toString() ?? ''),
          className: className,
          classSubjects: typedSubjects,
        );
      case 2: // Tests
        return ClassroomTestsTab(
          classId: widget.classId,
          teacherId: _classroom['teacherId']?.toString() ?? '',
          teacherName: _teacherNameFromPrefs.isNotEmpty
              ? _teacherNameFromPrefs
              : (_classroom['teacherName']?.toString() ?? ''),
          orgId: _classroom['orgId']?.toString() ?? '',
          className: className,
          classSubjects: typedSubjects,
        );
      case 3: // Attendance (Students)
        return ClassroomStudentsTab(
          classId: widget.classId,
          students: students.map((s) => s.toString()).toList(),
          onRefresh: _fetchClassroom,
        );
      case 4: // Notices
        return ClassroomNoticesTab(classId: widget.classId);
      case 5: // Requests
        return ClassroomRequestsTab(classId: widget.classId);
      case 6: // Notes
        return ClassroomNotesTab(classId: widget.classId);
      case 7: // Promotion
        return YearRolloverPage(
          classId: widget.classId,
          className: className,
          orgId: _classroom['orgId']?.toString() ?? '',
          teacherId: _classroom['teacherId']?.toString() ?? '',
        );
      case 8: // Quizzes
        return TeacherQuizListScreen(
          classId: widget.classId,
          className: _classroom['className']?.toString(),
          subjects: _classroom['subjects'] as List?,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Could not load classroom',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 140,
            height: 44,
            child: ElevatedButton(
              onPressed: _fetchClassroom,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
