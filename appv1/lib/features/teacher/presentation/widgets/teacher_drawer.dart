import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/network/dio_http_adapter.dart' as http;
import '../../../notification_studio/controllers/notification_studio_controller.dart';
import '../../../main_app/pages/login_page.dart';
import '../../../main_app/pages/app_update_page.dart';
import '../../../support/presentation/pages/support_page.dart';
import '../pages/teacher_attendance_page.dart';
import '../pages/teacher_settings_page.dart';
import '../pages/teacher_main_screen.dart';

enum TeacherDrawerRoute {
  home,
  chat,
  classroom,
  achievements,
  dashboard,
  attendance,
  help,
  settings,
  update,
  logout
}

class TeacherDrawer extends StatefulWidget {
  final TeacherDrawerRoute currentRoute;
  final ValueChanged<int>? onTabSelected;

  const TeacherDrawer({
    super.key,
    required this.currentRoute,
    this.onTabSelected,
  });

  @override
  State<TeacherDrawer> createState() => _TeacherDrawerState();
}

class _TeacherDrawerState extends State<TeacherDrawer> {
  @override
  Widget build(BuildContext context) {
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
                  isSelected: widget.currentRoute == TeacherDrawerRoute.home,
                  onTap: () => _handleMainTabSelection(context, 0, TeacherDrawerRoute.home),
                ),
                _buildDrawerItem(
                  icon: Icons.chat_bubble_rounded,
                  title: 'Chat',
                  isSelected: widget.currentRoute == TeacherDrawerRoute.chat,
                  onTap: () => _handleMainTabSelection(context, 1, TeacherDrawerRoute.chat),
                ),
                _buildDrawerItem(
                  icon: Icons.class_rounded,
                  title: 'Classroom',
                  isSelected: widget.currentRoute == TeacherDrawerRoute.classroom,
                  onTap: () => _handleMainTabSelection(context, 2, TeacherDrawerRoute.classroom),
                ),
                _buildDrawerItem(
                  icon: Icons.emoji_events_rounded,
                  title: 'Achievements',
                  isSelected: widget.currentRoute == TeacherDrawerRoute.achievements,
                  onTap: () => _handleMainTabSelection(context, 3, TeacherDrawerRoute.achievements),
                ),
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  isSelected: widget.currentRoute == TeacherDrawerRoute.dashboard,
                  onTap: () => _handleMainTabSelection(context, 4, TeacherDrawerRoute.dashboard),
                ),
                _buildDrawerItem(
                  icon: Icons.how_to_reg_rounded,
                  title: 'My Attendance',
                  isSelected: widget.currentRoute == TeacherDrawerRoute.attendance,
                  onTap: () => _handleRouteSelection(
                    context,
                    TeacherDrawerRoute.attendance,
                    () => const TeacherAttendancePage(),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help',
                  isSelected: widget.currentRoute == TeacherDrawerRoute.help,
                  onTap: () => _handleRouteSelection(
                    context,
                    TeacherDrawerRoute.help,
                    () => const SupportPage(),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  isSelected: widget.currentRoute == TeacherDrawerRoute.settings,
                  onTap: () => _handleRouteSelection(
                    context,
                    TeacherDrawerRoute.settings,
                    () => TeacherSettingsPage(),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.system_update_rounded,
                  title: 'App Update',
                  isSelected: widget.currentRoute == TeacherDrawerRoute.update,
                  onTap: () => _handleRouteSelection(
                    context,
                    TeacherDrawerRoute.update,
                    () => const AppUpdatePage(),
                  ),
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
                    _logout(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMainTabSelection(BuildContext context, int index, TeacherDrawerRoute route) {
    Navigator.pop(context); // Close drawer
    if (widget.currentRoute != route && widget.onTabSelected != null) {
      widget.onTabSelected!(index);
    } else if (widget.currentRoute != route) {
      // We are not on the main screen, so we need to navigate there and select the tab
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => TeacherMainScreen(initialTab: index)),
        (r) => false,
      );
    }
  }

  void _handleRouteSelection(BuildContext context, TeacherDrawerRoute route, Widget Function() pageBuilder) {
    Navigator.pop(context); // Close drawer
    if (widget.currentRoute != route) {
      if (widget.currentRoute == TeacherDrawerRoute.home ||
          widget.currentRoute == TeacherDrawerRoute.chat ||
          widget.currentRoute == TeacherDrawerRoute.classroom ||
          widget.currentRoute == TeacherDrawerRoute.achievements ||
          widget.currentRoute == TeacherDrawerRoute.dashboard) {
        // We are coming from main screen tabs, just push
        Navigator.push(context, MaterialPageRoute(builder: (_) => pageBuilder()));
      } else {
        // We are on another pushed page, replace it
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => pageBuilder()));
      }
    }
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

  Future<void> _logout(BuildContext context) async {
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
}
