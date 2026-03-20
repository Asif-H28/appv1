import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import 'create_test_sheet.dart';
import 'edit_test_sheet.dart';
import '../pages/test_results_page.dart';

class ClassroomTestsTab extends StatefulWidget {
  final String classId;
  final String teacherId;
  final String teacherName;
  final String orgId;
  final String className;
  final List<Map<String, dynamic>> classSubjects;

  const ClassroomTestsTab({
    required this.classId,
    required this.teacherId,
    required this.teacherName,
    required this.orgId,
    required this.className,
    required this.classSubjects,
  });

  @override
  _ClassroomTestsTabState createState() => _ClassroomTestsTabState();
}

class _ClassroomTestsTabState extends State<ClassroomTestsTab> {
  static const Color _accent = Colors.teal;
  List<Map<String, dynamic>> _tests = [];
  bool _isLoading = true;
  bool _hasError = false;
  final Map<String, bool> _deletingMap = {};

  @override
  void initState() {
    super.initState();
    _fetchTests();
  }

  Future<void> _fetchTests() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/test/class/${widget.classId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['tests'] is List)
          raw = body['tests'];
        else if (body['data'] is List)
          raw = body['data'];
        setState(() {
          _tests = raw.map((e) => e as Map<String, dynamic>).toList();
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

  Future<void> _deleteTest(String testId) async {
    setState(() => _deletingMap[testId] = true);
    try {
      final response = await http.delete(
        Uri.parse('https://appv1backend.onrender.com/api/test/$testId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _deletingMap.remove(testId);
          _tests.removeWhere((t) => t['testId']?.toString() == testId);
        });
        _snack('Test deleted.', Colors.green[600]!);
      } else {
        setState(() => _deletingMap.remove(testId));
        _snack('Failed to delete test.', Colors.red[600]!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingMap.remove(testId));
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  void _confirmDelete(String testId, String testName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        titlePadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        contentPadding: EdgeInsets.fromLTRB(16, 10, 16, 0),
        actionsPadding: EdgeInsets.fromLTRB(16, 8, 16, 14),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.delete_rounded,
                color: Colors.red[600],
                size: 15,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Delete Test',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Delete "$testName"? This cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: Theme(
                    data: ThemeData(
                      colorScheme: ColorScheme.light(
                        primary: Colors.red[600]!,
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteTest(testId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTestSheet(
        classId: widget.classId,
        teacherId: widget.teacherId,
        teacherName: widget.teacherName,
        orgId: widget.orgId,
        className: widget.className,
        classSubjects: widget.classSubjects,
        onCreated: (newTest) {
          setState(() => _tests.insert(0, newTest));
          _snack('Test created!', Colors.green[600]!);
        },
      ),
    );
  }

  void _openEditSheet(Map<String, dynamic> test) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditTestSheet(
        test: test,
        classSubjects: widget.classSubjects,
        onUpdated: (updated) {
          final idx = _tests.indexWhere(
            (t) => t['testId']?.toString() == updated['testId']?.toString(),
          );
          if (idx != -1) setState(() => _tests[idx] = updated);
          _snack('Test updated!', Colors.green[600]!);
        },
      ),
    );
  }

  void _openResultsPage(Map<String, dynamic> test) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestResultsPage(
          test: test,
          classId: widget.classId,
          orgId: widget.orgId,
          teacherName: widget.teacherName,
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
      );
    if (_hasError) return _buildError();

    return Column(
      children: [
        // ── Action bar ──
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(
            children: [
              // Count chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_rounded, color: _accent, size: 12),
                    SizedBox(width: 5),
                    Text(
                      '${_tests.length} Test${_tests.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              // Refresh
              // Refresh
              SizedBox(
                width: 38,
                height: 38,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.refresh_rounded, color: _accent, size: 16),
                    onPressed: _fetchTests,
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ),
              ),

              SizedBox(width: 8),
              // Create button
              GestureDetector(
                onTap: _openCreateSheet,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 5),
                      Text(
                        'Create Test',
                        style: TextStyle(
                          color: Colors.white,
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

        SizedBox(height: 10),

        // ── Body ──
        _tests.isEmpty
            ? _buildEmpty()
            : Expanded(
                child: RefreshIndicator(
                  color: _accent,
                  onRefresh: _fetchTests,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(14, 4, 14, 40),
                    itemCount: _tests.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8),
                    itemBuilder: (_, i) => _testCard(_tests[i]),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _testCard(Map<String, dynamic> test) {
    final testId = test['testId']?.toString() ?? '';
    final testName = test['testModule']?.toString() ?? 'Unnamed Test';
    final subjects = test['subjects'] as List? ?? [];
    final createdAt = test['createdAt']?.toString() ?? '';
    final isDeleting = _deletingMap[testId] == true;

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──
          Container(
            padding: EdgeInsets.fromLTRB(10, 9, 6, 9),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.04),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(Icons.quiz_rounded, color: _accent, size: 16),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dateStr.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 9,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 3),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (isDeleting)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.red[400],
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconBtn(
                        Icons.edit_outlined,
                        _accent,
                        () => _openEditSheet(test),
                      ),
                      SizedBox(width: 4),
                      _iconBtn(
                        Icons.delete_outline_rounded,
                        Colors.red[400]!,
                        () => _confirmDelete(testId, testName),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Subjects ──
          if (subjects.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 10,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Subjects (${subjects.length})',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 7),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: subjects.map((s) {
                  final sub = s as Map<String, dynamic>;
                  final name = sub['subjectName']?.toString() ?? '';
                  final max = sub['maximumScore']?.toString() ?? '0';
                  final min = sub['minimumScore']?.toString() ?? '0';
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: _accent.withOpacity(0.18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 1),
                        Row(
                          children: [
                            _scoreBadge('Max', max, _accent),
                            SizedBox(width: 4),
                            _scoreBadge('Min', min, Colors.orange[700]!),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // ── Footer: Enter Marks button ──
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                // Test ID badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    testId.length > 12
                        ? '# ${testId.substring(0, 12)}…'
                        : '# $testId',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Spacer(),
                // Enter marks button
                GestureDetector(
                  onTap: () => _openResultsPage(test),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Enter / View Marks',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBadge(String label, String value, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      '$label: $value',
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
    ),
  );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      );

  Widget _buildEmpty() => Expanded(
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _accent.withOpacity(0.08),
              ),
              child: Icon(Icons.quiz_outlined, color: _accent, size: 28),
            ),
            SizedBox(height: 14),
            Text(
              'No Tests Yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Create a test to evaluate\nstudents in this classroom.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            SizedBox(height: 18),
            Theme(
              data: ThemeData(
                colorScheme: ColorScheme.light(
                  primary: _accent,
                  onPrimary: Colors.white,
                ),
              ),
              child: SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: _openCreateSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  icon: Icon(Icons.add_rounded, size: 15, color: Colors.white),
                  label: Text(
                    'Create Test',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'Could not load tests',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Theme(
            data: ThemeData(
              colorScheme: ColorScheme.light(
                primary: _accent,
                onPrimary: Colors.white,
              ),
            ),
            child: SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: _fetchTests,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                icon: Icon(Icons.refresh, size: 14, color: Colors.white),
                label: Text(
                  'Retry',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
