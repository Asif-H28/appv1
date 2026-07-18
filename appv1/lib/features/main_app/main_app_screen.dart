import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/admin_achievements_page.dart';
import 'pages/admin_tutor_attendance_page.dart';
import 'pages/admin_parent_attendance_uploads_page.dart';
import 'pages/admin_payment_uploads_page.dart';
import 'pages/notification_router.dart';
import 'pages/admin_staff_salary_page.dart';
import '../support/presentation/pages/support_page.dart';
import 'pages/notification_service.dart';
import 'pages/app_update_page.dart';
import 'pages/support_staff_page.dart';
import 'pages/admin_upi_settings_page.dart';
import 'pages/admin_org_settings_page.dart';
import 'pages/admin_tuition_admissions_page.dart';
import '../chat/conversation_list_screen.dart';
import '../../core/services/chat_socket_service.dart';
import '../../core/services/api_service.dart';
import 'dart:convert';
import '../notification_studio/pages/notification_studio_page.dart';
import '../notification_studio/controllers/notification_studio_controller.dart';
import 'pages/login_page.dart';
import 'package:appv1/features/tuition_session/admin/admin_session_dashboard_screen.dart';
import 'package:appv1/core/services/feature_flag_service.dart';

const Color _accent = Colors.teal;

class MainAppScreen extends StatefulWidget {
  final int? initialTab;
  const MainAppScreen({Key? key, this.initialTab}) : super(key: key);

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  String _schoolName = 'SchoolSync';
  String _logoUrl = '';

  final List<Widget> _pages = [
    const HomePage(),
    const ConversationListScreen(showAppBar: false),
    const AdminAchievementsPage(),
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
    _fetchChatUnreadCount();
    _initFeatureFlags();
    _fetchSchoolProfile();
  }

  Future<void> _fetchSchoolProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final orgId = prefs.getString('orgId') ?? '';
    if (orgId.isNotEmpty) {
      try {
        final res = await ApiService.get('/org/school/$orgId/public');
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['success'] == true && mounted) {
            setState(() {
              _schoolName = body['data']['schoolName'] ?? 'SchoolSync';
              _logoUrl = body['data']['logoUrl'] ?? '';
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _initFeatureFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final orgId = prefs.getString('orgId') ?? '';
    if (orgId.isNotEmpty) {
      FeatureFlagService.instance.fetchAndCacheFlags(orgId);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
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
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _schoolName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
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
                _logoUrl.isNotEmpty
                    ? Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                          image: DecorationImage(
                            image: NetworkImage(_logoUrl),
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _schoolName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Admin Dashboard',
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
              padding: EdgeInsets.only(left: 12, right: 12, bottom: MediaQuery.of(context).padding.bottom + 64),
              children: [
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  title: 'Home',
                  isSelected: _currentIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.chat_bubble_rounded,
                  title: 'Chat',
                  isSelected: _currentIndex == 1,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.school_rounded,
                  title: 'Admissions',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminTuitionAdmissionsPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.upload_file_rounded,
                  title: 'Parent Attendence Uploads',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminParentAttendanceUploadsPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.receipt_long_rounded,
                  title: 'Payment Uploads',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPaymentUploadsPage(),
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: FeatureFlagService.instance.tutorSessionFeatureEnabled,
                  builder: (context, isTutorSessionEnabled, child) {
                    if (!isTutorSessionEnabled) return const SizedBox.shrink();
                    return _buildDrawerItem(
                      icon: Icons.checklist_rtl_rounded,
                      title: 'Tutor Attendance',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminTutorAttendancePage(),
                          ),
                        );
                      },
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Staff Salary',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminStaffSalaryPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.payments_rounded,
                  title: 'UPI Settings',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUpiSettingsPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.business_rounded,
                  title: 'Org Settings',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminOrgSettingsPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.emoji_events_rounded,
                  title: 'Achievements',
                  isSelected: _currentIndex == 2,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 2);
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: FeatureFlagService.instance.tuitionFeatureEnabled,
                  builder: (context, isTuitionEnabled, child) {
                    if (!isTuitionEnabled) return const SizedBox.shrink();
                    return _buildDrawerItem(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Tuition Sessions',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminSessionDashboardScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SupportPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.group_add_rounded,
                  title: 'Support Staff',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SupportStaffPage(),
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
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
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
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: const Text(
          'Are you sure you want to sign out of the dashboard?',
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
      final orgId = prefs.getString('orgId') ?? '';
      if (orgId.isNotEmpty) {
        await NotificationService.clearAdminToken(orgId: orgId);
      }
      await prefs.remove('isLoggedIn');
      await prefs.remove('userRole');
      await prefs.remove('authToken');
      await prefs.remove('userEmail');
      await prefs.remove('adminEmail');
      await prefs.remove('orgId');
      await prefs.remove('userOrg');
      await prefs.remove('orgPhone');
      await prefs.remove('orgAddress');
      await prefs.remove('orgCity');
      await prefs.remove('orgState');
      await prefs.remove('orgCountry');
      await prefs.remove('orgTeachers');
      await prefs.remove('orgNonTeaching');
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
          content: Text('Sign out failed. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
