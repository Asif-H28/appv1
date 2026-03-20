import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import 'create_test_sheet.dart';
import 'edit_test_sheet.dart';
import '../pages/test_results_page.dart'; // ← NEW

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
    } catch (e) {
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
        _snack('Test deleted.', Colors.red[600]!);
      } else {
        setState(() => _deletingMap.remove(testId));
        _snack('Failed to delete test.', Colors.red[600]!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingMap.remove(testId));
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  void _confirmDelete(String testId, String testName) {
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
                'Delete Test',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
        content: Text(
          'Delete "$testName"?\nThis cannot be undone.',
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
              _deleteTest(testId);
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

  // ── Navigate to Results Page ──
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_rounded, color: _accent, size: 13),
                    SizedBox(width: 5),
                    Text(
                      '${_tests.length} Test${_tests.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: _openCreateSheet,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 16),
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
        _tests.isEmpty
            ? _buildEmpty()
            : Expanded(
                child: RefreshIndicator(
                  color: _accent,
                  onRefresh: _fetchTests,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 40),
                    itemCount: _tests.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: _accent.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accent, _accent.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.quiz_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 10,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 3),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (isDeleting)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.red[400],
                      strokeWidth: 2,
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

            if (subjects.isNotEmpty) ...[
              SizedBox(height: 12),
              Divider(color: Colors.grey[100], height: 1),
              SizedBox(height: 10),
              Text(
                'Subjects (${subjects.length})',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: subjects.map((s) {
                  final sub = s as Map<String, dynamic>;
                  final name = sub['subjectName']?.toString() ?? '';
                  final max = sub['maximumScore']?.toString() ?? '0';
                  final min = sub['minimumScore']?.toString() ?? '0';
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _accent.withOpacity(0.2)),
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
                            fontSize: 11.5,
                          ),
                        ),
                        Text(
                          'Max: $max  Min: $min',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            SizedBox(height: 12),
            Divider(color: Colors.grey[100], height: 1),
            SizedBox(height: 10),

            // ── Enter Marks Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openResultsPage(test),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent.withOpacity(0.08),
                  foregroundColor: _accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: _accent.withOpacity(0.3)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
                icon: Icon(Icons.edit_note_rounded, size: 18),
                label: Text(
                  'Enter / View Marks',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),

            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                testId,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 15),
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.08),
              ),
              child: Icon(Icons.quiz_outlined, color: _accent, size: 34),
            ),
            SizedBox(height: 14),
            Text(
              'No Tests Yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
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
            ElevatedButton.icon(
              onPressed: _openCreateSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: Icon(Icons.add_rounded, size: 16),
              label: Text(
                'Create Test',
                style: TextStyle(fontWeight: FontWeight.bold),
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
          Icon(Icons.cloud_off_rounded, size: 46, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'Could not load tests',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchTests,
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
        ],
      ),
    ),
  );
}
