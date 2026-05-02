import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_test_class_stats_screen.dart';

const Color _accent = Colors.teal;

class StudentTestResultScreen extends StatefulWidget {
  final Map<String, dynamic> test;
  const StudentTestResultScreen({required this.test});

  @override
  _StudentTestResultScreenState createState() =>
      _StudentTestResultScreenState();
}

class _StudentTestResultScreenState extends State<StudentTestResultScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _result;

  String get _testId => widget.test['testId']?.toString() ?? '';

  String get _module => widget.test['testModule']?.toString() ?? 'Test';

  @override
  void initState() {
    super.initState();
    _fetchResult();
  }

  Future<void> _fetchResult() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('studentId') ?? '';

    if (studentId.isEmpty) {
      setState(() {
        _error = 'Student ID not found.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Get all results for this student, find the one matching testId
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/result/student/$studentId',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['results'] != null)
          raw = body['results'] as List;
        else if (body['data'] != null)
          raw = body['data'] as List;

        final match = raw
            .cast<Map<String, dynamic>>()
            .where((r) => r['testId']?.toString() == _testId)
            .toList();

        setState(() {
          _result = match.isNotEmpty ? match.first : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load result.';
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

  // â”€â”€ Grade color â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+':
        return Color(0xFF00897B);
      case 'A':
        return Color(0xFF43A047);
      case 'B+':
        return Color(0xFF7CB342);
      case 'B':
        return Color(0xFFC0CA33);
      case 'C':
        return Color(0xFFFFA726);
      case 'D':
        return Color(0xFFFF7043);
      default:
        return Color(0xFFE53935);
    }
  }

  Color _statusColor(String status) =>
      status.toLowerCase() == 'pass' ? Colors.green[600]! : Colors.red[600]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            // â”€â”€ Header â”€â”€
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
                  padding: EdgeInsets.fromLTRB(14, 12, 16, 16),
                  child: Row(
                    children: [
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
                          Icons.quiz_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _module,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'My Result',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // â”€â”€ Class stats button â”€â”€
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StudentTestClassStatsScreen(test: widget.test),
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
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
                                Icons.bar_chart_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Class Stats',
                                style: TextStyle(
                                  color: Colors.white,
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
              ),
            ),

            Expanded(
              child: _isLoading
                  ? _buildLoader()
                  : _error.isNotEmpty
                  ? _buildError()
                  : _result == null
                  ? _buildNoResult()
                  : _buildResult(),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Result view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildResult() {
    final result = _result!;
    final grade = result['grade']?.toString() ?? 'N/A';
    final percentage = (result['percentage'] as num?) ?? 0;
    final overallStatus = result['overallStatus']?.toString() ?? 'N/A';
    final totalScored = (result['totalScoredMarks'] as num?) ?? 0;
    final totalMax = (result['totalMaximumMarks'] as num?) ?? 0;
    final publishedBy = result['publishedBy']?.toString() ?? '';
    final subjectResults = (result['subjectResults'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14, 16, 14, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ Score summary card â”€â”€
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _gradeColor(grade),
                        _gradeColor(grade).withOpacity(0.5),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    children: [
                      // â”€â”€ Grade circle â”€â”€
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _gradeColor(grade).withOpacity(0.1),
                          border: Border.all(
                            color: _gradeColor(grade).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            grade,
                            style: TextStyle(
                              color: _gradeColor(grade),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                    color: AppColors.textPrimary,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      overallStatus,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: _statusColor(
                                        overallStatus,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    overallStatus.toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor(overallStatus),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              '$totalScored / $totalMax marks',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 8),
                            // â”€â”€ Progress bar â”€â”€
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _gradeColor(grade),
                                ),
                              ),
                            ),
                            if (publishedBy.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    size: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'By $publishedBy',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
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
              ],
            ),
          ),
          SizedBox(height: 16),

          // â”€â”€ Subject results section header â”€â”€
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Subject-wise Results',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          // â”€â”€ Subject result cards â”€â”€
          ...subjectResults.map((s) {
            final sub = s as Map<String, dynamic>;
            final name = sub['subjectName']?.toString() ?? '';
            final scored = (sub['scoredMarks'] as num?) ?? 0;
            final max = (sub['maximumScore'] as num?) ?? 0;
            final min = (sub['minimumScore'] as num?) ?? 0;
            final status = sub['status']?.toString() ?? '';
            final remarks = sub['remarks']?.toString() ?? '';
            final pct = max > 0 ? (scored / max) : 0.0;
            final sColor = _statusColor(status);

            return Container(
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: sColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: sColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: sColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        // â”€â”€ Score big â”€â”€
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$scored',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: ' / $max',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(pct * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Pass â‰¥ $min',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct.toDouble(),
                        minHeight: 5,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(sColor),
                      ),
                    ),
                    if (remarks.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                remarks,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // â”€â”€ States â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildLoader() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
        SizedBox(height: 14),
        Text(
          'Loading your result...',
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
            onTap: _fetchResult,
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

  Widget _buildNoResult() => Center(
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
              color: Colors.orange.withOpacity(0.08),
            ),
            child: Icon(
              Icons.hourglass_empty_rounded,
              color: Colors.orange[600],
              size: 30,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Result Not Published',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your teacher has not published your result for this test yet.',
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

