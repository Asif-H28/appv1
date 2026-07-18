import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:appv1/features/student/student_home_page.dart';
import 'package:appv1/features/student/student_profile_page.dart';
import 'package:appv1/features/student/student_achievements_page.dart';
import '../teacher/presentation/pages/org_transport_status_page.dart';
import '../notification_studio/pages/notification_studio_page.dart';
import '../notification_studio/controllers/notification_studio_controller.dart';
import '../main_app/pages/login_page.dart';
import '../main_app/pages/app_update_page.dart';
import 'student_logout_modal.dart';
import '../support/presentation/pages/support_page.dart';
import 'package:appv1/core/services/api_service.dart';
import 'child_lock_service.dart';
import 'child_lock_settings_page.dart';
import 'student_fee_payment_page.dart';
import 'student_theme_manager.dart';

class StudentMainScreen extends StatefulWidget {
  final int initialTab;
  const StudentMainScreen({this.initialTab = 0});

  @override
  _StudentMainScreenState createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  late int _currentTab;
  String _orgId = '';
  bool _isChildLockEnabled = false;
  String _schoolName = 'SchoolSync';
  String _logoUrl = '';

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final childLock = await ChildLockService.instance.isChildLockEnabled();
    final orgId = prefs.getString('orgId') ?? '';
    if (mounted) {
      setState(() {
        _orgId = orgId;
        _isChildLockEnabled = childLock;
      });
    }
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

  final List<Widget> _pages = [
    StudentHomePage(),
    StudentAchievementsPage(),
    StudentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, child) {
        return PopScope(
          canPop: !_isChildLockEnabled,
          onPopInvoked: (didPop) {
            if (didPop) return;
            if (_isChildLockEnabled && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Child lock is enabled. Cannot exit.'),
                ),
              );
            }
          },
          child: Scaffold(
            backgroundColor: theme.background,
            drawer: _buildDrawer(theme),
            body: AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
              child: Column(
                children: [
                  _buildHeader(theme),
                  Expanded(
                    child: IndexedStack(index: _currentTab, children: _pages),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNav(theme),
          ),
        );
      },
    );
  }

  Widget _buildHeader(StudentThemeConfig theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.gradientEnd],
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
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                      'Student Portal',
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
                            borderRadius: BorderRadius.circular(3),
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
                  if (_orgId.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrgTransportStatusPage(orgId: _orgId),
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
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

  Widget _buildBottomNav(StudentThemeConfig theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _navItem(
                0,
                Icons.home_rounded,
                Icons.home_outlined,
                'Home',
                theme,
              ),
              _navItem(
                1,
                Icons.emoji_events_rounded,
                Icons.emoji_events_outlined,
                'Achievements',
                theme,
              ),
              _navItem(
                2,
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profile',
                theme,
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
    String label,
    StudentThemeConfig theme,
  ) {
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
              color: isActive ? theme.primary : theme.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? theme.primary : theme.textSecondary,
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(StudentThemeConfig theme) {
    return Drawer(
      backgroundColor: theme.background,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primary, theme.gradientEnd],
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
                          Icons.school_rounded,
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
                        'Student Portal',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
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
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).padding.bottom + 64,
              ),
              children: [
                _buildDrawerItem(
                  theme: theme,
                  icon: Icons.home_rounded,
                  title: 'Home',
                  isSelected: _currentTab == 0,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentTab = 0);
                  },
                ),
                _buildDrawerItem(
                  theme: theme,
                  icon: Icons.emoji_events_rounded,
                  title: 'Achievements',
                  isSelected: _currentTab == 1,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentTab = 1);
                  },
                ),
                _buildDrawerItem(
                  theme: theme,
                  icon: Icons.person_rounded,
                  title: 'Profile & Settings',
                  isSelected: _currentTab == 2,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentTab = 2);
                  },
                ),
                if (_orgId.isNotEmpty)
                  _buildDrawerItem(
                    theme: theme,
                    icon: Icons.directions_bus_rounded,
                    title: 'Bus Tracker',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrgTransportStatusPage(orgId: _orgId),
                        ),
                      );
                    },
                  ),
                _buildDrawerItem(
                  theme: theme,
                  icon: Icons.payment_rounded,
                  title: 'View Fee Payment',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentFeePaymentPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  theme: theme,
                  icon: Icons.help_outline_rounded,
                  title: 'Help',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  theme: theme,
                  icon: Icons.system_update_rounded,
                  title: 'App Update',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppUpdatePage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  theme: theme,
                  icon: Icons.lock_outline_rounded,
                  title: 'Child Lock',
                  isSelected: false,
                  onTap: () async {
                    Navigator.pop(context); // Close drawer
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChildLockSettingsPage(),
                      ),
                    );
                    _loadData(); // Refresh state after returning
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Divider(height: 1, color: theme.dividerColor),
                ),
                _buildDrawerItem(
                  theme: theme,
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
    required StudentThemeConfig theme,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final activeColor = theme.primary;
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
          color: isSelected ? activeColor : (iconColor ?? theme.textSecondary),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? activeColor : (textColor ?? theme.textPrimary),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    if (_isChildLockEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Child lock is enabled. Disable it from settings to logout.',
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => StudentLogoutModal(),
    );
    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('studentId') ?? '';

    if (studentId.isNotEmpty) {
      try {
        await ApiService.post(
          Uri.parse(
            '${ApiConstants.apiBaseUrl}/notification/fcm/student/clear',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'studentId': studentId}),
        );
        debugPrint('[FCM] Token cleared on logout');
      } catch (e) {
        debugPrint('[FCM] Token clear failed: $e');
      }
    }

    await prefs.clear();
    NotificationStudioController().disconnect();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }
}
