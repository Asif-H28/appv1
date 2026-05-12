import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../main_app/pages/notification_service.dart';
import 'teacher_home_page.dart';
import 'teacher_classroom_page.dart';
import 'teacher_dashboard_page.dart';
import 'teacher_settings_page.dart';
import 'teacher_achievements_page.dart';
import '../../../chat/conversation_list_screen.dart';
import '../../../../core/services/chat_socket_service.dart';
import '../../../../core/services/api_service.dart';
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
  String _teacherId = '';
  String _authToken = '';
  final ValueNotifier<int> _unreadChatCount = ValueNotifier<int>(0);
  final List<StreamSubscription> _socketSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _loadAndFetch();
    teacherNotifCountNotifier.addListener(_onNotifReceived);

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
    teacherNotifCountNotifier.removeListener(_onNotifReceived);
    for (var sub in _socketSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  void _onNotifReceived() {
    // Only fetch if the value was incremented as a signal (e.g. from FCM)
    // To avoid infinite loop if we update the value here, we should be careful.
    // However, usually listeners don't trigger when value is set to same thing.
    _fetchCount();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _teacherId = prefs.getString('teacherId') ?? '';
    _authToken = prefs.getString('authToken') ?? '';
    _fetchCount();
  }

  Future<void> _fetchCount() async {
    if (_teacherId.isEmpty || _authToken.isEmpty) return;
    final count = await NotificationService.getTeacherNotificationCount(
      teacherId: _teacherId,
      token: _authToken,
    );
    if (mounted) {
      // Use teacherNotifCountNotifier to store the real count
      teacherNotifCountNotifier.value = count;
    }
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
