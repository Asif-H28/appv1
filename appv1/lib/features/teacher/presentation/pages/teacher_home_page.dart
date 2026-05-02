import 'package:appv1/core/constants/api_constants.dart';
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
import 'student_leave_review_page.dart';

const Color _accent = Colors.teal;

class TeacherHomePage extends StatefulWidget {
  @override
  _TeacherHomePageState createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  // â”€â”€ Prefs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String _name = '';
  String _teacherId = '';
  String _orgId = '';

  // â”€â”€ Schedule â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool _schedLoading = true;
  bool _schedError = false;
  List<Map<String, dynamic>> _todaySlots = [];
  String _todayLabel = '';

  // â”€â”€ Classrooms â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool _classLoading = true;
  bool _classError = false;
  List<Map<String, dynamic>> _classrooms = [];
  bool _showAllClassrooms = false;

  // â”€â”€ Student Leaves â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  int _pendingLeaveCount = 0;
  bool _pendingLeaveLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // â”€â”€ Load prefs + all data â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    await _fetchPendingLeaveCounts();
  }

  // â”€â”€ Today's schedule â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _fetchTodaySchedule() async {
    setState(() {
      _schedLoading = true;
      _schedError = false;
    });
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/timetable/teacher/$_teacherId',
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

  // â”€â”€ Classrooms â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _fetchClassrooms() async {
    setState(() {
      _classLoading = true;
      _classError = false;
    });
    try {
      List<dynamic> raw = [];

      if (_teacherId.isNotEmpty) {
        final res = await http.get(
          Uri.parse(
            '${ApiConstants.apiBaseUrl}/classroom/teacher/$_teacherId',
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

      if (raw.isEmpty && _orgId.isNotEmpty) {
        final res = await http.get(
          Uri.parse(
            '${ApiConstants.apiBaseUrl}/classroom/org/$_orgId',
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

  // â”€â”€ Pending leave counts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _fetchPendingLeaveCounts() async {
    if (_classrooms.isEmpty) return;
    setState(() => _pendingLeaveLoading = true);
    int total = 0;
    try {
      for (final cls in _classrooms) {
        final classId = cls['classId']?.toString() ?? '';
        if (classId.isEmpty) continue;
        final res = await http.get(
          Uri.parse(
            '${ApiConstants.apiBaseUrl}/leave/student/class/$classId/pending',
          ),
          headers: {'Content-Type': 'application/json'},
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

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  void _goToSchedule() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          TeacherSchedulePage(teacherId: _teacherId, teacherName: _name),
    ),
  );

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.sync_alt,
                  color: Colors.white,
                  size: 16,
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
              GestureDetector(
                onTap: null,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€ Today's Schedule section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: "Today's Schedule â€” $_todayLabel",
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

  // â”€â”€ My Classrooms section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Student Leave section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Notice section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
        const SizedBox(height: 10),
        ...notices.map(
          (n) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
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

// â”€â”€ Notice model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Notice {
  final String title;
  final String preview;
  final String time;
  const _Notice(this.title, this.preview, this.time);
}

