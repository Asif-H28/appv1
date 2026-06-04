import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/drawer_helper.dart';
import '../widgets/classroom_card.dart';
import 'classroom_detail_page.dart';
import 'teacher_schedule_page.dart';
import 'teacher_home_widgets.dart';
import 'notice_page.dart';
import 'student_leave_review_page.dart';
import '../widgets/notice_detail_sheet.dart';
import 'teacher_notification_screen.dart';
import 'teacher_settings_page.dart';
import '../../../main_app/pages/notification_service.dart';
import 'org_transport_status_page.dart';
import '../../../notification_studio/pages/notification_studio_page.dart';
import '../../../notification_studio/controllers/notification_studio_controller.dart';
import 'package:appv1/features/tuition_session/teacher/teacher_today_sessions_screen.dart';
import 'package:appv1/core/services/feature_flag_service.dart';

const Color _accent = Colors.teal;

class TeacherHomePage extends StatefulWidget {
  @override
  _TeacherHomePageState createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  // ── Prefs ───────────────────────────────────────────
  String _name = '';
  String _teacherId = '';
  String _orgId = '';

  // ── Schedule ─────────────────────────────────────────
  bool _schedLoading = true;
  bool _schedError = false;
  List<Map<String, dynamic>> _todaySlots = [];
  String _todayLabel = '';

  // ── Classrooms ───────────────────────────────────────
  bool _classLoading = true;
  bool _classError = false;
  List<Map<String, dynamic>> _classrooms = [];
  bool _showAllClassrooms = false;

  // ── Student Leaves ──────────────────────────────────
  int _pendingLeaveCount = 0;
  bool _pendingLeaveLoading = false;

