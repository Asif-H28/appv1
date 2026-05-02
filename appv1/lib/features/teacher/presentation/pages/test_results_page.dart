import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/enter_marks_sheet.dart';

class TestResultsPage extends StatefulWidget {
  final Map<String, dynamic> test;
  final String classId;
  final String orgId;
  final String teacherName;

  const TestResultsPage({
    required this.test,
    required this.classId,
    required this.orgId,
    required this.teacherName,
  });

  @override
  _TestResultsPageState createState() => _TestResultsPageState();
}

class _TestResultsPageState extends State<TestResultsPage>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Colors.teal;
  late TabController _tabController;
  int _currentTab = 0;

  String _resolvedTeacherName = '';

  List<Map<String, dynamic>> _students = [];
  bool _loadingStudents = true;

  List<Map<String, dynamic>> _results = [];
  bool _loadingResults = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    _loadTeacherName();
    _fetchStudents();
    _fetchResults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // â”€â”€ Load teacher name from SharedPreferences (key = 'teacherName') â”€â”€
  Future<void> _loadTeacherName() async {
    if (widget.teacherName.isNotEmpty) {
      setState(() => _resolvedTeacherName = widget.teacherName);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('teacherName') ?? '';
    debugPrint('>>> Resolved teacherName from prefs: "$name"');
    if (mounted) setState(() => _resolvedTeacherName = name);
  }

  Future<void> _fetchStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/join/class/${widget.classId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['requests'] is List)
          raw = body['requests'];
        else if (body['data'] is List)
          raw = body['data'];

        final approved = raw
            .map((e) => e as Map<String, dynamic>)
            .where((r) => r['status']?.toString() == 'approved')
            .toList();

        setState(() {
          _students = approved;
          _loadingStudents = false;
        });
      } else {
        setState(() => _loadingStudents = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStudents = false);
    }
  }

  Future<void> _fetchResults() async {
    setState(() => _loadingResults = true);
    try {
      final testId =
          widget.test['testId']?.toString() ??
          widget.test['_id']?.toString() ??
          '';
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/result/test/$testId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['results'] is List)
          raw = body['results'];
        else if (body['data'] is List)
          raw = body['data'];
        setState(() {
          _results = raw.map((e) => e as Map<String, dynamic>).toList();
          _loadingResults = false;
        });
      } else {
        setState(() => _loadingResults = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingResults = false);
    }
  }

  Map<String, dynamic>? _resultForStudent(String studentId) {
    try {
      return _results.firstWhere(
        (r) => r['studentId']?.toString() == studentId,
      );
    } catch (_) {
      return null;
    }
  }

  void _openEnterMarks(Map<String, dynamic> student) {
    final studentId = student['studentId']?.toString() ?? '';
    final existingResult = _resultForStudent(studentId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EnterMarksSheet(
        test: widget.test,
        student: student,
        orgId: widget.orgId,
        teacherName: _resolvedTeacherName,
        existingResult: existingResult,
        onSaved: (result) {
          setState(() {
            final idx = _results.indexWhere(
              (r) => r['studentId']?.toString() == studentId,
            );
            if (idx != -1) {
              _results[idx] = result;
            } else {
              _results.insert(0, result);
            }
          });
          _snack('Marks saved successfully!', Colors.green[600]!);
        },
      ),
    );
  }

  Future<void> _deleteResult(String resultId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.apiBaseUrl}/result/$resultId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(
          () => _results.removeWhere(
            (r) => r['resultId']?.toString() == resultId,
          ),
        );
        _snack('Result deleted.', Colors.red[600]!);
      } else {
        _snack('Failed to delete result.', Colors.red[600]!);
      }
    } catch (e) {
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  void _confirmDeleteResult(String resultId, String studentName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(
                Icons.delete_rounded,
                color: Colors.red[600],
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Result',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
        content: Text(
          'Delete result for $studentName?\nThis cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.5,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteResult(resultId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
    final testName = widget.test['testModule']?.toString() ?? 'Test';
    final subjects = widget.test['subjects'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // â”€â”€ Gradient Header â”€â”€
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
                    // Top bar
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                testName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Results & Marks',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Teacher name badge
                        if (_resolvedTeacherName.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _resolvedTeacherName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            _fetchStudents();
                            _fetchResults();
                          },
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Stats row
                    Row(
                      children: [
                        _statChip(
                          Icons.people_rounded,
                          '${_students.length}',
                          'Students',
                        ),
                        SizedBox(width: 8),
                        _statChip(
                          Icons.subject_rounded,
                          '${subjects.length}',
                          'Subjects',
                        ),
                        SizedBox(width: 8),
                        _statChip(
                          Icons.check_circle_rounded,
                          '${_results.length}',
                          'Marked',
                        ),
                        SizedBox(width: 8),
                        _statChip(
                          Icons.pending_rounded,
                          '${_students.length - _results.length < 0 ? 0 : _students.length - _results.length}',
                          'Pending',
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Tab bar
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
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
                        tabs: [
                          _tab(Icons.edit_note_rounded, 'Enter Marks', 0),
                          _tab(Icons.bar_chart_rounded, 'Results', 1),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // â”€â”€ Body â”€â”€
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              clipBehavior: Clip.antiAlias,
              child: TabBarView(
                controller: _tabController,
                children: [_buildStudentsTab(), _buildResultsTab()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(IconData icon, String label, int idx) {
    final isActive = _currentTab == idx;
    return Tab(
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
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : Icon(icon, size: 15),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) => Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 13),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
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

  // â”€â”€ Tab 1: Students List â”€â”€
  Widget _buildStudentsTab() {
    if (_loadingStudents) {
      return Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
      );
    }
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 52,
              color: Colors.grey[400],
            ),
            SizedBox(height: 12),
            Text(
              'No students in this classroom',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Students need to join the class first',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Progress indicator at top
    final marked = _results.length;
    final total = _students.length;
    final progress = total > 0 ? marked / total : 0.0;

    return Column(
      children: [
        // Progress bar
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Marks Entry Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '$marked / $total',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[100],
                  color: _accent,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey[100], height: 1),
        Expanded(
          child: RefreshIndicator(
            color: _accent,
            onRefresh: _fetchStudents,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 40),
              itemCount: _students.length,
              separatorBuilder: (_, __) =>
                  Divider(color: Colors.grey[100], height: 1, indent: 72),
              itemBuilder: (_, i) => _studentTile(_students[i]),
            ),
          ),
        ),
      ],
    );
  }

  static const List<List<Color>> _gradients = [
    [Color(0xFF00897B), Color(0xFF4DB6AC)],
    [Color(0xFF00796B), Color(0xFF80CBC4)],
    [Color(0xFF26A69A), Color(0xFF80CBC4)],
    [Color(0xFF00ACC1), Color(0xFF4DD0E1)],
    [Color(0xFF0097A7), Color(0xFF80DEEA)],
  ];

  Widget _studentTile(Map<String, dynamic> student) {
    final studentId = student['studentId']?.toString() ?? '';
    final name =
        student['studentName']?.toString() ??
        student['name']?.toString() ??
        'Student';
    final email =
        student['studentEmail']?.toString() ??
        student['email']?.toString() ??
        '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final idx = _students.indexOf(student);
    final gradient = _gradients[idx % _gradients.length];
    final existingResult = _resultForStudent(studentId);
    final hasMarks = existingResult != null;

    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    email.isNotEmpty ? email : studentId,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasMarks) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _gradeColor(
                          existingResult['grade']?.toString() ?? '',
                        ).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(existingResult['percentage'] ?? 0).toStringAsFixed(1)}%  â€¢  ${existingResult['grade'] ?? ''}  â€¢  ${(existingResult['overallStatus'] ?? '').toUpperCase()}',
                        style: TextStyle(
                          color: _gradeColor(
                            existingResult['grade']?.toString() ?? '',
                          ),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Marks / Edit button
            GestureDetector(
              onTap: () => _openEnterMarks(student),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: hasMarks
                      ? Colors.orange.withOpacity(0.08)
                      : _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: hasMarks
                        ? Colors.orange.withOpacity(0.3)
                        : _accent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasMarks ? Icons.edit_rounded : Icons.add_rounded,
                      color: hasMarks ? Colors.orange[700] : _accent,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      hasMarks ? 'Edit' : 'Marks',
                      style: TextStyle(
                        color: hasMarks ? Colors.orange[700] : _accent,
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
      ),
    );
  }

  // â”€â”€ Tab 2: Results â”€â”€
  Widget _buildResultsTab() {
    if (_loadingResults) {
      return Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 52, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(
              'No results published yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Enter marks from the Enter Marks tab',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _fetchResults,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: _results.length,
        separatorBuilder: (_, __) => SizedBox(height: 10),
        itemBuilder: (_, i) => _resultCard(_results[i]),
      ),
    );
  }

  Widget _resultCard(Map<String, dynamic> result) {
    final resultId = result['resultId']?.toString() ?? '';
    final studentName = result['studentName']?.toString() ?? 'Student';
    final percentage = (result['percentage'] ?? 0).toDouble();
    final grade = result['grade']?.toString() ?? '';
    final overallStatus = result['overallStatus']?.toString() ?? '';
    final totalScored = result['totalScoredMarks']?.toString() ?? '0';
    final totalMax = result['totalMaximumMarks']?.toString() ?? '0';
    final subjectResults = result['subjectResults'] as List? ?? [];
    final initial = studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S';
    final idx = _results.indexOf(result);
    final gradient = _gradients[idx % _gradients.length];
    final gradeColor = _gradeColor(grade);
    final isPass = overallStatus.toLowerCase() == 'pass';

    return Container(
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
        border: Border.all(color: gradeColor.withOpacity(0.15)),
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$totalScored / $totalMax marks',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Grade circle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: gradeColor.withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Text(
                          grade,
                          style: TextStyle(
                            color: gradeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isPass ? Colors.green : Colors.red).withOpacity(
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPass ? 'PASS' : 'FAIL',
                        style: TextStyle(
                          color: isPass ? Colors.green[700] : Colors.red[600],
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 8),
                // Edit button
                GestureDetector(
                  onTap: () {
                    // Find the student from _students list
                    final student = _students.firstWhere(
                      (s) =>
                          s['studentId']?.toString() ==
                          result['studentId']?.toString(),
                      orElse: () => {
                        'studentId': result['studentId'],
                        'studentName': result['studentName'],
                      },
                    );
                    _openEnterMarks(student);
                  },
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.25),
                      ),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.orange[700],
                      size: 15,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                // Delete button
                GestureDetector(
                  onTap: () => _confirmDeleteResult(resultId, studentName),
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red[400],
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),
            // Percentage progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[100],
                      color: gradeColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            if (subjectResults.isNotEmpty) ...[
              SizedBox(height: 10),
              Divider(color: Colors.grey[100], height: 1),
              SizedBox(height: 8),
              ...subjectResults.map((s) {
                final sub = s as Map<String, dynamic>;
                final subName = sub['subjectName']?.toString() ?? '';
                final scored = sub['scoredMarks']?.toString() ?? '0';
                final max = sub['maximumScore']?.toString() ?? '0';
                final status = sub['status']?.toString() ?? '';
                final remarks = sub['remarks']?.toString() ?? '';
                final isSubPass = status.toLowerCase() == 'pass';
                return Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        isSubPass
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: isSubPass ? Colors.green[600] : Colors.red[400],
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          subName,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '$scored/$max',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSubPass
                              ? Colors.green[700]
                              : Colors.red[500],
                        ),
                      ),
                      if (remarks.isNotEmpty) ...[
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'â€¢ $remarks',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A+':
        return Colors.green[700]!;
      case 'A':
        return Colors.green[600]!;
      case 'B+':
        return Colors.teal[600]!;
      case 'B':
        return Colors.teal[400]!;
      case 'C':
        return Colors.orange[600]!;
      case 'D':
        return Colors.orange[800]!;
      default:
        return Colors.red[600]!;
    }
  }
}

