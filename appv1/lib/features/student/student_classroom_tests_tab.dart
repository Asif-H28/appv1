import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_test_result_screen.dart';

const Color _accent = Colors.teal;

class StudentClassroomTestsTab extends StatefulWidget {
  @override
  _StudentClassroomTestsTabState createState() => _StudentClassroomTestsTabState();
}

class _StudentClassroomTestsTabState extends State<StudentClassroomTestsTab> {
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _tests = [];
  String _orgId = '';
  String _classId = '';

  @override
  void initState() {
    super.initState();
    _fetchTests();
  }

  Future<void> _fetchTests() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final prefs = await SharedPreferences.getInstance();
    _classId = prefs.getString('classId') ?? '';
    _orgId = prefs.getString('orgId') ?? '';

    if (_classId.isEmpty || _orgId.isEmpty) {
      setState(() {
        _error = 'Class or Organization info missing.';
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/comprehensive-assessment/list?orgId=$_orgId&classId=$_classId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['data'] != null)
          raw = body['data'] as List;

        final list = raw.map((e) => e as Map<String, dynamic>).toList();
        list.sort((a, b) {
          final d1 = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(2000);
          final d2 = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(2000);
          return d2.compareTo(d1);
        });

        setState(() {
          _tests = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load assessments.';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoader();
    if (_error.isNotEmpty) return _buildError();
    if (_tests.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: _accent,
      onRefresh: _fetchTests,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(14, 16, 14, 40),
        itemCount: _tests.length,
        separatorBuilder: (_, __) => SizedBox(height: 10),
        itemBuilder: (_, i) => _testCard(_tests[i]),
      ),
    );
  }

  Widget _testCard(Map<String, dynamic> test) {
    final testId = test['assessmentId']?.toString() ?? test['_id']?.toString() ?? '';
    final testName = test['title']?.toString() ?? 'Unnamed Assessment';
    final tName = test['teacherName']?.toString() ?? 'Unknown Teacher';
    final cName = test['className']?.toString() ?? 'Unknown Class';
    final createdAt = test['createdAt']?.toString() ?? '';

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
                  child: Icon(Icons.assignment_turned_in_rounded, color: _accent, size: 16),
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
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 10, color: AppColors.textSecondary),
                          SizedBox(width: 3),
                          Text(tName, style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
                          SizedBox(width: 8),
                          Icon(Icons.class_outlined, size: 10, color: AppColors.textSecondary),
                          SizedBox(width: 3),
                          Text(cName, style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
                        ],
                      ),
                      if (dateStr.isNotEmpty) ...[
                        SizedBox(height: 2),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    testId.length > 12
                        ? '# ${testId.substring(0, 12)}...'
                        : '# $testId',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentTestResultScreen(test: test),
                      ),
                    );
                  },
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
                          Icons.visibility_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'View Result',
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

  Widget _buildLoader() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
        SizedBox(height: 14),
        Text(
          'Loading assessments...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );

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
            onTap: _fetchTests,
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

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.08),
            ),
            child: Icon(Icons.assignment_turned_in_rounded, color: _accent, size: 30),
          ),
          SizedBox(height: 14),
          Text(
            'No Assessments Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your teacher has not created any assessments yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}