  // ── Notices ──────────────────────────────────────────
  List<Map<String, dynamic>> _notices = [];
  bool _noticesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Load prefs + all data ────────────────────────────

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('teacherName') ?? 'Teacher';
      _teacherId = prefs.getString('teacherId') ?? '';
      _orgId = prefs.getString('orgId') ?? '';
    });

    if (_orgId.isNotEmpty) {
      FeatureFlagService.instance.fetchAndCacheFlags(_orgId);
    }

    await Future.wait([
      if (_teacherId.isNotEmpty)
        _fetchTodaySchedule()
      else
        Future(() => setState(() => _schedLoading = false)),
      _fetchClassrooms(),
      _fetchNotices(),
    ]);
    await _fetchPendingLeaveCounts();
  }

  // ── Today's schedule ─────────────────────────────────

  Future<void> _fetchTodaySchedule() async {
    setState(() {
      _schedLoading = true;
      _schedError = false;
    });
    try {
      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/timetable/teacher/$_teacherId',
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

  // ── Classrooms ───────────────────────────────────────

  Future<void> _fetchClassrooms() async {
    setState(() {
      _classLoading = true;
      _classError = false;
    });
    try {
      List<dynamic> raw = [];

      if (_teacherId.isNotEmpty) {
        final res = await ApiService.get(
          '${ApiConstants.apiBaseUrl}/classroom/teacher/$_teacherId',
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
        _classrooms = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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

  // ── Pending leave counts ──────────────────────────────

  Future<void> _fetchPendingLeaveCounts() async {
    if (_classrooms.isEmpty) return;
    setState(() => _pendingLeaveLoading = true);
    int total = 0;
    try {
      for (final cls in _classrooms) {
        final classId = cls['classId']?.toString() ?? '';
        if (classId.isEmpty) continue;
        final res = await ApiService.get(
          '${ApiConstants.apiBaseUrl}/leave/student/class/$classId/pending',
        );
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map;
          total += (body['count'] as int? ?? 0);
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _pendingLeaveCount = total;
        _pendingLeaveLoading = false;
      });
    }
  }

  // ── Fetch Notices ────────────────────────────────────

  Future<void> _fetchNotices() async {
    if (_orgId.isEmpty) return;
    setState(() => _noticesLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/admin-notices/teacher/$_orgId',
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['notices'] as List? ?? []);
        if (mounted) {
          setState(() {
            _notices = list.map((e) => Map<String, dynamic>.from(e)).toList();
            _noticesLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _noticesLoading = false);
      }
    } catch (e) {
      debugPrint('[TeacherHomePage] fetchNotices error: $e');
      if (mounted) setState(() => _noticesLoading = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────

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

  void _goToSchedule() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          TeacherSchedulePage(teacherId: _teacherId, teacherName: _name),
    ),
  );

  // ── Build ─────────────────────────────────────────────

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
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodaySection(),
                    const SizedBox(height: 24),
                    _buildClassroomsSection(),
                    const SizedBox(height: 24),
                    _buildStudentLeaveSection(),
                    const SizedBox(height: 24),
                    _buildTransportSection(),
                    const SizedBox(height: 24),
                    ValueListenableBuilder<bool>(
                      valueListenable: FeatureFlagService.instance.tuitionFeatureEnabled,
                      builder: (context, isEnabled, child) {
                        if (!isEnabled) return const SizedBox.shrink();
                        return Column(
                          children: [
                            _buildTuitionSessionsSection(),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
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

  // ── Header ────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(
            children: [
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => openParentDrawer(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SchoolSync',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Teacher Portal',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: NotificationStudioController(),
                builder: (context, _) {
                  final count = NotificationStudioController().unreadCount;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationStudioPage(),
                        ),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            top: -5,
                            right: -5,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
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
                  );
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TeacherSettingsPage()),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Today's Schedule section ──────────────────────────

  Widget _buildTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: "Today's Schedule $_todayLabel",
          subtitle: (!_schedLoading && _todaySlots.isNotEmpty)
              ? '${_todaySlots.length} period${_todaySlots.length == 1 ? '' : 's'}'
              : null,
          actionLabel: 'View All',
          onAction: _goToSchedule,
        ),
        const SizedBox(height: 10),
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
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HomeScheduleCard(slot: s),
                ),
              ),
        if (!_schedLoading && !_schedError && _todaySlots.length > 3) ...[
          const SizedBox(height: 4),
          HomeViewMoreBtn(
            label: '+${_todaySlots.length - 3} more periods',
            onTap: _goToSchedule,
          ),
        ],
      ],
    );
  }

  // ── My Classrooms section ─────────────────────────────

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
        const SizedBox(height: 10),
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
              padding: const EdgeInsets.only(bottom: 8),
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
          if (_classrooms.length > 2)
            GestureDetector(
              onTap: () =>
                  setState(() => _showAllClassrooms = !_showAllClassrooms),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
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
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
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
  }

  // ── Student Leave section ─────────────────────────────

  Widget _buildStudentLeaveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Student Leave Requests',
          subtitle: _pendingLeaveLoading
              ? null
              : _pendingLeaveCount > 0
              ? '$_pendingLeaveCount pending'
              : 'No pending requests',
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            if (_classrooms.isEmpty) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentLeaveReviewPage(
                  classrooms: _classrooms,
                  teacherId: _teacherId,
                ),
              ),
            );
            // Refresh pending count on return
            _fetchPendingLeaveCounts();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: Colors.teal,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Leave Requests',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Approve or reject student leave applications',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_pendingLeaveLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.teal,
                      strokeWidth: 2,
                    ),
                  )
                else if (_pendingLeaveCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '$_pendingLeaveCount pending',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: 'Live Transport Monitoring',
          subtitle: 'Track school vehicles in real-time',
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            if (_orgId.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrgTransportStatusPage(orgId: _orgId),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Colors.orange,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fleet Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View real-time location of all active buses',
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
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTuitionSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: 'Tuition Sessions',
          subtitle: 'Manage today\'s sessions and check-ins',
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherTodaySessionsScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.teal,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Sessions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'View sessions, scan QR, and log activities',
                        style: TextStyle(
                          color: Colors.black54,
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
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Notice section ────────────────────────────────────

  Widget _buildNoticeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Notice Board',
          subtitle: _noticesLoading
              ? null
              : _notices.isEmpty
                  ? 'No notices'
                  : '${_notices.length} notice${_notices.length == 1 ? '' : 's'}',
          // actionLabel: 'View All', // REMOVED per requirement
          // onAction: () => Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (_) => const NoticePage()),
          // ),
        ),
        const SizedBox(height: 10),
        if (_noticesLoading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.teal)))
        else if (_notices.isEmpty)
          HomeNoNoticesCard()
        else ...[
          ..._notices.take(3).map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HomeNoticeCard(
                    notice: n,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => NoticeDetailSheet(notice: n),
                    ),
                  ),
                ),
              ),
          if (_notices.length > 3) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoticePage()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.teal.withOpacity(0.2)),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All Notices',
                        style: TextStyle(
                          color: Colors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.teal),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (_notices.isNotEmpty) ...[
            // Small card for view all if notices are few
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoticePage()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.teal.withOpacity(0.1)),
                ),
                child: const Center(
                  child: Text(
                    'Go to Notice Board',
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
