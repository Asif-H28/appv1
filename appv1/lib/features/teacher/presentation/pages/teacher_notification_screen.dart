import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../main_app/pages/notification_service.dart';
import '../../../student/notification/notification_card.dart';

const Color _accent = Colors.teal;

class TeacherNotificationScreen extends StatefulWidget {
  const TeacherNotificationScreen({Key? key}) : super(key: key);

  @override
  State<TeacherNotificationScreen> createState() => _TeacherNotificationScreenState();
}

class _TeacherNotificationScreenState extends State<TeacherNotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loadingOrg = true;
  List<Map<String, dynamic>> _orgNotifs = [];

  bool _loadingStudent = true;
  List<Map<String, dynamic>> _studentNotifs = [];

  String _teacherId = '';
  String _authToken = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _teacherId = prefs.getString('teacherId') ?? '';
    _authToken = prefs.getString('authToken') ?? '';
    _fetchOrgNotifs();
    _fetchStudentNotifs();
  }

  Future<void> _fetchOrgNotifs() async {
    if (!mounted) return;
    setState(() => _loadingOrg = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/notification/teacher/$_teacherId/admin-leave-reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['notifications'] as List? ?? []).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['_source'] = 'organization';
          return m;
        }).toList();

        list.sort((a, b) {
          final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(2000);
          final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

        if (mounted) {
          setState(() {
            _orgNotifs = list;
            _loadingOrg = false;
          });
          _bulkMarkRead(true);
        }
      } else {
        if (mounted) setState(() => _loadingOrg = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOrg = false);
    }
  }

  Future<void> _fetchStudentNotifs() async {
    if (!mounted) return;
    setState(() => _loadingStudent = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/notification/teacher/$_teacherId/student-leave-requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['notifications'] as List? ?? []).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['_source'] = 'student';
          return m;
        }).toList();

        list.sort((a, b) {
          final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(2000);
          final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

        if (mounted) {
          setState(() {
            _studentNotifs = list;
            _loadingStudent = false;
          });
          _bulkMarkRead(false);
        }
      } else {
        if (mounted) setState(() => _loadingStudent = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStudent = false);
    }
  }

  Future<void> _markAsRead(String notifId, bool isOrg) async {
    if (_teacherId.isEmpty) return;
    try {
      await http.put(
        Uri.parse('${ApiConstants.apiBaseUrl}/notification/$notifId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({'userId': _teacherId}),
      );
      // ✅ Trigger global notifier so home page badge updates
      teacherNotifCountNotifier.value++;

      if (mounted) {
        setState(() {
          final list = isOrg ? _orgNotifs : _studentNotifs;
          final idx = list.indexWhere((n) => n['notificationId'] == notifId || n['_id'] == notifId);
          if (idx != -1) {
            final readBy = List<String>.from(list[idx]['readBy'] as List? ?? []);
            if (!readBy.contains(_teacherId)) {
              readBy.add(_teacherId);
              list[idx] = {...list[idx], 'readBy': readBy};
            }
          }
        });
      }
    } catch (_) {}
  }

  void _bulkMarkRead(bool isOrg) {
    if (_teacherId.isEmpty || _authToken.isEmpty) return;
    
    if (isOrg) {
      if (_getUnreadCount(_orgNotifs) > 0) {
        NotificationService.markAllAdminReviewsRead(
          teacherId: _teacherId,
          token: _authToken,
        ).then((_) => teacherNotifCountNotifier.value++);
      }
    } else {
      if (_getUnreadCount(_studentNotifs) > 0) {
        NotificationService.markAllStudentLeavesRead(
          teacherId: _teacherId,
          token: _authToken,
        ).then((_) => teacherNotifCountNotifier.value++);
      }
    }
  }

  int _getUnreadCount(List<Map<String, dynamic>> list) {
    return list.where((n) => !_isRead(n)).length;
  }

  bool _isRead(Map<String, dynamic> notif) {
    final readBy = List<String>.from(notif['readBy'] as List? ?? []);
    return readBy.contains(_teacherId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_orgNotifs, _loadingOrg, true),
                  _buildList(_studentNotifs, _loadingStudent, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Updates from Organization and Students',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _init,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final orgUnread = _getUnreadCount(_orgNotifs);
    final studentUnread = _getUnreadCount(_studentNotifs);

    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _accent,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: _accent,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Organization'),
                if (orgUnread > 0) ...[
                  const SizedBox(width: 6),
                  _buildBadge(orgUnread),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Students'),
                if (studentUnread > 0) ...[
                  const SizedBox(width: 6),
                  _buildBadge(studentUnread),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, bool isLoading, bool isOrg) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
      );
    }

    if (items.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: isOrg ? _fetchOrgNotifs : _fetchStudentNotifs,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final notif = items[i];
          final isRead = _isRead(notif);
          final notifId = notif['notificationId']?.toString() ?? notif['_id']?.toString() ?? '';
          return NotificationCard(
            data: notif,
            isRead: isRead,
            onTap: isRead ? null : () => _markAsRead(notifId, isOrg),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: _accent,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'You are all caught up',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
