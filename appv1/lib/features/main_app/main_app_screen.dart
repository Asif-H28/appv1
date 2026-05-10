import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/admin_achievements_page.dart';
import 'pages/admin_leave_notifications_page.dart';
import 'pages/notification_service.dart';
import '../chat/conversation_list_screen.dart';
import '../../core/services/chat_socket_service.dart';
import '../../core/services/api_service.dart';
import 'dart:convert';

const Color _accent = Colors.teal;

class MainAppScreen extends StatefulWidget {
  final int? initialTab;
  const MainAppScreen({Key? key, this.initialTab}) : super(key: key);

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  int _notifCount = 0;
  String _orgId = '';

  final List<Widget> _pages = [
    const HomePage(),
    const ConversationListScreen(),
    const AdminAchievementsPage(),
    SettingsPage(),
  ];

  final ValueNotifier<int> _unreadChatCount = ValueNotifier<int>(0);
  final List<StreamSubscription> _socketSubscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTab != null && widget.initialTab! < _pages.length) {
        setState(() => _currentIndex = widget.initialTab!);
      }
    });
    _loadAndFetchCount();
    // ✅ Listen for incoming FCM leave-request notifications (same pattern as student)
    adminNotifCountNotifier.addListener(_onAdminNotification);

    // Listen for chat messages and status updates (read/delivered)
    _socketSubscriptions.add(
      ChatSocketService().onNewMessage.listen((_) => _fetchChatUnreadCount()),
    );
    _socketSubscriptions.add(
      ChatSocketService().onStatusUpdate.listen((_) => _fetchChatUnreadCount()),
    );
    _socketSubscriptions.add(
      ChatSocketService().onRefreshUnread.listen((_) => _fetchChatUnreadCount()),
    );
    _socketSubscriptions.add(
      ChatSocketService().onConnectStream.listen((_) => _fetchChatUnreadCount()),
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
    adminNotifCountNotifier.removeListener(_onAdminNotification);
    for (var sub in _socketSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  // Called automatically whenever a teacher-leave-request FCM arrives
  void _onAdminNotification() => _fetchNotificationCount();

  Future<void> _loadAndFetchCount() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    _fetchNotificationCount();
  }

  Future<void> _fetchNotificationCount() async {
    if (_orgId.isEmpty) return;
    try {
      final list = await NotificationService.getTeacherLeaveNotifications(
        _orgId,
      );
      if (!mounted) return;
      // Count notifications not yet read by this org
      final unread = list.where((n) {
        final readBy = (n['readBy'] as List? ?? []);
        return !readBy.any((r) => r.toString() == _orgId);
      }).length;
      setState(() => _notifCount = unread);
    } catch (_) {}
  }

  void _openNotifications() {
    // Clear badge immediately for optimistic UX
    setState(() => _notifCount = 0);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminLeaveNotificationsPage()),
    ).then((_) {
      // Re-fetch after returning in case there are newer unread ones
      _fetchNotificationCount();
    });
  }

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
              child: IndexedStack(index: _currentIndex, children: _pages),
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
                      'Admin Panel',
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
          height: 60,
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
                Icons.emoji_events_rounded,
                Icons.emoji_events_outlined,
                'Achievements',
              ),
              _navItem(
                3,
                Icons.settings_rounded,
                Icons.settings_outlined,
                'Settings',
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
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
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
