import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

const Color _accent = Colors.teal;

class StudentTestClassStatsScreen extends StatefulWidget {
  final Map<String, dynamic> test;
  const StudentTestClassStatsScreen({required this.test});

  @override
  _StudentTestClassStatsScreenState createState() =>
      _StudentTestClassStatsScreenState();
}

class _StudentTestClassStatsScreenState
    extends State<StudentTestClassStatsScreen> {
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _results = [];

  String get _testId => widget.test['testId']?.toString() ?? '';

  String get _module => widget.test['testModule']?.toString() ?? 'Test';

  @override
  void initState() {
    super.initState();
    _fetchClassResults();
  }

  Future<void> _fetchClassResults() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await http.get(
        Uri.parse('https://appv1backend.onrender.com/api/result/test/$_testId'),
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

        setState(() {
          _results = raw.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load class stats.';
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

  // ── Computed stats ────────────────────────────────────

  int get _totalStudents => _results.length;

  int get _passCount => _results
      .where((r) => r['overallStatus']?.toString().toLowerCase() == 'pass')
      .length;

  int get _failCount => _totalStudents - _passCount;

  double get _avgPercentage {
    if (_results.isEmpty) return 0;
    final sum = _results.fold<double>(
      0,
      (p, r) => p + ((r['percentage'] as num?) ?? 0).toDouble(),
    );
    return sum / _results.length;
  }

  double get _highestPercentage => _results.isEmpty
      ? 0
      : _results
            .map((r) => ((r['percentage'] as num?) ?? 0).toDouble())
            .reduce((a, b) => a > b ? a : b);

  double get _lowestPercentage => _results.isEmpty
      ? 0
      : _results
            .map((r) => ((r['percentage'] as num?) ?? 0).toDouble())
            .reduce((a, b) => a < b ? a : b);

  // ── Grade distribution ────────────────────────────────

  Map<String, int> get _gradeDistribution {
    final map = <String, int>{
      'A+': 0,
      'A': 0,
      'B+': 0,
      'B': 0,
      'C': 0,
      'D': 0,
      'F': 0,
    };
    for (final r in _results) {
      final g = r['grade']?.toString() ?? 'F';
      map[g] = (map[g] ?? 0) + 1;
    }
    return map;
  }

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
            // ── Header ──
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
                          Icons.bar_chart_rounded,
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
                              'Class Statistics',
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
                  : _results.isEmpty
                  ? _buildEmpty()
                  : _buildStats(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final gradeDist = _gradeDistribution;
    final passRate = _totalStudents > 0
        ? (_passCount / _totalStudents * 100)
        : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        14,
        16,
        14,
        40 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Overview stat tiles ──
          Row(
            children: [
              Expanded(
                child: _statTile(
                  'Total',
                  '$_totalStudents',
                  Icons.people_rounded,
                  _accent,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  'Passed',
                  '$_passCount',
                  Icons.check_circle_rounded,
                  Colors.green[600]!,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  'Failed',
                  '$_failCount',
                  Icons.cancel_rounded,
                  Colors.red[600]!,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  'Average',
                  '${_avgPercentage.toStringAsFixed(1)}%',
                  Icons.trending_up_rounded,
                  Colors.blue[600]!,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  'Highest',
                  '${_highestPercentage.toStringAsFixed(1)}%',
                  Icons.emoji_events_rounded,
                  Colors.amber[700]!,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  'Lowest',
                  '${_lowestPercentage.toStringAsFixed(1)}%',
                  Icons.arrow_downward_rounded,
                  Colors.orange[600]!,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // ── Pass vs Fail visual bar ──
          _sectionHeader('Pass / Fail Overview'),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
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
                Row(
                  children: [
                    Expanded(
                      child: _passFailLegend(
                        'Passed',
                        _passCount,
                        Colors.green[600]!,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _passFailLegend(
                        'Failed',
                        _failCount,
                        Colors.red[600]!,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                // ── Stacked bar ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Row(
                    children: [
                      if (_passCount > 0)
                        Expanded(
                          flex: _passCount,
                          child: Container(
                            height: 14,
                            color: Colors.green[600],
                          ),
                        ),
                      if (_failCount > 0)
                        Expanded(
                          flex: _failCount,
                          child: Container(height: 14, color: Colors.red[600]),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    '${passRate.toStringAsFixed(1)}% pass rate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: passRate >= 50
                          ? Colors.green[600]
                          : Colors.red[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // ── Grade distribution ──
          _sectionHeader('Grade Distribution'),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
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
              children: gradeDist.entries.map((e) {
                final grade = e.key;
                final count = e.value;
                final pct = _totalStudents > 0 ? count / _totalStudents : 0.0;
                return Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _gradeColor(grade).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: _gradeColor(grade).withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            grade,
                            style: TextStyle(
                              color: _gradeColor(grade),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: Colors.grey[100],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _gradeColor(grade),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '$count student${count != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16),

          // ── Subject averages ──
          _buildSubjectAverages(),
        ],
      ),
    );
  }

  // ── Subject averages ──────────────────────────────────

  Widget _buildSubjectAverages() {
    // Collect per-subject averages
    final subMap = <String, List<double>>{};
    for (final r in _results) {
      final subs = (r['subjectResults'] as List<dynamic>?) ?? [];
      for (final s in subs) {
        final sub = s as Map<String, dynamic>;
        final name = sub['subjectName']?.toString() ?? '';
        final scored = ((sub['scoredMarks'] as num?) ?? 0).toDouble();
        final max = ((sub['maximumScore'] as num?) ?? 1).toDouble();
        if (name.isNotEmpty && max > 0) {
          subMap.putIfAbsent(name, () => []);
          subMap[name]!.add(scored / max * 100);
        }
      }
    }
    if (subMap.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Subject Averages'),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
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
            children: subMap.entries.map((e) {
              final name = e.key;
              final avg = e.value.reduce((a, b) => a + b) / e.value.length;
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${avg.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: avg >= 40
                                ? Colors.green[600]
                                : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: avg / 100,
                        minHeight: 7,
                        backgroundColor: Colors.grey[100],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          avg >= 40 ? Colors.green[600]! : Colors.red[600]!,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Small helpers ─────────────────────────────────────

  Widget _sectionHeader(String title) => Row(
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
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
      ),
    ],
  );

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _passFailLegend(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLoader() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
        SizedBox(height: 14),
        Text(
          'Loading class stats...',
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
            onTap: _fetchClassResults,
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
              color: Colors.orange.withOpacity(0.08),
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              color: Colors.orange[600],
              size: 30,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'No Results Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'No results have been published for this test yet.',
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
