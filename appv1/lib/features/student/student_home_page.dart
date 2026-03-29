import 'dart:convert';
import 'package:appv1/features/student/notification/student_notification_screen.dart';
import 'package:appv1/features/student/student_period_card.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_classroom_screen.dart';
import 'student_attendance_screen.dart';
import 'student_notice_screen.dart';
import 'student_timetable_page.dart';

const Color _accent = Colors.teal;

class StudentHomePage extends StatefulWidget {
  @override
  _StudentHomePageState createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  // ── Prefs ──────────────────────────────────────────
  String _studentName = '';
  String _orgName = '';
  String _className = '';
  String _classId = '';

  // ── Today schedule ─────────────────────────────────
  bool _schedLoading = true;
  bool _schedError = false;
  String _todayLabel = '';
  List<Map<String, dynamic>> _todaySlots = [];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  int _notifCount = 0;

  Future<void> _fetchNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('studentId') ?? '';
    final classId = prefs.getString('classId') ?? '';
    int count = 0;

    try {
      if (studentId.isNotEmpty) {
        final r1 = await http.get(
          Uri.parse(
            'https://appv1backend.onrender.com/api/notification/student/$studentId',
          ),
        );
        final b1 = jsonDecode(r1.body);
        count += (b1['count'] as int? ?? 0);
      }
      if (classId.isNotEmpty) {
        final r2 = await http.get(
          Uri.parse(
            'https://appv1backend.onrender.com/api/notification/class/$classId',
          ),
        );
        final b2 = jsonDecode(r2.body);
        count += (b2['count'] as int? ?? 0);
      }
    } catch (_) {}

    if (mounted) setState(() => _notifCount = count);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _studentName = prefs.getString('studentName') ?? 'Student';
      _orgName = prefs.getString('tempOrgName') ?? '';
      _className = prefs.getString('className') ?? '';
      _classId = prefs.getString('classId') ?? '';
    });
    if (_classId.isNotEmpty) {
      await _fetchToday();
    } else {
      setState(() => _schedLoading = false);
    }
  }

  // ── Today API ──────────────────────────────────────

  Future<void> _fetchToday() async {
    setState(() {
      _schedLoading = true;
      _schedError = false;
    });
    try {
      final res = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/timetable/class/$_classId/today',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      debugPrint('[StudentToday] ${res.statusCode}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _todayLabel = body['today']?.toString() ?? _todayKey();
        final raw = (body['slots'] ?? []) as List<dynamic>;
        final slots = raw.map((e) => e as Map<String, dynamic>).toList()
          ..sort((a, b) => _periodNum(a).compareTo(_periodNum(b)));
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
    } catch (e) {
      debugPrint('[StudentToday] error: $e');
      if (!mounted) return;
      setState(() {
        _schedError = true;
        _schedLoading = false;
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

  int _periodNum(Map<String, dynamic> s) => s['periodNumber'] is int
      ? s['periodNumber'] as int
      : int.tryParse(s['periodNumber']?.toString() ?? '') ?? 0;

  bool _isCurrentPeriod(Map<String, dynamic> slot) {
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _goToTimetable() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          StudentTimetablePage(classId: _classId, className: _className),
    ),
  );

  // ── Build ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _accent,
          onRefresh: _fetchToday,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 18),
                _buildBanner(),
                SizedBox(height: 22),
                _buildTodaySection(),
                SizedBox(height: 22),
                _buildQuickAccessSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Hi, $_studentName',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_orgName.isNotEmpty) ...[
                SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 11,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 3),
                    Text(
                      _orgName,
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
        // In your StudentMainScreen header — replace avatar with:
        GestureDetector(
          onTap: () async {
            // Clear badge count before navigating
            setState(() => _notifCount = 0);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentNotificationScreen(),
              ),
            );
            // Reload count after returning (optional)
            _fetchNotificationCount();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (_notifCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _notifCount > 99 ? '99+' : '$_notifCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Banner ─────────────────────────────────────────

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, _accent.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay on track',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check your timetable and\nkeep up with class notices.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    _bannerChip(
                      Icons.calendar_today_rounded,
                      _todayLabel.isNotEmpty
                          ? _todayLabel.substring(0, 3)
                          : 'Today',
                    ),
                    SizedBox(width: 14),
                    _bannerChip(
                      Icons.schedule_rounded,
                      _schedLoading ? '...' : '${_todaySlots.length} periods',
                    ),
                    SizedBox(width: 14),
                    _bannerChip(Icons.notifications_outlined, 'Notices'),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(Icons.school_rounded, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _bannerChip(IconData icon, String label) => Row(
    children: [
      Icon(icon, color: Colors.white.withOpacity(0.9), size: 12),
      SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  // ── Today's timetable section ──────────────────────

  Widget _buildTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Classes — $_todayLabel",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (!_schedLoading && _todaySlots.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Text(
                        '${_todaySlots.length} period${_todaySlots.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _goToTimetable,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _accent.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, size: 12, color: _accent),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),

        // Content
        if (_schedLoading)
          _buildSkeleton()
        else if (_schedError)
          _buildErrorCard()
        else if (_todaySlots.isEmpty)
          _buildNoClassCard()
        else
          ..._todaySlots
              .take(2)
              .map(
                (s) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: StudentPeriodCard(slot: s),
                ),
              ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: EdgeInsets.only(bottom: 8),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 38,
                margin: EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 11, width: 100, color: Colors.grey[200]),
                    SizedBox(height: 7),
                    Container(height: 9, width: 64, color: Colors.grey[200]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.red[400], size: 17),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Failed to load timetable',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: _fetchToday,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoClassCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: Colors.teal[600],
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No classes today',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Colors.teal[700],
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Enjoy your free day',
                  style: TextStyle(color: Colors.teal[400], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick access section ───────────────────────────

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        _buildNavCard(
          icon: Icons.calendar_month_rounded,
          title: 'Timetable',
          subtitle: 'View your full weekly schedule',
          onTap: _goToTimetable,
        ),
        SizedBox(height: 8),
        _buildNavCard(
          icon: Icons.class_rounded,
          title: 'Visit Classroom',
          subtitle: _className.isNotEmpty
              ? _className
              : 'View lessons, materials and more',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentClassroomScreen()),
          ),
        ),
        SizedBox(height: 8),
        _buildNavCard(
          icon: Icons.fact_check_rounded,
          title: 'My Attendance',
          subtitle: 'Track your daily attendance record',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentAttendanceScreen()),
          ),
        ),
        SizedBox(height: 8),
        _buildNavCard(
          icon: Icons.campaign_rounded,
          title: 'Notice Board',
          subtitle: 'Announcements from your teacher',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentNoticeScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(icon, color: _accent, size: 19),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
