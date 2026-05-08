import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_header.dart';
import 'student_attendance_summary_card.dart';
import 'student_attendance_chart.dart';
import 'student_attendance_records_list.dart';

const Color _accent = Colors.teal;

class StudentAttendanceScreen extends StatefulWidget {
  @override
  _StudentAttendanceScreenState createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String _error = '';

  int _totalDays = 0;
  int _totalPresent = 0;
  int _totalAbsent = 0;
  double _percentage = 0;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final classId = prefs.getString('classId') ?? '';
    final studentId = prefs.getString('studentId') ?? '';

    if (classId.isEmpty || studentId.isEmpty) {
      setState(() {
        _error = 'Student or class ID not found.';
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/attendance/summary/$classId/$studentId',
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        final rawRecords = (body['records'] as List<dynamic>?) ?? [];
        final records =
            rawRecords.map((e) => e as Map<String, dynamic>).toList()
              ..sort((a, b) {
                final da =
                    DateTime.tryParse(a['date']?.toString() ?? '') ??
                    DateTime(2000);
                final db =
                    DateTime.tryParse(b['date']?.toString() ?? '') ??
                    DateTime(2000);
                return db.compareTo(da);
              });

        final pctRaw =
            body['attendancePercentage']?.toString().replaceAll('%', '') ?? '0';

        setState(() {
          _totalDays = (body['totalDays'] as num? ?? 0).toInt();
          _totalPresent = (body['totalPresent'] as num? ?? 0).toInt();
          _totalAbsent = (body['totalAbsent'] as num? ?? 0).toInt();
          _percentage = double.tryParse(pctRaw) ?? 0;
          _records = records;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load attendance.';
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

  Color get _statusColor {
    if (_percentage >= 75) return Colors.green[600]!;
    if (_percentage >= 50) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  String get _statusLabel {
    if (_percentage >= 75) return 'Good Standing';
    if (_percentage >= 50) return 'Needs Attention';
    return 'Critical';
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
            // ── Header with embedded tab bar ──
            _buildHeader(),

            // ── Body ──
            Expanded(
              child: _isLoading
                  ? _buildLoader()
                  : _error.isNotEmpty
                  ? _buildError()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // ── Tab 1: Daily Records ──
                        RefreshIndicator(
                          color: _accent,
                          onRefresh: _fetchSummary,
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(14, 16, 14, 40),
                            child: Column(
                              children: [
                                StudentAttendanceSummaryCard(
                                  totalDays: _totalDays,
                                  totalPresent: _totalPresent,
                                  totalAbsent: _totalAbsent,
                                  percentage: _percentage,
                                  statusColor: _statusColor,
                                  statusLabel: _statusLabel,
                                ),
                                SizedBox(height: 16),
                                StudentAttendanceRecordsList(records: _records),
                              ],
                            ),
                          ),
                        ),

                        // ── Tab 2: Insights ──
                        RefreshIndicator(
                          color: _accent,
                          onRefresh: _fetchSummary,
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(14, 16, 14, 40),
                            child: StudentAttendanceChart(
                              totalPresent: _totalPresent,
                              totalAbsent: _totalAbsent,
                              percentage: _percentage,
                              statusColor: _statusColor,
                              records: _records,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, _accent.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Title row ──
            Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 16, 12),
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
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.fact_check_rounded,
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
                          'My Attendance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isLoading && _error.isEmpty)
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
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
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _percentage >= 75
                                            ? Colors.greenAccent
                                            : _percentage >= 50
                                            ? Colors.orange[300]
                                            : Colors.red[300],
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      '${_percentage.toStringAsFixed(1)}%  •  $_statusLabel',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab bar ──
            Container(
              margin: EdgeInsets.fromLTRB(14, 0, 14, 12),
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: _accent,
                unselectedLabelColor: Colors.white.withOpacity(0.85),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                padding: EdgeInsets.all(3),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt_rounded, size: 14),
                        SizedBox(width: 5),
                        Text('Daily Records'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.insights_rounded, size: 14),
                        SizedBox(width: 5),
                        Text('Insights'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── States ────────────────────────────────────────────

  Widget _buildLoader() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
        SizedBox(height: 14),
        Text(
          'Loading attendance...',
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
            onTap: _fetchSummary,
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
}

