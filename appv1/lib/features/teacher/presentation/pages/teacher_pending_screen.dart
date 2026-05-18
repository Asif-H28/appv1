import 'package:appv1/core/constants/api_constants.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import 'dart:convert';
import '../../../../core/constants/app_colors.dart';
import '../../../main_app/pages/login_page.dart';
import 'teacher_main_screen.dart';

class TeacherPendingScreen extends StatefulWidget {
  final String teacherName;
  final String orgId;

  const TeacherPendingScreen({required this.teacherName, required this.orgId});

  @override
  _TeacherPendingScreenState createState() => _TeacherPendingScreenState();
}

class _TeacherPendingScreenState extends State<TeacherPendingScreen>
    with SingleTickerProviderStateMixin {
  final Color _accent = Colors.teal;
  bool _isChecking = false;
  bool _isLoggingOut = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();

    // â”€â”€ Pulse animation for the pending icon â”€â”€
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // â”€â”€ Auto-check every 30 seconds â”€â”€
    _autoCheckTimer = Timer.periodic(
      Duration(seconds: 30),
      (_) => _checkStatus(),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherId = prefs.getString('teacherId') ?? '';
      final token = prefs.getString('authToken') ?? '';

      if (teacherId.isEmpty) {
        setState(() => _isChecking = false);
        return;
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/teacher/$teacherId/profile',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final teacherData = body['teacher'] as Map<String, dynamic>? ?? {};
      final isVerified = teacherData['verified'] == true;

      setState(() => _isChecking = false);

      if (isVerified) {
        await prefs.setBool('teacherVerified', true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'ðŸŽ‰ You have been approved! Welcome aboard.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TeacherMainScreen()),
        );
      } else {
        // Still pending
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Still pending. Please check back later.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not check status. Please try again.'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(Icons.logout_rounded, color: Colors.red[600]),
            ),
            SizedBox(width: 12),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
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
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    setState(() => _isLoggingOut = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userRole');
    await prefs.remove('authToken');
    await prefs.remove('userEmail');
    await prefs.remove('teacherId');
    await prefs.remove('teacherName');
    await prefs.remove('orgId');
    await prefs.remove('userOrg');
    await prefs.remove('teacherVerified');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // â”€â”€ Decorative blobs â”€â”€
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.07),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // â”€â”€ Top bar â”€â”€
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.sync_alt,
                              color: _accent,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'SchoolSync',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _confirmLogout,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.red[600],
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Column(
                      children: [
                        // â”€â”€ Pulsing pending icon â”€â”€
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange.withOpacity(0.08),
                                ),
                              ),
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange.withOpacity(0.13),
                                ),
                              ),
                              Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange,
                                      Colors.orange.withOpacity(0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.35),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.hourglass_top_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 28),

                        Text(
                          'Approval Pending',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 10),

                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.6,
                            ),
                            children: [
                              TextSpan(text: 'Hi '),
                              TextSpan(
                                text: widget.teacherName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ', your join request has been submitted. Your account is awaiting approval from your organization admin.',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 28),

                        // â”€â”€ Status card â”€â”€
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              _statusStep(
                                icon: Icons.check_circle_rounded,
                                color: Colors.green,
                                title: 'Account Created',
                                subtitle: 'Your account is set up',
                                done: true,
                              ),
                              _statusDivider(),
                              _statusStep(
                                icon: Icons.send_rounded,
                                color: Colors.green,
                                title: 'Join Request Sent',
                                subtitle: 'Request submitted to admin',
                                done: true,
                              ),
                              _statusDivider(),
                              _statusStep(
                                icon: Icons.admin_panel_settings_rounded,
                                color: Colors.orange,
                                title: 'Admin Review',
                                subtitle: 'Waiting for approval',
                                done: false,
                                isActive: true,
                              ),
                              _statusDivider(),
                              _statusStep(
                                icon: Icons.login_rounded,
                                color: Colors.grey,
                                title: 'Access Granted',
                                subtitle: 'You can login to the portal',
                                done: false,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 28),

                        // â”€â”€ Info box â”€â”€
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _accent.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: _accent,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Contact your organization admin at ${widget.orgId} to speed up the approval process.',
                                  style: TextStyle(
                                    color: _accent,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 28),

                        // â”€â”€ Check status button â”€â”€
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isChecking ? null : _checkStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _accent.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: 200),
                              child: _isChecking
                                  ? Row(
                                      key: ValueKey('checking'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Checking Status...',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      key: ValueKey('idle'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.refresh_rounded, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Check Approval Status',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),

                        Text(
                          'Auto-checks every 30 seconds',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusStep({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool done,
    bool isActive = false,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? color.withOpacity(0.15)
                : isActive
                ? Colors.orange.withOpacity(0.15)
                : Colors.grey.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            color: done
                ? color
                : isActive
                ? Colors.orange
                : Colors.grey[400],
            size: 20,
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: done || isActive
                      ? AppColors.textPrimary
                      : Colors.grey[400],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: done || isActive
                      ? AppColors.textSecondary
                      : Colors.grey[350],
                ),
              ),
            ],
          ),
        ),
        if (done)
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
        if (isActive)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: Colors.orange,
              strokeWidth: 2,
            ),
          ),
      ],
    );
  }

  Widget _statusDivider() => Padding(
    padding: EdgeInsets.only(left: 19, top: 4, bottom: 4),
    child: Container(
      width: 2,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(1),
      ),
    ),
  );
}

