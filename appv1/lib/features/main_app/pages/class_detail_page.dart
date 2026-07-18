import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/features/teacher/presentation/pages/assessment_results_page.dart';
import 'package:appv1/features/learning_resources/screens/learning_resources_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'class_students_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum DrawerType { none, subjectDetails }

class ClassDetailPage extends StatefulWidget {
  final Map<String, dynamic> classData;

  const ClassDetailPage({super.key, required this.classData});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _selectedWeek = 1;

  bool _isLoadingChart = true;
  String _chartError = '';
  List<dynamic> _dailyData = [];

  final List<int> _years = [2024, 2025, 2026, 2027];
  final List<int> _months = List.generate(12, (i) => i + 1);
  final List<int> _weeks = [1, 2, 3, 4, 5];

  // Drawer state
  DrawerType _drawerType = DrawerType.subjectDetails;

  // Assessments State
  List<dynamic> _assessments = [];
  bool _isLoadingAssessments = true;
  String _assessmentError = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
    _fetchAssessments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAssessments() async {
    setState(() {
      _isLoadingAssessments = true;
      _assessmentError = '';
    });

    final classId = widget.classData['classId'];
    if (classId == null) {
      if (mounted) {
        setState(() {
          _assessmentError = 'Invalid class ID';
          _isLoadingAssessments = false;
        });
      }
      return;
    }

    final result = await ApiService.fetchAssessmentsByClass(classId);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _assessments = result['data']?['assessments'] ?? [];
          _isLoadingAssessments = false;
        });
      } else {
        setState(() {
          _assessmentError = result['message'] ?? 'Failed to load assessments';
          _isLoadingAssessments = false;
        });
      }
    }
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      _isLoadingChart = true;
      _chartError = '';
    });

    final classId = widget.classData['classId'];
    if (classId == null) {
      if (mounted) {
        setState(() {
          _chartError = 'Invalid class ID';
          _isLoadingChart = false;
        });
      }
      return;
    }

    try {
      final url = Uri.parse(
        '${ApiConstants.apiBaseUrl}/attendance/class/$classId/week?year=$_selectedYear&month=$_selectedMonth&week=$_selectedWeek',
      );
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _dailyData = data['dailyData'] ?? [];
            _isLoadingChart = false;
          });
        } else if (mounted) {
          setState(() {
            _chartError = 'Failed to load data';
            _isLoadingChart = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _chartError = 'Server Error ${response.statusCode}';
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chartError = 'Network error: $e';
          _isLoadingChart = false;
        });
      }
    }
  }

  double get _maxY {
    double maxStudents = 0;
    for (var day in _dailyData) {
      if (day['totalStudents'] != null) {
        final count = (day['totalStudents'] as num).toDouble();
        if (count > maxStudents) maxStudents = count;
      }
    }
    if (maxStudents == 0) return 25; // Default if nothing marked
    return maxStudents;
  }

  double get _yInterval {
    double maxY = _maxY;
    if (maxY <= 10) return 2;
    if (maxY <= 25) return 5;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 250) return 50;
    return 100;
  }

  List<FlSpot> get _chartSpots {
    List<FlSpot> spots = [];
    for (int i = 0; i < _dailyData.length; i++) {
      final dayData = _dailyData[i];
      double present = 0;
      if (dayData['marked'] == true && dayData['totalPresent'] != null) {
        present = (dayData['totalPresent'] as num).toDouble();
      }
      spots.add(FlSpot(i.toDouble(), present));
    }
    return spots;
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    int index = value.toInt();
    if (index < 0 || index >= _dailyData.length) {
      return SideTitleWidget(meta: meta, space: 4, child: const SizedBox());
    }

    final data = _dailyData[index];
    final dayText = data['day']?.toString() ?? '';
    String dateText = '';

    if (data['date'] != null) {
      try {
        final dt = DateTime.parse(data['date'].toString());
        dateText = '${dt.day}/${dt.month}';
      } catch (_) {
        dateText = data['date'].toString();
        if (dateText.length >= 10 && dateText.contains('-')) {
          dateText = '${dateText.substring(8, 10)}/${dateText.substring(5, 7)}';
        }
      }
    }

    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayText,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (dateText.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              dateText,
              style: const TextStyle(fontSize: 9, color: Color(0xFF718096)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    // Only show integer labels
    if (value != value.toInt()) {
      return Container();
    }
    return Text(
      value.toInt().toString(),
      style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
      textAlign: TextAlign.right,
    );
  }

  @override
  Widget build(BuildContext context) {
    final className = widget.classData['className'] ?? 'Unknown Class';
    final teacherName = widget.classData['teacherName']?.toString() ?? '';
    final studentCount = (widget.classData['students'] as List<dynamic>? ??
            widget.classData['studentIds'] as List<dynamic>? ??
            [])
        .length;

    int totalLessons = 0;
    int completedLessons = 0;
    final subjects = widget.classData['subjects'] as List<dynamic>? ?? [];
    for (var subject in subjects) {
      final lessons = subject['lessons'] as List<dynamic>? ?? [];
      totalLessons += lessons.length;
      for (var lesson in lessons) {
        if (lesson['completed'] == true) {
          completedLessons++;
        }
      }
    }

    double progress = totalLessons == 0 ? 0.0 : completedLessons / totalLessons;
    int percentage = (progress * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F6),
      appBar: AppBar(
        title: Text(
          className,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF009688),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 1.0,
        backgroundColor: const Color(0xFFF0F7F6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(3),
            bottomLeft: Radius.circular(3),
          ),
        ),
        child: SafeArea(
          child: _drawerType == DrawerType.subjectDetails
              ? _buildSubjectDetailsDrawer(subjects)
              : const Center(child: Text('Coming soon')),
        ),
      ),
      body: Builder(
        builder: (context) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (teacherName.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009688).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF009688).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_rounded, size: 14, color: Color(0xFF009688)),
                        const SizedBox(width: 6),
                        Text(
                          'Teacher: $teacherName',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF009688),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildStatCard(
                  icon: Icons.groups_rounded,
                  title: 'Total Students Enrolled',
                  value: '$studentCount',
                  action: studentCount > 0
                      ? TextButton(
                          onPressed: () {
                            final students = widget.classData['students'] as List<dynamic>? ?? [];
                            final className = widget.classData['className'] ?? 'Class';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassStudentsPage(
                                  students: students,
                                  className: className,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF009688),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('View Students', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: const Color(0xFF009688).withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF009688).withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: totalLessons == 0 ? 0.0 : progress,
                              strokeWidth: 8,
                              backgroundColor: const Color(
                                0xFF009688,
                              ).withOpacity(0.1),
                              color: const Color(0xFF009688),
                            ),
                            Center(
                              child: Text(
                                totalLessons == 0 ? 'N/A' : '$percentage%',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Academic Progress',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              totalLessons == 0
                                  ? 'No lessons added yet.'
                                  : '$completedLessons out of $totalLessons lessons completed across all subjects.',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF718096),
                                height: 1.4,
                              ),
                            ),
                            if (subjects.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _drawerType = DrawerType.subjectDetails;
                                  });
                                  Scaffold.of(context).openEndDrawer();
                                },
                                child: const Row(
                                  children: [
                                    Text(
                                      'View Details',
                                      style: TextStyle(
                                        color: Color(0xFF009688),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: Color(0xFF009688),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: const Color(0xFF009688).withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF009688).withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weekly Attendance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown<int>(
                                  value: _selectedYear,
                                  items: _years,
                                  label: 'Y',
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedYear = v);
                                      _fetchAttendanceData();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildDropdown<int>(
                                  value: _selectedMonth,
                                  items: _months,
                                  label: 'M',
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedMonth = v);
                                      _fetchAttendanceData();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildDropdown<int>(
                                  value: _selectedWeek,
                                  items: _weeks,
                                  label: 'W',
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedWeek = v);
                                      _fetchAttendanceData();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_isLoadingChart)
                        const SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF009688),
                            ),
                          ),
                        )
                      else if (_chartError.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              _chartError,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      else if (_dailyData.isEmpty)
                        const SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              'No attendance data found.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        )
                      else
                        AspectRatio(
                          aspectRatio: 1.5,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                getDrawingHorizontalLine: (value) =>
                                    const FlLine(
                                      color: Color(0xFFE2E8F0),
                                      strokeWidth: 1,
                                    ),
                                getDrawingVerticalLine: (value) => const FlLine(
                                  color: Color(0xFFE2E8F0),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 44,
                                    getTitlesWidget: _bottomTitleWidgets,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: _yInterval,
                                    getTitlesWidget: _leftTitleWidgets,
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: const Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFE2E8F0),
                                    width: 1.5,
                                  ),
                                  left: BorderSide(
                                    color: Color(0xFFE2E8F0),
                                    width: 1.5,
                                  ),
                                  right: BorderSide.none,
                                  top: BorderSide.none,
                                ),
                              ),
                              minX: 0,
                              maxX: (_dailyData.length - 1).toDouble() > 0
                                  ? (_dailyData.length - 1).toDouble()
                                  : 6,
                              minY: 0,
                              maxY: _maxY,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _chartSpots,
                                  isCurved: false,
                                  color: const Color(0xFF009688),
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 4,
                                            color: const Color(0xFF009688),
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          );
                                        },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: const Color(
                                      0xFF009688,
                                    ).withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildAssessmentsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssessmentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF009688), size: 20),
            const SizedBox(width: 8),
            Text(
              'Assessments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingAssessments)
          const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
        else if (_assessmentError.isNotEmpty)
          _buildError(_assessmentError)
        else if (_assessments.isEmpty)
          _buildEmptyAssessments()
        else
          ..._assessments.map((a) => _buildAssessmentCard(a)).toList(),
      ],
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> assessment) {
    final date = assessment['createdAt'] != null 
        ? DateTime.parse(assessment['createdAt']).toLocal() 
        : DateTime.now();
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = "${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assessment['title'] ?? 'Untitled Assessment',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF009688)),
              const SizedBox(width: 8),
              Text(
                'Created by: ${assessment['teacherName'] ?? 'Unknown'}',
                style: const TextStyle(color: Color(0xFF009688), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF009688)),
              const SizedBox(width: 8),
              Text(
                'Created on: $dateStr',
                style: const TextStyle(color: Color(0xFF009688), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssessmentResultsPage(
                      assessmentId: assessment['assessmentId'] ?? '',
                      assessmentTitle: assessment['title'] ?? 'Assessment Results',
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF009688), width: 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Results',
                    style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF009688)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAssessments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No assessments found',
            style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF009688).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF009688).withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF009688).withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(icon, color: const Color(0xFF009688), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3748),
                        height: 1,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(width: 12),
                      action,
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String label,
    required void Function(T?) onChanged,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.only(left: 6, right: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F6),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF009688).withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isDense: true,
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF009688),
            size: 16,
          ),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
          onChanged: onChanged,
          items: items.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(
                '$label $e',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubjectDetailsDrawer(List<dynamic> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          color: const Color(0xFF009688),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Subject Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Close',
              ),
            ],
          ),
        ),
        Expanded(
          child: subjects.isEmpty
              ? const Center(
                  child: Text(
                    'No subjects assigned.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: subjects.map((s) {
                    final sName = s['name'] ?? 'Unknown Subject';
                    final sLessons = s['lessons'] as List<dynamic>? ?? [];
                    final sTotal = sLessons.length;
                    final sCompleted = sLessons
                        .where((l) => l['completed'] == true)
                        .length;
                    final sProgress = sTotal == 0 ? 0.0 : sCompleted / sTotal;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: const Color(0xFF009688).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              Text(
                                '$sCompleted / $sTotal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFF009688),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: sProgress,
                              minHeight: 6,
                              backgroundColor: const Color(
                                0xFF009688,
                              ).withOpacity(0.1),
                              color: const Color(0xFF009688),
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
}
