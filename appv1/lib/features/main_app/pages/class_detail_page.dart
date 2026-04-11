import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum DrawerType { subjectDetails, studentResult }

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
  Map<String, dynamic>? _selectedStudentResult;

  // Test and Results State
  List<dynamic> _tests = [];
  Map<String, dynamic>? _selectedTest;
  List<dynamic> _testResults = [];
  bool _isLoadingTests = true;
  bool _isLoadingResults = false;
  String _testError = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
    _fetchTests();
  }

  Future<void> _fetchTests() async {
    setState(() {
      _isLoadingTests = true;
      _testError = '';
    });

    final classId = widget.classData['classId'];
    if (classId == null) {
      if (mounted) {
        setState(() {
          _testError = 'Invalid class ID';
          _isLoadingTests = false;
        });
      }
      return;
    }

    try {
      final url = Uri.parse(
        'https://appv1backend.onrender.com/api/test/class/$classId',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          final tests = data['tests'] as List<dynamic>? ?? [];
          setState(() {
            _tests = tests;
            _isLoadingTests = false;
            if (_tests.isNotEmpty) {
              _selectedTest = _tests.first;
              _fetchResults();
            }
          });
        } else if (mounted) {
          setState(() {
            _testError = 'Failed to load tests';
            _isLoadingTests = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _testError = 'Server Error ${response.statusCode}';
          _isLoadingTests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testError = 'Network error: $e';
          _isLoadingTests = false;
        });
      }
    }
  }

  Future<void> _fetchResults() async {
    if (_selectedTest == null) return;

    setState(() {
      _isLoadingResults = true;
      _testResults = [];
    });

    final testId = _selectedTest!['testId'];
    try {
      final url = Uri.parse(
        'https://appv1backend.onrender.com/api/result/test/$testId',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          final results = data['results'] as List<dynamic>? ?? [];
          results.sort(
            (a, b) =>
                (b['percentage'] as num).compareTo(a['percentage'] as num),
          );
          setState(() {
            _testResults = results;
            _isLoadingResults = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoadingResults = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingResults = false;
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
        'https://appv1backend.onrender.com/api/attendance/class/$classId/week?year=$_selectedYear&month=$_selectedMonth&week=$_selectedWeek',
      );
      final response = await http.get(url);

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
    final studentCount =
        (widget.classData['studentIds'] as List<dynamic>? ?? []).length;

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
              : _buildStudentResultDrawer(context),
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
                // Student count card
                _buildStatCard(
                  icon: Icons.groups_rounded,
                  title: 'Total Students Enrolled',
                  value: '$studentCount',
                ),
                const SizedBox(height: 16),

                // Academic Progress Card
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
                                    _drawerType = DrawerType
                                        .subjectDetails; // ← force reset
                                    _selectedStudentResult =
                                        null; // ← clear any previous result
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

                // Attendance Line Graph Card
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
                      // Header & Filters
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
                              _buildDropdown<int>(
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
                              const SizedBox(width: 6),
                              _buildDropdown<int>(
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
                              const SizedBox(width: 6),
                              _buildDropdown<int>(
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
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Chart or Loading/Error
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
                _buildResultsCard(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3748),
                ),
              ),
              if (!_isLoadingTests && _tests.isNotEmpty)
                Container(
                  height: 36,
                  constraints: const BoxConstraints(maxWidth: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF009688).withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: _selectedTest,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF009688),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                      items: _tests.map<DropdownMenuItem<Map<String, dynamic>>>(
                        (dynamic test) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: test as Map<String, dynamic>,
                            child: Text(
                              test['testModule'] ?? 'Unknown Test',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged: (Map<String, dynamic>? newValue) {
                        setState(() {
                          _selectedTest = newValue;
                        });
                        _fetchResults();
                      },
                    ),
                  ),
                ),
            ],
          ),
          if (_isLoadingTests) ...[
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF009688)),
            ),
          ] else if (_testError.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(_testError, style: const TextStyle(color: Colors.red)),
          ] else if (_tests.isEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'No tests assigned to this class.',
              style: TextStyle(color: Colors.black54),
            ),
          ],

          if (!_isLoadingTests && _tests.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search student...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFA0AEC0),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF718096),
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: const Color(0xFFF7FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF009688)),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ],

          const SizedBox(height: 24),
          // Results Table
          if (_isLoadingResults)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF009688)),
            )
          else if (_testResults.isEmpty && !_isLoadingTests)
            const Center(
              child: Text(
                'No results available for this test.',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            _buildResultsTable(context),
        ],
      ),
    );
  }

  Widget _buildResultsTable(BuildContext context) {
    final displayedResults = _testResults.where((r) {
      final sName = (r['studentName'] ?? '').toString().toLowerCase();
      return sName.contains(_searchQuery.toLowerCase());
    }).toList();

    if (displayedResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No matching student found.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: const [
              Expanded(
                flex: 2,
                child: Text(
                  'Student Name',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF718096),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Marks / Total Marks',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF718096),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        // Table Rows
        ...displayedResults.map((result) {
          final globalRank = _testResults.indexOf(result);
          final studentName = result['studentName'] ?? 'Unknown';
          final scored = result['totalScoredMarks']?.toString() ?? '0';
          final total = result['totalMaximumMarks']?.toString() ?? '0';

          Widget? badge;
          if (globalRank == 0)
            badge = const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 16,
            );
          else if (globalRank == 1)
            badge = const Icon(
              Icons.emoji_events,
              color: Color(0xFFC0C0C0),
              size: 16,
            );
          else if (globalRank == 2)
            badge = const Icon(
              Icons.emoji_events,
              color: Color(0xFFCD7F32),
              size: 16,
            );

          return InkWell(
            onTap: () {
              setState(() {
                _drawerType = DrawerType.studentResult;
                _selectedStudentResult = result;
              });
              Scaffold.of(context).openEndDrawer();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF7FAFC))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        if (badge != null) ...[badge, const SizedBox(width: 8)],
                        Expanded(
                          child: Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2D3748),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '$scored / $total',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3748),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
      constraints: const BoxConstraints(maxWidth: 80),
      padding: const EdgeInsets.only(left: 6, right: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F6),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF009688).withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
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

  Widget _buildStudentResultDrawer(BuildContext context) {
    if (_selectedStudentResult == null) {
      return const Center(child: Text('No student selected'));
    }

    final result = _selectedStudentResult!;
    final studentName = result['studentName'] ?? 'Unknown';
    final percentage = result['percentage']?.toString() ?? '0';
    final grade = result['grade'] ?? '-';
    final overallStatus =
        result['overallStatus']?.toString().toUpperCase() ?? 'N/A';
    final isPass = result['overallStatus'] == 'pass';
    final subjects = result['subjectResults'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF009688),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Student Result',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),
        // Student Header Overview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Percentage',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Grade & Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Grade $grade',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPass
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              overallStatus,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPass ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        // Subject Wise View
        Expanded(
          child: subjects.isEmpty
              ? const Center(
                  child: Text(
                    'No subject results found.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final sub = subjects[index];
                    final sName = sub['subjectName'] ?? 'Subject';
                    final sMarks = sub['scoredMarks']?.toString() ?? '0';
                    final sTotal = sub['maximumScore']?.toString() ?? '0';
                    final sStatus =
                        sub['status']?.toString().toUpperCase() ?? '';
                    final sPass = sub['status'] == 'pass';

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
                              if (sStatus.isNotEmpty)
                                Text(
                                  sStatus,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: sPass ? Colors.green : Colors.red,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$sMarks / $sTotal',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF009688),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
