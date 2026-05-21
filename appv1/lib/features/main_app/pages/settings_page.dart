import 'package:appv1/features/main_app/pages/login_page.dart';
import 'package:appv1/features/main_app/pages/notification_service.dart';
import 'package:appv1/features/main_app/pages/pwa_notification_panel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../notification_studio/controllers/notification_studio_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ── Colours matching the screenshot ───────────────────
  static const _teal = Color(0xFF00796B);
  static const _signOutBg = Color(0xFF8B3A1E); // deep burnt-sienna/brown
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _cardBg = Color(0xFFF9FAFB);
  static const _borderColor = Color(0xFFE5E7EB);

  String _orgName = '';
  String _adminEmail = '';
  String _renewalDate = 'September 24, 2025';
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _orgName = prefs.getString('userOrg') ?? 'Your Organization';
      _adminEmail =
          prefs.getString('adminEmail') ??
          prefs.getString('userEmail') ??
          '';
    });
  }

  // ── Logout ────────────────────────────────────────────
  void _confirmLogout() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            content: const Text(
              'Are you sure you want to sign out of the dashboard?',
              style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx, true);
                  _performLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _signOutBg,
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
  }

  Future<void> _performLogout() async {
    setState(() => _isLoggingOut = true);
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
        const SnackBar(
          content: Text('Sign out failed. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final navBottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title header ──────────────────────────────
            _buildHeader(),

            // ── Scrollable content ────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 32 + navBottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Subscription card ─────────────────
                    _buildSubscriptionCard(),
                    const SizedBox(height: 18),

                    // ── Push Notification Card ────────────
                    const PwaNotificationPanel(),
                    const SizedBox(height: 24),

                    // ── Sign Out button ───────────────────
                    _buildSignOutButton(),

                    const SizedBox(height: 36),

                    // ── Footer ────────────────────────────
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage your institutional identity and\nsecurity credentials.',
            style: TextStyle(
              fontSize: 13.5,
              color: _textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ── Subscription card ──────────────────────────────────
  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + icon row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT TIER',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _teal,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Subscription\nActive',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _teal.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: _teal,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: _borderColor),
          const SizedBox(height: 14),

          // Renewal date
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: _textSecondary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Renewal Date: $_renewalDate',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sign Out button ────────────────────────────────────
  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoggingOut ? null : _confirmLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: _signOutBg,
          disabledBackgroundColor: _signOutBg.withOpacity(0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
        child: _isLoggingOut
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Sign Out of Dashboard',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────
  Widget _buildFooter() {
    return Center(
      child: Text(
        'SCHOOLSYNC ADMIN PANEL © 2024  •  INSTITUTIONAL\nVERSION 4.8.2',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _textSecondary.withOpacity(0.7),
          letterSpacing: 0.4,
          height: 1.6,
        ),
      ),
    );
  }
}
