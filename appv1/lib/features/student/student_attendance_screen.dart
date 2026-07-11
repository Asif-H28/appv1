import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'student_theme_manager.dart';
import 'student_attendance_summary_card.dart';
import 'student_attendance_records_list.dart';

class StudentAttendanceScreen extends StatefulWidget {
  @override
  _StudentAttendanceScreenState createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  bool _isLoading = true;
  String _error = '';

  int _totalDays = 0;
  int _totalPresent = 0;
  int _totalAbsent = 0;
  double _percentage = 0;
  List<Map<String, dynamic>> _records = [];

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchSummary();
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
        '${ApiConstants.apiBaseUrl}/attendance/summary/$classId/$studentId?month=${_selectedDate.month}&year=${_selectedDate.year}',
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
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        return Scaffold(
          backgroundColor: theme.background,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
            child: Column(
              children: [
                // ── Header ──
                _buildHeader(theme),

                // ── Body ──
                Expanded(
                  child: _isLoading
                      ? _buildLoader(theme)
                      : _error.isNotEmpty
                      ? _buildError(theme)
                      : RefreshIndicator(
                          color: theme.primary,
                          onRefresh: _fetchSummary,
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(14, 16, 14, 40),
                            child: Column(
                              children: [
                                _buildCalendar(theme),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendar(StudentThemeConfig theme) {
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDay = DateTime(year, month, 1);
    final firstWeekday = firstDay.weekday; // 1=Mon, 7=Sun
    final emptyDays = firstWeekday % 7; // Sunday=0, Monday=1, ..., Saturday=6

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final attendanceMap = <int, String>{};
    for (var record in _records) {
      final dateStr = record['date']?.toString() ?? '';
      final dt = DateTime.tryParse(dateStr);
      if (dt != null && dt.year == year && dt.month == month) {
        attendanceMap[dt.day] =
            record['attendance']?.toString().toLowerCase() ?? '';
      }
    }

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month / Year selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: theme.primary),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(year, month - 1);
                    _fetchSummary();
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: theme.primary),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(year, month + 1);
                    _fetchSummary();
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          // Days of week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 8),
          // Grid of days
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: emptyDays + daysInMonth,
            itemBuilder: (context, index) {
              if (index < emptyDays) {
                return SizedBox(); // empty day slot
              }
              final day = index - emptyDays + 1;
              final currentDayDate = DateTime(year, month, day);

              final isFuture = currentDayDate.isAfter(today);
              final status = attendanceMap[day];

              Color bgColor = Colors.transparent;
              Color textColor = theme.textPrimary;

              if (isFuture) {
                textColor = Colors.grey[400]!;
              } else if (status == 'present') {
                bgColor = Colors.green[100]!;
                textColor = Colors.green[800]!;
              } else if (status == 'absent') {
                bgColor = Colors.red[100]!;
                textColor = Colors.red[800]!;
              } else if (currentDayDate == today) {
                bgColor = Colors.blue[50]!;
                textColor = Colors.blue[800]!;
              }

              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────

  Widget _buildHeader(StudentThemeConfig theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.primary.withOpacity(0.75)],
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
          ],
        ),
      ),
    );
  }

  // ── States ────────────────────────────────────────────

  Widget _buildLoader(StudentThemeConfig theme) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: theme.primary, strokeWidth: 2.5),
        SizedBox(height: 14),
        Text(
          'Loading attendance...',
          style: TextStyle(color: theme.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildError(StudentThemeConfig theme) => Center(
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
              color: theme.textPrimary,
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
                color: theme.primary,
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
