import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

const Color _accent = Colors.teal;

class StudentTestResultScreen extends StatefulWidget {
  final Map<String, dynamic> test;
  const StudentTestResultScreen({required this.test});

  @override
  _StudentTestResultScreenState createState() => _StudentTestResultScreenState();
}

class _StudentTestResultScreenState extends State<StudentTestResultScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _result;

  String get _testId => widget.test['assessmentId']?.toString() ?? widget.test['_id']?.toString() ?? '';
  String get _title => widget.test['title']?.toString() ?? 'Assessment';

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
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/comprehensive-result/assessment/$_testId'),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['data'] != null)
          raw = body['data'] as List;

        final match = raw
            .cast<Map<String, dynamic>>()
            .where((r) => r['studentId']?.toString() == studentId)
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
                          Icons.assignment_turned_in_rounded,
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
                              _title,
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

  Widget _buildResult() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14, 16, 14, 40),
      child: _resultCard(_result!),
    );
  }

  Widget _resultCard(Map<String, dynamic> result) {
    final scholastic = result['scholasticResults'] as List? ?? [];
    final coScholastic = result['coScholasticResults'] as List? ?? [];
    
    double totalScored = 0;
    double totalMax = 0;
    
    for (final s in scholastic) {
      totalScored += (s['totalMarksScored'] as num?)?.toDouble() ?? 0;
      final subName = s['subjectName']?.toString();
      final assessmentSubjects = widget.test['scholasticSubjects'] as List? ?? [];
      final assessmentSub = assessmentSubjects.firstWhere(
        (as) => as['subjectName'] == subName,
        orElse: () => null,
      );
      if (assessmentSub != null) {
        final internalMax = (assessmentSub['internalMaximumScore'] as num?)?.toDouble() ?? 0;
        final externalMax = (assessmentSub['externalMaximumScore'] as num?)?.toDouble() ?? 0;
        totalMax += (internalMax + externalMax);
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: BorderSide(color: Colors.teal.shade100, width: 1),
      ),
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.04),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              border: Border(bottom: BorderSide(color: Colors.teal.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Icon(Icons.stars_rounded, color: Colors.teal[600], size: 24),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Performance',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal[900]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Total: ${totalScored.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.teal[800]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (scholastic.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 16, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'SCHOLASTIC AREAS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal[700], letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'SUBJECT',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[900], letterSpacing: 0.5),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'MARKS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[900], letterSpacing: 0.5),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'GRADE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[900], letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...scholastic.map((s) {
                          final subName = s['subjectName']?.toString() ?? '';
                          final scored = (s['totalMarksScored'] as num?)?.toDouble() ?? 0;
                          final grade = s['grade']?.toString() ?? '-';
                          
                          final assessmentSubjects = widget.test['scholasticSubjects'] as List? ?? [];
                          final assessmentSub = assessmentSubjects.firstWhere(
                            (as) => as['subjectName'] == subName,
                            orElse: () => null,
                          );
                          double max = 0;
                          if (assessmentSub != null) {
                            final iM = (assessmentSub['internalMaximumScore'] as num?)?.toDouble() ?? 0;
                            final eM = (assessmentSub['externalMaximumScore'] as num?)?.toDouble() ?? 0;
                            max = iM + eM;
                          }

                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    subName,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${scored.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    grade,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal[700]),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Total',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${totalScored.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.teal[900]),
                                ),
                              ),
                              Expanded(child: SizedBox()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (coScholastic.isNotEmpty) ...[
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.palette_rounded, size: 16, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'CO-SCHOLASTIC ACTIVITIES',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal[700], letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'ACTIVITY',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[900], letterSpacing: 0.5),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'GRADE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[900], letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...coScholastic.map((c) {
                          final name = c['activityName']?.toString() ?? '';
                          final grade = c['grade']?.toString() ?? '-';
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    name,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    grade,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal[700]),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Published by ${result['publishedBy'] ?? 'Teacher'}',
                      style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey[500]),
                    ),
                  ],
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
            'Your teacher has not published your result for this assessment yet.',
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
