import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../main_app/pages/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeacherSettingsPage extends StatefulWidget {
  @override
  _TeacherSettingsPageState createState() => _TeacherSettingsPageState();
}

class _TeacherSettingsPageState extends State<TeacherSettingsPage> {
  bool _notificationsEnabled = true;
  bool _isLoggingOut = false;
  final Color _accent = Colors.teal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Gradient Header ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Row(
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Preferences ──
                    _sectionLabel('Preferences'),
                    SizedBox(height: 10),
                    _settingsCard([
                      _switchTile(
                        icon: Icons.notifications_outlined,
                        iconColor: Colors.orange,
                        title: 'Notifications',
                        subtitle: 'Receive push notifications',
                        value: _notificationsEnabled,
                        onChanged: (val) =>
                            setState(() => _notificationsEnabled = val),
                      ),
                      _divider(),
                      _arrowTile(
                        icon: Icons.language_outlined,
                        iconColor: Colors.blue,
                        title: 'Language',
                        subtitle: 'English',
                        onTap: () => _comingSoon('Language settings'),
                      ),
                      _divider(),
                      _arrowTile(
                        icon: Icons.color_lens_outlined,
                        iconColor: _accent,
                        title: 'Theme',
                        subtitle: 'Light',
                        onTap: () => _comingSoon('Theme settings'),
                      ),
                    ]),
                    SizedBox(height: 24),

                    // ── About ──
                    _sectionLabel('About'),
                    SizedBox(height: 10),
                    _settingsCard([
                      _arrowTile(
                        icon: Icons.info_outline,
                        iconColor: Colors.teal,
                        title: 'App Version',
                        subtitle: '1.0.0',
                        onTap: null,
                      ),
                      _divider(),
                      _arrowTile(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: Colors.purple,
                        title: 'Privacy Policy',
                        subtitle: 'View our privacy policy',
                        onTap: () {},
                      ),
                      _divider(),
                      _arrowTile(
                        icon: Icons.description_outlined,
                        iconColor: Colors.indigo,
                        title: 'Terms of Service',
                        subtitle: 'View terms and conditions',
                        onTap: () {},
                      ),
                    ]),
                    SizedBox(height: 24),

                    // ── Account ──
                    _sectionLabel('Account'),
                    SizedBox(height: 10),
                    _settingsCard([
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Colors.red[600],
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          'Sign out of your account',
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 12,
                          ),
                        ),
                        trailing: _isLoggingOut
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.red[400],
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.chevron_right, color: Colors.red[300]),
                        onTap: _isLoggingOut ? null : _confirmLogout,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout confirm dialog ──
  void _confirmLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(Icons.logout_rounded, color: Colors.red[600]),
            ),
            SizedBox(width: 12),
            Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Yes, Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherId = prefs.getString('teacherId') ?? '';

      // ✅ Step 1 — Clear FCM token on backend BEFORE clearing local session
      if (teacherId.isNotEmpty) {
        try {
          await http.post(
            Uri.parse(
              'https://appv1backend.onrender.com/api/notification/fcm/teacher/clear',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'teacherId': teacherId}),
          );
          debugPrint('[FCM] Teacher token cleared on logout');
        } catch (e) {
          debugPrint('[FCM] Teacher token clear failed: $e');
          // ✅ Don't block logout even if this fails
        }
      }

      // ✅ Step 2 — Clear local session
      await prefs.clear();

      if (!mounted) return;
      setState(() => _isLoggingOut = false);

      // ✅ Step 3 — Navigate to login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed. Please try again.'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label.toUpperCase(),
    style: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );

  Widget _settingsCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => ListTile(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    leading: CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(icon, color: iconColor, size: 20),
    ),
    title: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
    ),
    trailing: Switch(value: value, onChanged: onChanged, activeColor: _accent),
  );

  Widget _arrowTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) => ListTile(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    leading: CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(icon, color: iconColor, size: 20),
    ),
    title: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
    ),
    trailing: onTap != null
        ? Icon(Icons.chevron_right, color: AppColors.textSecondary)
        : null,
    onTap: onTap,
  );

  Widget _divider() =>
      Divider(height: 1, indent: 68, endIndent: 16, color: Colors.grey[200]);
}
