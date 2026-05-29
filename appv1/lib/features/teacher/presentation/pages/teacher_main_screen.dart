import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/drawer_helper.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_http_adapter.dart' as http;
import '../../../main_app/pages/notification_service.dart';
import '../../../main_app/pages/login_page.dart';
import '../../../main_app/pages/app_update_page.dart';
import 'teacher_home_page.dart';
import 'teacher_classroom_page.dart';
import 'teacher_dashboard_page.dart';
import 'teacher_settings_page.dart';
import 'teacher_achievements_page.dart';
import 'teacher_attendance_page.dart';
import '../../../chat/conversation_list_screen.dart';
import '../../../../core/services/chat_socket_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../notification_studio/controllers/notification_studio_controller.dart';
import 'dart:convert';


const Color _accent = Colors.teal;

class TeacherMainScreen extends StatefulWidget {
  final int initialTab;
  const TeacherMainScreen({this.initialTab = 0});

  @override
  _TeacherMainScreenState createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  late int _currentTab;
  final ValueNotifier<int> _unreadChatCount = ValueNotifier<int>(0);
  final List<StreamSubscription> _socketSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;

    // Listen for chat messages and updates
    _socketSubscriptions.add(
      ChatSocketService().onNewMessage.listen((_) => _fetchChatUnreadCount()),
    );
    _socketSubscriptions.add(
      ChatSocketService().onStatusUpdate.listen((_) => _fetchChatUnreadCount()),
    );
    _socketSubscriptions.add(
      ChatSocketService().onRefreshUnread.listen(
        (_) => _fetchChatUnreadCount(),
      ),
    );
    _fetchChatUnreadCount();
  }

  Future<void> _fetchChatUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.getString('userId') ??
        prefs.getString('teacherId') ??
        prefs.getString('studentId') ??
        prefs.getString('orgId') ??
        '';
    if (userId.isEmpty) return;

    final response = await ApiService.get('/chat/conversations/$userId');
    if (response.statusCode == 200) {
      final List conversations = jsonDecode(response.body);
      int count = 0;
      for (var conv in conversations) {
        final unreadCounts = conv['unreadCounts'] ?? {};
        count += (unreadCounts[userId] as int? ?? 0);
      }
      _unreadChatCount.value = count;
    }
  }

  @override
  void dispose() {
    for (var sub in _socketSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  final List<Widget> _pages = [
    TeacherHomePage(),
    const ConversationListScreen(),
    TeacherClassroomPage(),
    TeacherAchievementsPage(),
    TeacherDashboardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: teacherScaffoldKey,
      drawer: _buildDrawer(),
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: IndexedStack(index: _currentTab, children: _pages),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SchoolSync',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Teacher Portal',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  title: 'Home',
                  isSelected: _currentTab == 0,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentTab = 0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.chat_bubble_rounded,
                  title: 'Chat',
                  isSelected: _currentTab == 1,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentTab = 1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.class_rounded,
                  title: 'Classroom',
                  isSelected: _currentTab == 2,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentTab = 2);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.emoji_events_rounded,
                  title: 'Achievements',
                  isSelected: _currentTab == 3,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentTab = 3);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  isSelected: _currentTab == 4,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentTab = 4);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.how_to_reg_rounded,
                  title: 'My Attendance',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherAttendancePage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TeacherSettingsPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.system_update_rounded,
                  title: 'App Update',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppUpdatePage(),
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  isSelected: false,
                  iconColor: Colors.red[600],
                  textColor: Colors.red[600],
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final activeColor = Colors.teal;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          icon,
          color: isSelected ? activeColor : (iconColor ?? const Color(0xFF64748B)),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? activeColor : (textColor ?? const Color(0xFF1E293B)),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherId = prefs.getString('teacherId') ?? '';
      if (teacherId.isNotEmpty) {
        try {
          await http.post(
            Uri.parse('${ApiConstants.apiBaseUrl}/notification/fcm/teacher/clear'),
            headers: await ApiService.getHeaders(),
            body: jsonEncode({'teacherId': teacherId}),
          );
        } catch (_) {}
      }
      await prefs.clear();
      NotificationStudioController().disconnect();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout failed. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                Icons.chat_bubble_rounded,
                Icons.chat_bubble_outline_rounded,
                'Chat',
                badgeCount: _unreadChatCount,
              ),
              _navItem(
                2,
                Icons.class_rounded,
                Icons.class_outlined,
                'Classroom',
              ),
              _navItem(
                3,
                Icons.emoji_events_rounded,
                Icons.emoji_events_outlined,
                'Achieve',
              ),
              _navItem(
                4,
                Icons.dashboard_rounded,
                Icons.dashboard_outlined,
                'Dashboard',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData active,
    IconData inactive,
    String label, {
    ValueNotifier<int>? badgeCount,
  }) {
    final isActive = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentTab = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? active : inactive,
                  color: isActive ? _accent : AppColors.textSecondary,
                  size: 22,
                ),
                if (badgeCount != null)
                  ValueListenableBuilder<int>(
                    valueListenable: badgeCount,
                    builder: (context, count, _) {
                      if (count == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: -5,
                        top: -5,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _accent : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
