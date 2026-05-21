import 'dart:convert';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/features/student/student_main_screen.dart';
import 'package:appv1/features/student/student_rejected_screen.dart';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../main_app/pages/login_page.dart';
import '../notification_studio/controllers/notification_studio_controller.dart';

const Color _accent = Colors.teal;

class StudentPendingScreen extends StatefulWidget {
  final String studentName;
  const StudentPendingScreen({required this.studentName});

  @override
  State<StudentPendingScreen> createState() => _StudentPendingScreenState();
}

class _StudentPendingScreenState extends State<StudentPendingScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('studentId') ?? '';

      if (studentId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please sign out and login again.')),
          );
        }
        setState(() => _isChecking = false);
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/student/profile/$studentId'),
        headers: await ApiService.getHeaders(),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final student = body['student'] as Map<String, dynamic>? ?? {};
        final status = student['joinStatus']?.toString() ?? 'pending';

        // Update local prefs
        await prefs.setString('joinStatus', status);
        if (student['classId'] != null) {
          await prefs.setString('classId', student['classId'].toString());
        }

        if (status == 'approved') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const StudentMainScreen()),
            (route) => false,
          );
        } else if (status == 'rejected') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => StudentRejectedScreen(studentName: widget.studentName)),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your request is still under review. Please wait.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to check status. Try again later.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error. Please check your internet.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            // ── Gradient header ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, _accent.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 16, 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.pending_actions_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Request Pending',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Waiting for teacher approval',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ──
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
                  child: Column(
                    children: [
                      // ── Status icon ──
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.hourglass_top_rounded,
                          color: Colors.orange[600],
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Text(
                        'Hi, ${widget.studentName}! 👋',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your request to join the class\nhas been sent successfully.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Status card ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.25),
                          ),
                        ),
                        child: Column(
                          children: [
                            _statusRow(
                              Icons.pending_actions_rounded,
                              Colors.orange,
                              'Status',
                              'Pending Approval',
                            ),
                            const SizedBox(height: 12),
                            _statusRow(
                              Icons.info_outline_rounded,
                              _accent,
                              'Next Step',
                              'Wait for your teacher to approve your request',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Info banner ──
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: _accent.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: _accent,
                              size: 15,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You\'ll be notified once your teacher approves your request. Please check back later.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Check status button ──
                      GestureDetector(
                        onTap: _checkStatus,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isChecking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Check Approval Status',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Sign out button ──
                      GestureDetector(
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          NotificationStudioController().disconnect();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => LoginPage()),
                              (route) => false,
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(IconData icon, Color color, String label, String value) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
