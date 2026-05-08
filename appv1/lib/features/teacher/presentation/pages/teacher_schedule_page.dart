import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

const Color _sAccent = Colors.teal;

class TeacherSchedulePage extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherSchedulePage({
    required this.teacherId,
    required this.teacherName,
  });

  @override
  _TeacherSchedulePageState createState() => _TeacherSchedulePageState();
}

class _TeacherSchedulePageState extends State<TeacherSchedulePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;

  Map<String, List<Map<String, dynamic>>> _schedule = {};
  late TabController _tabCtrl;
  int _totalPeriods = 0;

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    final todayIdx = _todayTabIndex();
    _tabCtrl = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: todayIdx,
    );
    _fetchSchedule();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  int _todayTabIndex() {
    const map = {
      'Monday': 0,
      'Tuesday': 1,
      'Wednesday': 2,
      'Thursday': 3,
      'Friday': 4,
      'Saturday': 5,
    };
    return map[_todayKey()] ?? 0;
  }

  String _todayKey() {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[DateTime.now().weekday];
  }

  // ── Fetch full week schedule ───────────────────────

  Future<void> _fetchSchedule() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/timetable/teacher/${widget.teacherId}',
        ),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      debugPrint('[Schedule] ${res.statusCode}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = body['schedule'] as Map<String, dynamic>? ?? {};

        int total = 0;
        final parsed = <String, List<Map<String, dynamic>>>{};

        for (final day in _days) {
          final list = (raw[day] ?? []) as List<dynamic>;
          final slots = list.map((e) => e as Map<String, dynamic>).toList()
            ..sort((a, b) => _periodNum(a).compareTo(_periodNum(b)));
          parsed[day] = slots;
          total += slots.length;
        }

        setState(() {
          _schedule = parsed;
          _totalPeriods = total;
          _isLoading = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _schedule = {for (final d in _days) d: []};
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Schedule] error: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────

  int _periodNum(Map<String, dynamic> s) => s['periodNumber'] is int
      ? s['periodNumber'] as int
      : int.tryParse(s['periodNumber']?.toString() ?? '') ?? 0;

  bool _isCurrentPeriod(Map<String, dynamic> slot, String day) {
    if (day != _todayKey()) return false;
    final now = TimeOfDay.now();
    final start = _parseTime(slot['startTime']?.toString() ?? '');
    final end = _parseTime(slot['endTime']?.toString() ?? '');
    if (start == null || end == null) return false;
    final nowM = now.hour * 60 + now.minute;
    final startM = start.hour * 60 + start.minute;
    final endM = end.hour * 60 + end.minute;
    return nowM >= startM && nowM < endM;
  }

  TimeOfDay? _parseTime(String t) {
    try {
      final p = t.split(':');
      return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    } catch (_) {
      return null;
    }
  }

  String _duration(String start, String end) {
    final s = _parseTime(start);
    final e = _parseTime(end);
    if (s == null || e == null) return '';
    final mins = (e.hour * 60 + e.minute) - (s.hour * 60 + s.minute);
    if (mins <= 0) return '';
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  Color _subjectColor(String? subject) {
    if (subject == null) return Colors.teal;
    final s = subject.toLowerCase();
    if (s.contains('math')) return Colors.blue[600]!;
    if (s.contains('science') ||
        s.contains('physics') ||
        s.contains('chem') ||
        s.contains('bio'))
      return Colors.purple[500]!;
    if (s.contains('english') || s.contains('lang')) return Colors.green[600]!;
    if (s.contains('history') || s.contains('social'))
      return Colors.orange[600]!;
    if (s.contains('geo')) return Colors.teal[600]!;
    if (s.contains('art')) return Colors.pink[400]!;
    if (s.contains('pt') || s.contains('sport')) return Colors.red[400]!;
    if (s.contains('lab')) return Colors.indigo[500]!;
    return Colors.teal[600]!;
  }

  // ── Build ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          if (!_isLoading && !_hasError) _buildDayTabBar(),
          Expanded(
            child: _isLoading
                ? _buildLoader()
                : _hasError
                ? _buildError()
                : TabBarView(
                    controller: _tabCtrl,
                    children: _days.map((d) => _buildDayTab(d)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_sAccent, _sAccent.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Schedule',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.teacherName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _fetchSchedule,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isLoading && !_hasError) ...[
                SizedBox(height: 14),
                _buildWeekSummary(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekSummary() {
    return Row(
      children: _days.map((d) {
        final count = (_schedule[d] ?? []).length;
        final isToday = d == _todayKey();
        return Expanded(
          child: GestureDetector(
            onTap: () {
              final idx = _days.indexOf(d);
              _tabCtrl.animateTo(idx);
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              padding: EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isToday ? Colors.white : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    d.substring(0, 3),
                    style: TextStyle(
                      color: isToday ? _sAccent : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: isToday ? _sAccent : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Day tab bar ────────────────────────────────────

  Widget _buildDayTabBar() {
    return Container(
      color: _sAccent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(0)),
        ),
        child: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: _sAccent, width: 2.5),
            insets: EdgeInsets.symmetric(horizontal: 12),
          ),
          labelColor: _sAccent,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12.5,
          ),
          padding: EdgeInsets.zero,
          dividerColor: Colors.grey[200],
          tabs: _days.map((d) {
            final count = (_schedule[d] ?? []).length;
            final isToday = d == _todayKey();
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(d.substring(0, 3)),
                  if (isToday) ...[
                    SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _sAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ] else if (count > 0) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _sAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 9,
                          color: _sAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Day tab content ────────────────────────────────

  Widget _buildDayTab(String day) {
    final slots = _schedule[day] ?? [];
    if (slots.isEmpty) return _buildEmptyDay(day);

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: slots.length,
      separatorBuilder: (_, __) => Padding(
        padding: EdgeInsets.only(left: 24),
        child: Container(height: 12, width: 2, color: Colors.grey[200]),
      ),
      itemBuilder: (_, i) => _periodCard(slots[i], day),
    );
  }

  Widget _periodCard(Map<String, dynamic> slot, String day) {
    final subject = slot['subjectName']?.toString() ?? '';
    final className = slot['className']?.toString() ?? '';
    final classId = slot['classId']?.toString() ?? '';
    final start = slot['startTime']?.toString() ?? '';
    final end = slot['endTime']?.toString() ?? '';
    final pNum = _periodNum(slot);
    final color = _subjectColor(subject);
    final isCurr = _isCurrentPeriod(slot, day);
    final dur = _duration(start, end);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurr ? color.withOpacity(0.5) : Colors.grey[200]!,
          width: isCurr ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurr
                ? color.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: isCurr ? 12 : 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent + period num
            Container(
              width: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                border: Border(
                  right: BorderSide(color: color.withOpacity(0.15)),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'P$pNum',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isCurr) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'NOW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time + duration
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '$start – $end',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (dur.isNotEmpty) ...[
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              dur,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 5),

                    // Subject name
                    Text(
                      subject.isNotEmpty ? subject : 'Period $pNum',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),

                    // Class name + id
                    Row(
                      children: [
                        Icon(
                          Icons.class_rounded,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          className,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (classId.isNotEmpty) ...[
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              classId,
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Right color strip
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color.withOpacity(0.4),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDay(String day) {
    final isToday = day == _todayKey();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? Colors.teal[50] : Colors.grey[100],
            ),
            child: Icon(
              isToday ? Icons.celebration_rounded : Icons.event_busy_rounded,
              size: 30,
              color: isToday ? Colors.teal[400] : Colors.grey[350],
            ),
          ),
          SizedBox(height: 12),
          Text(
            isToday ? 'No classes today! 🎉' : 'No classes on $day',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            isToday ? 'Enjoy your free day!' : 'Free day',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() => Center(
    child: CircularProgressIndicator(color: _sAccent, strokeWidth: 2.5),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_rounded, size: 44, color: Colors.grey[400]),
        SizedBox(height: 12),
        Text(
          'Failed to load schedule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: _fetchSchedule,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _sAccent,
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
  );
}

