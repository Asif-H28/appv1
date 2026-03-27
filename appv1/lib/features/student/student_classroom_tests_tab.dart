import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_test_card.dart';
import 'student_test_result_screen.dart';

const Color _accent = Colors.teal;

class StudentClassroomTestsTab extends StatefulWidget {
  @override
  _StudentClassroomTestsTabState createState() =>
      _StudentClassroomTestsTabState();
}

class _StudentClassroomTestsTabState extends State<StudentClassroomTestsTab> {
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _tests = [];

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
    final classId = prefs.getString('classId') ?? '';

    if (classId.isEmpty) {
      setState(() {
        _error = 'No classroom assigned.';
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('https://appv1backend.onrender.com/api/test/class/$classId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['tests'] != null)
          raw = body['tests'] as List;
        else if (body['data'] != null)
          raw = body['data'] as List;

        setState(() {
          _tests = raw.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load tests.';
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
        itemBuilder: (_, i) => StudentTestCard(
          test: _tests[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentTestResultScreen(test: _tests[i]),
            ),
          ),
        ),
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
          'Loading tests...',
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
            child: Icon(Icons.quiz_rounded, color: _accent, size: 30),
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
            'Your teacher has not created any tests yet.',
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
