import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'student_period_card.dart';
import 'student_theme_manager.dart';

class StudentTimetablePage extends StatefulWidget {
  final String classId;
  final String className;

  const StudentTimetablePage({required this.classId, required this.className});

  @override
  _StudentTimetablePageState createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<StudentTimetablePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;

  Map<String, List<Map<String, dynamic>>> _timetable = {};
  String _academicYear = '';
  String _createdByName = '';

  late TabController _tabCtrl;

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
    _tabCtrl = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: _todayIndex(),
    );
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchTimetable();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  int _todayIndex() {
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

  // ── Fetch full week ────────────────────────────────

  Future<void> _fetchTimetable() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/timetable/class/${widget.classId}',
      );
      if (!mounted) return;
      debugPrint('[StudentTimetable] ${res.statusCode}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _academicYear = body['academicYear']?.toString() ?? '';
        _createdByName = body['createdByName']?.toString() ?? '';

        final raw = body['timetable'] as Map<String, dynamic>? ?? {};
        final parsed = <String, List<Map<String, dynamic>>>{};

        for (final day in _days) {
          final list = (raw[day] ?? []) as List<dynamic>;
          parsed[day] = list.map((e) => e as Map<String, dynamic>).toList()
            ..sort((a, b) => _periodNum(a).compareTo(_periodNum(b)));
        }

        setState(() {
          _timetable = parsed;
          _isLoading = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _timetable = {for (final d in _days) d: []};
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[StudentTimetable] error: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  int _periodNum(Map<String, dynamic> s) => s['periodNumber'] is int
      ? s['periodNumber'] as int
      : int.tryParse(s['periodNumber']?.toString() ?? '') ?? 0;

  // ── Build ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              _buildHeader(theme),
              if (!_isLoading && !_hasError) _buildTabBar(theme),
              Expanded(
                child: _isLoading
                    ? _buildLoader(theme)
                    : _hasError
                    ? _buildError(theme)
                    : TabBarView(
                        controller: _tabCtrl,
                        children: _days
                            .map((d) => _buildDayTab(d, theme))
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────

  Widget _buildHeader(StudentThemeConfig theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
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
                          'Timetable',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.className,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _fetchTimetable,
                    child: Container(
                      padding: EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
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

              // Week summary strip
              if (!_isLoading && !_hasError) ...[
                SizedBox(height: 12),
                Row(
                  children: _days.map((d) {
                    final count = (_timetable[d] ?? []).length;
                    final isSelected = _days.indexOf(d) == _tabCtrl.index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _tabCtrl.animateTo(_days.indexOf(d)),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          padding: EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Column(
                            children: [
                              Text(
                                d.substring(0, 3),
                                style: TextStyle(
                                  color: isSelected
                                      ? theme.primary
                                      : Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '$count',
                                style: TextStyle(
                                  color: isSelected
                                      ? theme.primary
                                      : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Academic year + teacher info
              if (_academicYear.isNotEmpty || _createdByName.isNotEmpty) ...[
                SizedBox(height: 10),
                Row(
                  children: [
                    if (_academicYear.isNotEmpty) ...[
                      Icon(
                        Icons.school_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 11,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _academicYear,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (_createdByName.isNotEmpty) ...[
                      SizedBox(width: 12),
                      Icon(
                        Icons.person_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 11,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _createdByName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────

  Widget _buildTabBar(StudentThemeConfig theme) {
    return Container(
      color: theme.background,
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: theme.primary, width: 2.5),
          insets: EdgeInsets.symmetric(horizontal: 12),
        ),
        labelColor: theme.primary,
        unselectedLabelColor: theme.textSecondary,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
        unselectedLabelStyle: TextStyle(fontSize: 12.5),
        dividerColor: theme.dividerColor,
        padding: EdgeInsets.zero,
        tabs: _days.map((d) {
          final count = (_timetable[d] ?? []).length;
          final isSelected = _days.indexOf(d) == _tabCtrl.index;
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(d.substring(0, 3)),
                if (isSelected) ...[
                  SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ] else if (count > 0) ...[
                  SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 9,
                        color: theme.primary,
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
    );
  }

  // ── Day tab content ────────────────────────────────

  Widget _buildDayTab(String day, StudentThemeConfig theme) {
    final slots = _timetable[day] ?? [];
    if (slots.isEmpty) return _buildEmptyDay(day, theme);

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        14,
        14,
        14,
        40 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: slots.length,
      separatorBuilder: (_, __) => Padding(
        padding: EdgeInsets.only(left: 20),
        child: Container(height: 10, width: 2, color: theme.dividerColor),
      ),
      itemBuilder: (_, i) => StudentPeriodCard(slot: slots[i]),
    );
  }

  Widget _buildEmptyDay(String day, StudentThemeConfig theme) {
    final isToday = day == _todayKey();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isToday
                  ? theme.primary.withOpacity(0.08)
                  : theme.dividerColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isToday
                  ? Icons.event_available_rounded
                  : Icons.event_busy_rounded,
              size: 28,
              color: isToday
                  ? theme.primary.withOpacity(0.8)
                  : theme.textSecondary.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 12),
          Text(
            isToday ? 'No classes today' : 'No classes on $day',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
              color: theme.textPrimary,
            ),
          ),
          SizedBox(height: 3),
          Text(
            isToday ? 'Enjoy your free day' : 'Free day',
            style: TextStyle(color: theme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader(StudentThemeConfig theme) => Center(
    child: CircularProgressIndicator(color: theme.primary, strokeWidth: 2.5),
  );

  Widget _buildError(StudentThemeConfig theme) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_rounded, size: 44, color: theme.dividerColor),
        SizedBox(height: 12),
        Text(
          'Failed to load timetable',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: theme.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: _fetchTimetable,
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
  );
}
