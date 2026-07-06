import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:appv1/features/student/notification/student_notification_screen.dart';
import 'package:appv1/features/student/student_leave_screen.dart';
import 'package:appv1/features/student/student_period_card.dart';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_classroom_screen.dart';
import 'student_attendance_screen.dart';
import 'student_notice_screen.dart';
import 'student_timetable_page.dart';
import 'student_theme_manager.dart';

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
      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/timetable/class/$_classId/today',
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
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        return Scaffold(
          backgroundColor: theme.background,
          // ✅ SafeArea removed — StudentMainScreen header handles it
          body: RefreshIndicator(
            color: theme.primary,
            onRefresh: _fetchToday,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 18),
                  _buildBanner(theme),
                  const SizedBox(height: 22),
                  _buildTodaySection(theme),
                  const SizedBox(height: 22),
                  _buildQuickAccessSection(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Header — bell removed (lives in StudentMainScreen) ──
  Widget _buildHeader(StudentThemeConfig theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting(),
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Hi, $_studentName',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_orgName.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                Icons.business_rounded,
                size: 11,
                color: theme.textSecondary,
              ),
              const SizedBox(width: 3),
              Text(
                _orgName,
                style: TextStyle(color: theme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Banner ─────────────────────────────────────────
  Widget _buildBanner(StudentThemeConfig theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.gradientEnd],
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
                const Text(
                  'Stay on track',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check your timetable and\nkeep up with class notices.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _bannerChip(
                      Icons.calendar_today_rounded,
                      _todayLabel.isNotEmpty
                          ? _todayLabel.substring(0, 3)
                          : 'Today',
                    ),
                    const SizedBox(width: 14),
                    _bannerChip(
                      Icons.schedule_rounded,
                      _schedLoading ? '...' : '${_todaySlots.length} periods',
                    ),
                    const SizedBox(width: 14),
                    _bannerChip(Icons.notifications_outlined, 'Notices'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerChip(IconData icon, String label) => Row(
    children: [
      Icon(icon, color: Colors.white.withOpacity(0.9), size: 12),
      const SizedBox(width: 3),
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
  Widget _buildTodaySection(StudentThemeConfig theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Classes $_todayLabel",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  if (!_schedLoading && _todaySlots.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        '${_todaySlots.length} period${_todaySlots.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: theme.textSecondary,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: theme.primary.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, size: 12, color: theme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_schedLoading)
          _buildSkeleton(theme)
        else if (_schedError)
          _buildErrorCard(theme)
        else if (_todaySlots.isEmpty)
          _buildNoClassCard(theme)
        else
          ..._todaySlots
              .take(2)
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: StudentPeriodCard(slot: s),
                ),
              ),
      ],
    );
  }

  Widget _buildSkeleton(StudentThemeConfig theme) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 64,
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 38,
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 11, width: 100, color: theme.dividerColor),
                    const SizedBox(height: 7),
                    Container(height: 9, width: 64, color: theme.dividerColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(StudentThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.red[400], size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Failed to load timetable',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: _fetchToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  Widget _buildNoClassCard(StudentThemeConfig theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: theme.primary.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: theme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No classes today',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: theme.primary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Enjoy your free day',
                  style: TextStyle(color: theme.primary.withOpacity(0.8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick access section ───────────────────────────
  Widget _buildQuickAccessSection(StudentThemeConfig theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildNavCard(
          icon: Icons.calendar_month_rounded,
          title: 'Timetable',
          subtitle: 'View your full weekly schedule',
          onTap: _goToTimetable,
          theme: theme,
        ),
        const SizedBox(height: 8),
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
          theme: theme,
        ),
        const SizedBox(height: 8),
        _buildNavCard(
          icon: Icons.fact_check_rounded,
          title: 'My Attendance',
          subtitle: 'Track your daily attendance record',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentAttendanceScreen()),
          ),
          theme: theme,
        ),
        const SizedBox(height: 8),
        _buildNavCard(
          icon: Icons.campaign_rounded,
          title: 'Notice Board',
          subtitle: 'Announcements from your teacher',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentNoticeScreen()),
          ),
          theme: theme,
        ),
        const SizedBox(height: 8),
        _buildNavCard(
          icon: Icons.event_note_rounded,
          title: 'Leave Requests',
          subtitle: 'Apply for leave and track status',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentLeaveScreen()),
          ),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required StudentThemeConfig theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(icon, color: theme.primary, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: theme.textSecondary,
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
                    color: theme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: theme.primary,
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

