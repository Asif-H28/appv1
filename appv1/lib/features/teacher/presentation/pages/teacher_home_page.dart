import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/classroom_card.dart';
import 'classroom_detail_page.dart';
import 'teacher_schedule_page.dart';
import 'teacher_home_widgets.dart';
import 'notice_page.dart';

const Color _accent = Colors.teal;

class TeacherHomePage extends StatefulWidget {
  @override
  _TeacherHomePageState createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  // ── Prefs ──────────────────────────────────────────
  String _name = '';
  String _teacherId = '';
  String _orgId = '';

  // ── Schedule ───────────────────────────────────────
  bool _schedLoading = true;
  bool _schedError = false;
  List<Map<String, dynamic>> _todaySlots = [];
  String _todayLabel = '';

  // ── Classrooms ─────────────────────────────────────
  bool _classLoading = true;
  bool _classError = false;
  List<Map<String, dynamic>> _classrooms = [];
  // Add this to your state variables at the top
  bool _showAllClassrooms = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Load prefs ─────────────────────────────────────

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('teacherName') ?? 'Teacher';
      _teacherId = prefs.getString('teacherId') ?? '';
      _orgId = prefs.getString('orgId') ?? '';
    });
    await Future.wait([
      if (_teacherId.isNotEmpty)
        _fetchTodaySchedule()
      else
        Future(() => setState(() => _schedLoading = false)),
      _fetchClassrooms(),
    ]);
  }

  // ── Today's schedule ───────────────────────────────

  Future<void> _fetchTodaySchedule() async {
    setState(() {
      _schedLoading = true;
      _schedError = false;
    });
    try {
      final res = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/timetable/teacher/$_teacherId',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final schedule = body['schedule'] as Map<String, dynamic>?;
        final today = _todayKey();
        _todayLabel = today;
        final raw = (schedule?[today] ?? []) as List<dynamic>;
        final slots = raw.map((e) => e as Map<String, dynamic>).toList()
          ..sort((a, b) => periodNum(a).compareTo(periodNum(b)));
        setState(() {
          _todaySlots = slots;
          _schedLoading = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _todaySlots = [];
          _schedLoading = false;
        });
      } else {
        setState(() {
          _schedError = true;
          _schedLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _schedError = true;
        _schedLoading = false;
      });
    }
  }

  // ── Classrooms ─────────────────────────────────────

  Future<void> _fetchClassrooms() async {
    setState(() {
      _classLoading = true;
      _classError = false;
    });
    try {
      List<dynamic> raw = [];

      // Prefer teacher-specific endpoint
      if (_teacherId.isNotEmpty) {
        final res = await http.get(
          Uri.parse(
            'https://appv1backend.onrender.com/api/classroom/teacher/$_teacherId',
          ),
          headers: {'Content-Type': 'application/json'},
        );
        if (!mounted) return;
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          raw = body is List
              ? body
              : (body['classrooms'] ?? body['data'] ?? []) as List;
        }
      }

      // Fallback to org
      if (raw.isEmpty && _orgId.isNotEmpty) {
        final res = await http.get(
          Uri.parse(
            'https://appv1backend.onrender.com/api/classroom/org/$_orgId',
          ),
          headers: {'Content-Type': 'application/json'},
        );
        if (!mounted) return;
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          raw = body is List
              ? body
              : (body['classrooms'] ?? body['data'] ?? []) as List;
        }
      }

      if (!mounted) return;
      setState(() {
        _classrooms = raw.map((e) => e as Map<String, dynamic>).toList();
        _classLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _classError = true;
        _classLoading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────

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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const wdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${wdays[d.weekday]}, ${d.day} ${months[d.month]} ${d.year}';
  }

  void _goToSchedule() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          TeacherSchedulePage(teacherId: _teacherId, teacherName: _name),
    ),
  );

  // ── Build ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              color: _accent,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodaySection(),
                    SizedBox(height: 24),
                    _buildClassroomsSection(),
                    SizedBox(height: 24),
                    _buildNoticeSection(),
                  ],
                ),
              ),
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
          colors: [_accent, _accent.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 11,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatDate(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _headerBtn(
                    Icons.calendar_month_rounded,
                    onTap: _goToSchedule,
                  ),
                  SizedBox(height: 8),
                  _headerBtn(Icons.notifications_outlined),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.28)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ── Today's schedule section ───────────────────────

  Widget _buildTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: "Today's Schedule — $_todayLabel",
          subtitle: (!_schedLoading && _todaySlots.isNotEmpty)
              ? '${_todaySlots.length} period${_todaySlots.length == 1 ? '' : 's'}'
              : null,
          actionLabel: 'View All',
          onAction: _goToSchedule,
        ),
        SizedBox(height: 10),

        if (_schedLoading)
          HomeScheduleSkeleton()
        else if (_schedError)
          HomeScheduleError(onRetry: _fetchTodaySchedule)
        else if (_todaySlots.isEmpty)
          HomeNoClassesCard()
        else
          ..._todaySlots
              .take(3)
              .map(
                (s) => Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: HomeScheduleCard(slot: s),
                ),
              ),

        if (!_schedLoading && !_schedError && _todaySlots.length > 3) ...[
          SizedBox(height: 4),
          HomeViewMoreBtn(
            label: '+${_todaySlots.length - 3} more periods',
            onTap: _goToSchedule,
          ),
        ],
      ],
    );
  }

  // ── My Classrooms section ──────────────────────────

  Widget _buildClassroomsSection() {
    final displayList = _showAllClassrooms
        ? _classrooms
        : _classrooms.take(2).toList();
    final remaining = _classrooms.length - 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'My Classrooms',
          subtitle: _classLoading
              ? null
              : '${_classrooms.length} classroom${_classrooms.length == 1 ? '' : 's'}',
        ),
        SizedBox(height: 10),

        if (_classLoading)
          HomeClassroomSkeleton()
        else if (_classError)
          HomeScheduleError(onRetry: _fetchClassrooms)
        else if (_classrooms.isEmpty)
          HomeNoClassroomsCard()
        else ...[
          ...displayList.map((cls) {
            final classId = cls['classId']?.toString() ?? '';
            final className = cls['className']?.toString() ?? 'Class';
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: HomeClassroomCard(
                classroom: cls,
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClassroomDetailPage(
                      classId: classId,
                      className: className,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Show/hide toggle button
          if (_classrooms.length > 2)
            GestureDetector(
              onTap: () =>
                  setState(() => _showAllClassrooms = !_showAllClassrooms),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.teal.withOpacity(0.2)),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showAllClassrooms
                            ? 'Show Less'
                            : 'View All  (+$remaining more)',
                        style: TextStyle(
                          color: Colors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        _showAllClassrooms
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 15,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  } // ── Notice section ─────────────────────────────────

  Widget _buildNoticeSection() {
    final notices = [
      _Notice(
        'School Annual Day Preparation',
        'All teachers are requested to...',
        'Today',
      ),
      _Notice(
        'Staff Meeting Tomorrow',
        'Mandatory staff meeting at 4 PM in...',
        'Yesterday',
      ),
      _Notice(
        'Exam Schedule Released',
        'The final exam timetable has been...',
        '2 days ago',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Notice Board',
          subtitle: '${notices.length} notices',
          actionLabel: 'View All',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NoticePage()),
          ),
        ),
        SizedBox(height: 10),
        ...notices.map(
          (n) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: HomeNoticeCard(
              notice: n,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NoticePage()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Notice model ───────────────────────────────────────

class _Notice {
  final String title;
  final String preview;
  final String time;
  const _Notice(this.title, this.preview, this.time);
}
