import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:appv1/features/main_app/pages/notification_service.dart';
import 'package:appv1/features/student/notification/student_notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_home_page.dart';

import 'student_profile_page.dart';
import 'student_achievements_page.dart';

const Color _accent = Colors.teal;

class StudentMainScreen extends StatefulWidget {
  final int initialTab;
  const StudentMainScreen({this.initialTab = 0});

  @override
  _StudentMainScreenState createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  late int _currentTab;
  int _notifCount = 0;
  String _studentId = '';
  String _classId = '';

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _loadAndFetchCount();
    notifCountNotifier.addListener(_onNewNotification);
  }

  @override
  void dispose() {
    notifCountNotifier.removeListener(_onNewNotification);
    super.dispose();
  }

  void _onNewNotification() => _fetchNotificationCount();

  Future<void> _loadAndFetchCount() async {
    final prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getString('studentId') ?? '';
    _classId = prefs.getString('classId') ?? '';
    _fetchNotificationCount();
  }

  Future<void> _fetchNotificationCount() async {
    if (_studentId.isEmpty) return;
    int total = 0;
    try {
      if (_classId.isNotEmpty) {
        final r = await http.get(
          Uri.parse(
            '${ApiConstants.apiBaseUrl}/notification/class/$_classId/unread/$_studentId',
          ),
          headers: {'Content-Type': 'application/json'},
        );
        if (r.statusCode == 200) {
          final b = jsonDecode(r.body);
          total += (b['unreadCount'] as int? ?? 0);
        }
      }
      if (_studentId.isNotEmpty) {
        final r = await http.get(
          Uri.parse(
            '${ApiConstants.apiBaseUrl}/notification/student/$_studentId',
          ),
          headers: {'Content-Type': 'application/json'},
        );
        if (r.statusCode == 200) {
          final b = jsonDecode(r.body);
          final list = (b['notifications'] as List? ?? []);
          final unread = list.where((n) {
            final readBy = List<String>.from(
              (n as Map)['readBy'] as List? ?? [],
            );
            return !readBy.contains(_studentId);
          }).length;
          total += unread;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _notifCount = total);
  }

  void _openNotifications() {
    setState(() => _notifCount = 0);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentNotificationScreen()),
    );
  }

  final List<Widget> _pages = [
    StudentHomePage(),

    const StudentAchievementsPage(),
    StudentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: IndexedStack(index: _currentTab, children: _pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

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
                      'Student Portal',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _openNotifications,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (_notifCount > 0)
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
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _navItem(
                1,
                Icons.emoji_events_rounded,
                Icons.emoji_events_outlined,
                'Achievements',
              ),
              _navItem(
                2,
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final isActive = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentTab = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? active : inactive,
              color: isActive ? _accent : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _accent : AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

