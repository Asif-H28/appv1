import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:appv1/features/teacher/presentation/pages/classroom_timetable_tab.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
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

class _ClassroomDetailPageState extends State<ClassroomDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _accent = Colors.teal;

  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic> _classroom = {};
  String _teacherNameFromPrefs = '';

  bool _isEditingName = false;
  final _nameController = TextEditingController();
  bool _isSavingName = false;
  int _currentTab = 0;

  static const _tabs = [
    {'icon': Icons.menu_book_rounded, 'label': 'Subjects'},
    {'icon': Icons.people_rounded, 'label': 'Students'},
    {'icon': Icons.campaign_rounded, 'label': 'Notices'},
    {'icon': Icons.description_rounded, 'label': 'Notes'},
    {'icon': Icons.person_add_rounded, 'label': 'Requests'},
    {'icon': Icons.quiz_rounded, 'label': 'Tests'},
    {'icon': Icons.calendar_month_rounded, 'label': 'Timetable'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging)
        setState(() => _currentTab = _tabController.index);
    });
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
    _tabController.dispose();
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
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/classroom/${widget.classId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['classroom'] ?? body['data'] ?? body;
        setState(() {
          _classroom = data as Map<String, dynamic>;
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
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/classroom/${widget.classId}',
        ),
        headers: {'Content-Type': 'application/json'},
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
    final className = _classroom['className']?.toString() ?? widget.className;
    final subjects = _classroom['subjects'] as List? ?? [];
    final typedSubjects = subjects
        .map((s) => s as Map<String, dynamic>)
        .toList();
    final students = _classroom['students'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
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
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _isEditingName
                              ? TextField(
                                  controller: _nameController,
                                  autofocus: true,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  cursorColor: Colors.white,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    isDense: true,
                                    filled: false,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    hintText: 'Class name...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.45),
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                )
                              : Text(
                                  className,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        if (_isEditingName) ...[
                          if (_isSavingName)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else ...[
                            _iconBtn(Icons.check_rounded, _saveClassName),
                            _iconBtn(
                              Icons.close_rounded,
                              () => setState(() => _isEditingName = false),
                            ),
                          ],
                        ] else ...[
                          _iconBtn(
                            Icons.edit_outlined,
                            () => setState(() => _isEditingName = true),
                          ),
                          if (!_isLoading)
                            _iconBtn(Icons.refresh, _fetchClassroom),
                        ],
                      ],
                    ),
                    SizedBox(height: 14),
                    _buildTabBar(),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: _accent,
                          strokeWidth: 2.5,
                        ),
                      )
                    : _hasError
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          SubjectLessonsTab(
                            classId: widget.classId,
                            subjects: typedSubjects,
                            onRefresh: _fetchClassroom,
                          ),
                          ClassroomStudentsTab(
                            classId: widget.classId,
                            students: students
                                .map((s) => s.toString())
                                .toList(),
                            onRefresh: _fetchClassroom,
                          ),
                          ClassroomNoticesTab(classId: widget.classId),
                          ClassroomNotesTab(classId: widget.classId),
                          ClassroomRequestsTab(classId: widget.classId),
                          ClassroomTestsTab(
                            classId: widget.classId,
                            teacherId:
                                _classroom['teacherId']?.toString() ?? '',
                            teacherName: _teacherNameFromPrefs.isNotEmpty 
                                ? _teacherNameFromPrefs 
                                : (_classroom['teacherName']?.toString() ?? ''),
                            orgId: _classroom['orgId']?.toString() ?? '',
                            className: className,
                            classSubjects: typedSubjects,
                          ),
                          ClassroomTimetableTab(
                            classId: widget.classId,
                            orgId: _classroom['orgId']?.toString() ?? '',
                            teacherId:
                                _classroom['teacherId']?.toString() ?? '',
                            teacherName: _teacherNameFromPrefs.isNotEmpty 
                                ? _teacherNameFromPrefs 
                                : (_classroom['teacherName']?.toString() ?? ''),
                            className: className,
                            classSubjects: typedSubjects,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isActive = _currentTab == i;
          final icon = _tabs[i]['icon'] as IconData;
          final label = _tabs[i]['label'] as String;
          return GestureDetector(
            onTap: () {
              _tabController.animateTo(i);
              setState(() => _currentTab = i);
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 14 : 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.25),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: isActive ? _accent : Colors.white.withOpacity(0.9),
                  ),
                  if (isActive) ...[
                    SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.only(left: 4),
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'Could not load classroom',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Check your connection and try again.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          SizedBox(height: 18),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _fetchClassroom,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              icon: Icon(Icons.refresh, size: 15, color: Colors.white),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
