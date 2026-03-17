import 'package:appv1/features/main_app/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── Gradient Header ───
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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

          // ─── White Body with rounded top corners ───
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Preferences Section ──
                    _sectionLabel('Preferences'),
                    SizedBox(height: 10),
                    _buildSettingsCard(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.notifications_outlined,
                          iconColor: Colors.orange,
                          title: 'Notifications',
                          subtitle: 'Receive push notifications',
                          value: _notificationsEnabled,
                          onChanged: (val) =>
                              setState(() => _notificationsEnabled = val),
                        ),
                        _divider(),
                        _buildArrowTile(
                          icon: Icons.language_outlined,
                          iconColor: Colors.blue,
                          title: 'Language',
                          subtitle: 'English',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Language settings coming soon!'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                        _divider(),
                        _buildArrowTile(
                          icon: Icons.color_lens_outlined,
                          iconColor: AppColors.primary,
                          title: 'Theme',
                          subtitle: 'Light',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Theme settings coming soon!'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // ── About Section ──
                    _sectionLabel('About'),
                    SizedBox(height: 10),
                    _buildSettingsCard(
                      children: [
                        _buildArrowTile(
                          icon: Icons.info_outline,
                          iconColor: Colors.teal,
                          title: 'App Version',
                          subtitle: '1.0.0',
                          onTap: null,
                        ),
                        _divider(),
                        _buildArrowTile(
                          icon: Icons.privacy_tip_outlined,
                          iconColor: Colors.purple,
                          title: 'Privacy Policy',
                          subtitle: 'View our privacy policy',
                          onTap: () {},
                        ),
                        _divider(),
                        _buildArrowTile(
                          icon: Icons.description_outlined,
                          iconColor: Colors.indigo,
                          title: 'Terms of Service',
                          subtitle: 'View terms and conditions',
                          onTap: () {},
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // ── Account Section ──
                    _sectionLabel('Account'),
                    SizedBox(height: 10),
                    _buildSettingsCard(
                      children: [
                        // ── Logout tile ──
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
                              : Icon(
                                  Icons.chevron_right,
                                  color: Colors.red[300],
                                ),
                          onTap: _isLoggingOut ? null : _confirmLogout,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Logout: show confirm dialog ───
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
              Navigator.pop(ctx); // close dialog first
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

  // ─── Logout: clear prefs + navigate to LoginPage ───
  Future<void> _performLogout() async {
    setState(() => _isLoggingOut = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all auth-related keys, preserve non-auth data if needed
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

      if (!mounted) return;
      setState(() => _isLoggingOut = false);

      // Navigate to LoginPage and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false, // removes entire back stack
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Logout failed. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ─── Helpers ───
  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildArrowTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
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
  }

  Widget _divider() =>
      Divider(height: 1, indent: 68, endIndent: 16, color: Colors.grey[200]);
}
