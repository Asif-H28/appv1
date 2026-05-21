import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../notification_studio/controllers/notification_studio_controller.dart';
import '../../../main_app/pages/login_page.dart';
import 'package:appv1/features/main_app/pages/manage_vehicles_page.dart';
import 'teacher_profile_section.dart';
import 'teacher_leave_section.dart';

class TeacherSettingsPage extends StatefulWidget {
  @override
  _TeacherSettingsPageState createState() => _TeacherSettingsPageState();
}

class _TeacherSettingsPageState extends State<TeacherSettingsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoggingOut = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.red[600],
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _performLogout();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
      if (teacherId.isNotEmpty) {
        try {
          await http.post(
            Uri.parse(
              '${ApiConstants.apiBaseUrl}/notification/fcm/teacher/clear',
            ),
            headers: await ApiService.getHeaders(),
            body: jsonEncode({'teacherId': teacherId}),
          );
        } catch (_) {}
      }
      await prefs.clear();
      NotificationStudioController().disconnect();
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Logout failed. Please try again.'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.teal,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: Colors.teal,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Leave'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  child: const TeacherProfileSection(),
                ),
                const TeacherLeaveSection(),
              ],
            ),
          ),
        ],
      ),
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
                      'Teacher Portal',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              if (_isLoggingOut)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                GestureDetector(
                  onTap: _confirmLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[600]!.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

