import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    _fetchClassroom();
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
      final response = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/classroom/${widget.classId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
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
      final response = await http.put(
        Uri.parse(
          'https://appv1backend.onrender.com/api/classroom/${widget.classId}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'className': newName}),
      );
      if (!mounted) return;
      setState(() {
        _isSavingName = false;
        _isEditingName = false;
      });
      if (response.statusCode == 200) {
        setState(() => _classroom['className'] = newName);
        _showSnackBar('Classroom name updated!', Colors.green[600]!);
      } else {
        _showSnackBar('Failed to update name.', Colors.red[600]!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSavingName = false);
      _showSnackBar('No internet connection.', Colors.red[600]!);
    }
  }

  void _showSnackBar(String msg, Color color) {
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
    final className = _classroom['className']?.toString() ?? widget.className;
    final subjects = _classroom['subjects'] as List? ?? [];
    final students = _classroom['students'] as List? ?? [];

    // ── Typed subjects list reused for both SubjectLessonsTab & ClassroomTestsTab ──
    final typedSubjects = subjects
        .map((s) => s as Map<String, dynamic>)
        .toList();

    int totalLessons = 0;
    int completedLessons = 0;
    for (final sub in subjects) {
      final lessons = (sub as Map)['lessons'] as List? ?? [];
      totalLessons += lessons.length;
      completedLessons += lessons
          .where((l) => (l as Map)['completed'] == true)
          .length;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Gradient Header ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    // ── Top bar ──
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
                                    isDense: true,
                                    hintText: 'Class name...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 15,
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
                            _headerIconBtn(Icons.check_rounded, _saveClassName),
                            _headerIconBtn(
                              Icons.close_rounded,
                              () => setState(() => _isEditingName = false),
                            ),
                          ],
                        ] else ...[
                          _headerIconBtn(
                            Icons.edit_outlined,
                            () => setState(() => _isEditingName = true),
                          ),
                          if (!_isLoading)
                            _headerIconBtn(Icons.refresh, _fetchClassroom),
                        ],
                      ],
                    ),
                    SizedBox(height: 12),

                    // ── Stats ──
                    if (!_isLoading && !_hasError)
                      Row(
                        children: [
                          _headerStat(
                            Icons.menu_book_rounded,
                            '${subjects.length}',
                            'Subjects',
                          ),
                          SizedBox(width: 8),
                          _headerStat(
                            Icons.people_rounded,
                            '${students.length}',
                            'Students',
                          ),
                          SizedBox(width: 8),
                          _headerStat(
                            Icons.task_alt_rounded,
                            '$completedLessons/$totalLessons',
                            'Done',
                          ),
                        ],
                      ),
                    SizedBox(height: 12),

                    // ── Smart Tab Bar ──
                    _buildTabBar(),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // ── Tab Content ──
          Expanded(
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
                          students: students.map((s) => s.toString()).toList(),
                          onRefresh: _fetchClassroom,
                        ),
                        ClassroomNoticesTab(classId: widget.classId),
                        ClassroomNotesTab(classId: widget.classId),
                        ClassroomRequestsTab(classId: widget.classId),
                        // ── Tests tab with classSubjects auto-fill ──
                        ClassroomTestsTab(
                          classId: widget.classId,
                          teacherId: _classroom['teacherId']?.toString() ?? '',
                          teacherName:
                              _classroom['teacherName']?.toString() ?? '',
                          orgId: _classroom['orgId']?.toString() ?? '',
                          className: className,
                          classSubjects: typedSubjects, // ← NEW
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: _accent,
        unselectedLabelColor: Colors.white.withOpacity(0.85),
        padding: EdgeInsets.all(3),
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: List.generate(_tabs.length, (i) {
          final isActive = _currentTab == i;
          final icon = _tabs[i]['icon'] as IconData;
          final label = _tabs[i]['label'] as String;

          return AnimatedContainer(
            duration: Duration(milliseconds: 200),
            child: Center(
              child: isActive
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 12),
                        SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Icon(icon, size: 15),
            ),
          );
        }),
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
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

  Widget _headerStat(IconData icon, String value, String label) => Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 15),
          SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 9),
          ),
        ],
      ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: Icon(Icons.refresh, size: 15),
              label: Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
