import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../onboarding/presentation/pages/landing_page.dart';
import '../../student/student_join_org_page.dart';
import '../../student/student_main_screen.dart';
import '../../student/student_pending_screen.dart';
import '../../student/student_rejected_screen.dart';
import '../../teacher/presentation/pages/teacher_main_screen.dart';
import '../../teacher/presentation/pages/teacher_pending_screen.dart';
import '../main_app_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Colors.teal;
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging)
        setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            Container(
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
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.sync_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SchoolSync',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              Text(
                                'School Management Platform',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Welcome back 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Sign in to continue to your organization',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12.5,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: _accent,
                          unselectedLabelColor: Colors.white.withOpacity(0.85),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          padding: EdgeInsets.all(3),
                          dividerColor: Colors.transparent,
                          tabs: [
                            _tab(
                              Icons.admin_panel_settings_outlined,
                              'Admin',
                              0,
                            ),
                            _tab(Icons.school_outlined, 'Teacher', 1),
                            _tab(Icons.person_outline, 'Student', 2),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                clipBehavior: Clip.antiAlias,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _AdminLoginTab(accent: _accent),
                    _TeacherLoginTab(accent: _accent),
                    _StudentLoginTab(accent: _accent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(IconData icon, String label, int index) {
    final active = _selectedTab == index;
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────

Widget _loginLabel(String text) => Text(
  text,
  style: TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  ),
);

InputDecoration _loginFieldDeco({
  required String hint,
  required IconData icon,
  required Color accent,
  Widget? suffixIcon,
}) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(
    color: AppColors.textSecondary.withOpacity(0.5),
    fontSize: 13,
  ),
  prefixIcon: Icon(icon, color: accent, size: 16),
  suffixIcon: suffixIcon,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: BorderSide(color: Colors.grey[200]!),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: BorderSide(color: Colors.grey[200]!),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: BorderSide(color: accent.withOpacity(0.5), width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
  ),
  filled: true,
  fillColor: Colors.white,
  isDense: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
  errorStyle: TextStyle(color: Colors.red[400], fontSize: 11),
);

Widget _signInBtn({
  required Color accent,
  required bool isLoading,
  required String label,
  required VoidCallback? onTap,
}) => Theme(
  data: ThemeData(
    colorScheme: ColorScheme.light(primary: accent, onPrimary: Colors.white),
  ),
  child: SizedBox(
    width: double.infinity,
    height: 46,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: accent.withOpacity(0.45),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Signing in...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ],
            ),
    ),
  ),
);

Widget _bottomCard({
  required Color accent,
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) => GestureDetector(
  onTap: onTap,
  child: Container(
    padding: EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: accent.withOpacity(0.04),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: accent.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(icon, color: accent, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: accent),
      ],
    ),
  ),
);

Widget _divider(String label) => Row(
  children: [
    Expanded(child: Divider(color: Colors.grey[200]!, thickness: 1)),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    Expanded(child: Divider(color: Colors.grey[200]!, thickness: 1)),
  ],
);

void _showSnack(BuildContext ctx, String msg, Color color) {
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    ),
  );
}

// ─────────────────────────────────────────────────────────
// ADMIN LOGIN TAB
// ─────────────────────────────────────────────────────────

class _AdminLoginTab extends StatefulWidget {
  final Color accent;
  const _AdminLoginTab({required this.accent});
  @override
  __AdminLoginTabState createState() => __AdminLoginTabState();
}

class __AdminLoginTabState extends State<_AdminLoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://appv1backend.onrender.com/api/org/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminEmail': _emailCtrl.text.trim(),
          'adminPassword': _passCtrl.text,
        }),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userRole', 'admin');
        await prefs.setString('userEmail', _emailCtrl.text.trim());
        await prefs.setString('authToken', body['token'] ?? '');
        final org = body['organization'] as Map<String, dynamic>? ?? {};
        await prefs.setString('orgId', org['orgId']?.toString() ?? '');
        await prefs.setString('userOrg', org['name']?.toString() ?? '');
        await prefs.setString(
          'adminEmail',
          org['adminEmail']?.toString() ?? '',
        );
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnack(context, 'Welcome back, Admin!', Colors.green[600]!);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainAppScreen(initialTab: 0)),
        );
      } else {
        setState(() => _isLoading = false);
        _showSnack(
          context,
          body['message']?.toString() ?? 'Login failed.',
          Colors.red[600]!,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(context, 'No internet connection.', Colors.red[600]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _loginLabel('EMAIL ADDRESS'),
            SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              cursorColor: widget.accent,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
              decoration: _loginFieldDeco(
                hint: 'admin@organization.com',
                icon: Icons.email_outlined,
                accent: widget.accent,
              ),
            ),
            SizedBox(height: 12),
            _loginLabel('PASSWORD'),
            SizedBox(height: 6),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              cursorColor: widget.accent,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
              decoration: _loginFieldDeco(
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                accent: widget.accent,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 17,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                ),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: widget.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            _signInBtn(
              accent: widget.accent,
              isLoading: _isLoading,
              label: 'Sign In',
              onTap: _isLoading ? null : _login,
            ),
            SizedBox(height: 24),
            _divider('New to SchoolSync?'),
            SizedBox(height: 14),
            _bottomCard(
              accent: widget.accent,
              icon: Icons.add_business_rounded,
              title: 'Create or Join Organization',
              subtitle: 'Set up your school on SchoolSync',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LandingPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TEACHER LOGIN TAB
// ─────────────────────────────────────────────────────────

class _TeacherLoginTab extends StatefulWidget {
  final Color accent;
  const _TeacherLoginTab({required this.accent});
  @override
  __TeacherLoginTabState createState() => __TeacherLoginTabState();
}

class __TeacherLoginTabState extends State<_TeacherLoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://appv1backend.onrender.com/api/teacher/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'password': _passCtrl.text,
        }),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode != 200 || body['success'] != true) {
        setState(() => _isLoading = false);
        _showSnack(
          context,
          body['message']?.toString() ?? 'Login failed.',
          Colors.red[600]!,
        );
        return;
      }

      final teacher = body['teacher'] as Map<String, dynamic>? ?? {};
      final teacherId = teacher['teacherId']?.toString() ?? '';
      final token = body['token']?.toString() ?? '';

      final profileRes = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/teacher/$teacherId/profile',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (!mounted) return;
      final profileBody = jsonDecode(profileRes.body) as Map<String, dynamic>;
      final profile =
          profileBody['teacher'] as Map<String, dynamic>? ?? teacher;
      final isVerified = profile['verified'] == true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRole', 'teacher');
      await prefs.setString('userEmail', _emailCtrl.text.trim());
      await prefs.setString('authToken', token);
      await prefs.setString('teacherId', teacherId);
      await prefs.setString('teacherName', profile['name']?.toString() ?? '');
      await prefs.setString('orgId', profile['orgId']?.toString() ?? '');
      await prefs.setBool('teacherVerified', isVerified);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (isVerified) {
        _showSnack(
          context,
          'Welcome, ${profile['name'] ?? 'Teacher'}! 👋',
          Colors.teal[600]!,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TeacherMainScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherPendingScreen(
              teacherName: profile['name']?.toString() ?? 'Teacher',
              orgId: profile['orgId']?.toString() ?? '',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(context, 'No internet connection.', Colors.red[600]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _loginLabel('EMAIL ADDRESS'),
            SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              cursorColor: widget.accent,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
              decoration: _loginFieldDeco(
                hint: 'teacher@school.com',
                icon: Icons.email_outlined,
                accent: widget.accent,
              ),
            ),
            SizedBox(height: 12),
            _loginLabel('PASSWORD'),
            SizedBox(height: 6),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              cursorColor: widget.accent,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
              decoration: _loginFieldDeco(
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                accent: widget.accent,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 17,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                ),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: widget.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            _signInBtn(
              accent: widget.accent,
              isLoading: _isLoading,
              label: 'Sign In as Teacher',
              onTap: _isLoading ? null : _login,
            ),
            SizedBox(height: 24),
            _divider('New to SchoolSync?'),
            SizedBox(height: 14),
            _bottomCard(
              accent: widget.accent,
              icon: Icons.add_business_rounded,
              title: 'Create or Join Organization',
              subtitle: 'Set up your school on SchoolSync',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LandingPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// STUDENT LOGIN TAB  ← all debug logs are here
// ─────────────────────────────────────────────────────────

class _StudentLoginTab extends StatefulWidget {
  final Color accent;
  const _StudentLoginTab({required this.accent});
  @override
  __StudentLoginTabState createState() => __StudentLoginTabState();
}

class __StudentLoginTabState extends State<_StudentLoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://appv1backend.onrender.com/api/student/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'password': _passCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      // ── LOG 1: Raw HTTP response ──────────────────────
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════╗');
      debugPrint('║       STUDENT LOGIN RAW RESPONSE         ║');
      debugPrint('╠══════════════════════════════════════════╣');
      debugPrint('║ Status Code : ${res.statusCode}');
      debugPrint('║ Raw Body    : ${res.body}');
      debugPrint('╚══════════════════════════════════════════╝');

      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        debugPrint('❌ JSON decode failed for body: ${res.body}');
        _showSnack(context, 'Unexpected server response.', Colors.red[600]!);
        return;
      }

      if (res.statusCode != 200 || body['success'] != true) {
        debugPrint('❌ Login failed: ${body['message'] ?? body['error']}');
        _showSnack(
          context,
          body['message']?.toString() ??
              body['error']?.toString() ??
              'Login failed.',
          Colors.red[600]!,
        );
        return;
      }

      final student =
          body['student'] as Map<String, dynamic>? ??
          body['data'] as Map<String, dynamic>? ??
          {};

      // ── LOG 2: Parsed student object ──────────────────
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════╗');
      debugPrint('║         PARSED STUDENT OBJECT            ║');
      debugPrint('╠══════════════════════════════════════════╣');
      debugPrint('║ studentId   : ${student['studentId']}');
      debugPrint('║ name        : ${student['name']}');
      debugPrint('║ email       : ${student['email']}');
      debugPrint('║ joinStatus  : ${student['joinStatus']}');
      debugPrint('║ classId     : ${student['classId']}');
      debugPrint('║ orgId       : ${student['orgId']}');
      debugPrint('║ tempOrgId   : ${student['tempOrgId']}');
      debugPrint('║ tempOrg     : ${student['tempOrg']}');
      debugPrint('╚══════════════════════════════════════════╝');

      // ── Save to prefs ──
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRole', 'student');
      await prefs.setString(
        'studentId',
        student['studentId']?.toString() ?? '',
      );
      await prefs.setString('studentName', student['name']?.toString() ?? '');
      await prefs.setString('studentEmail', student['email']?.toString() ?? '');
      await prefs.setString('authToken', body['token']?.toString() ?? '');
      await prefs.setString('classId', student['classId']?.toString() ?? '');
      await prefs.setString(
        'joinStatus',
        student['joinStatus']?.toString() ?? 'none',
      );
      await prefs.setString('studentName', student['name']?.toString() ?? '');

      // ── Save tempOrg ──
      final tempOrg = student['tempOrg'] as Map<String, dynamic>?;

      // ── LOG 3: tempOrg saving ─────────────────────────
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════╗');
      debugPrint('║           SAVING TEMP ORG                ║');
      debugPrint('╠══════════════════════════════════════════╣');
      debugPrint('║ tempOrg is null?  : ${tempOrg == null}');
      debugPrint('║ tempOrg value     : $tempOrg');

      if (tempOrg != null) {
        await prefs.setString('tempOrg', jsonEncode(tempOrg));
        await prefs.setString('tempOrgId', tempOrg['orgId']?.toString() ?? '');
        await prefs.setString(
          'tempOrgName',
          tempOrg['orgName']?.toString() ?? '',
        );
        debugPrint('║ ✅ Saved tempOrgId   : ${tempOrg['orgId']}');
        debugPrint('║ ✅ Saved tempOrgName : ${tempOrg['orgName']}');
      } else {
        final flatOrgId = student['tempOrgId']?.toString() ?? '';
        debugPrint('║ ⚠️  tempOrg null, flatOrgId : $flatOrgId');
        if (flatOrgId.isNotEmpty) {
          await prefs.setString('tempOrgId', flatOrgId);
          debugPrint('║ ✅ Saved flat tempOrgId : $flatOrgId');
        } else {
          debugPrint('║ ❌ No org data found to save!');
        }
      }
      debugPrint('╚══════════════════════════════════════════╝');

      // ── LOG 4: All saved prefs ────────────────────────
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════╗');
      debugPrint('║         ALL SAVED PREFS AFTER LOGIN      ║');
      debugPrint('╠══════════════════════════════════════════╣');
      final allKeys = prefs.getKeys();
      for (final k in allKeys) {
        debugPrint('║  $k = ${prefs.get(k)}');
      }
      debugPrint('╚══════════════════════════════════════════╝');

      if (!mounted) return;

      final joinStatus = student['joinStatus']?.toString() ?? 'none';
      final classId = student['classId']?.toString() ?? '';
      final studentName = student['name']?.toString() ?? 'Student';

      // ── LOG 5: Routing decision ───────────────────────
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════╗');
      debugPrint('║           ROUTING DECISION               ║');
      debugPrint('╠══════════════════════════════════════════╣');
      debugPrint('║ joinStatus  : $joinStatus');
      debugPrint('║ classId     : $classId');
      debugPrint('║ studentName : $studentName');
      debugPrint('╚══════════════════════════════════════════╝');

      switch (joinStatus) {
        case 'approved':
          if (classId.isNotEmpty) {
            debugPrint('➡️  Routing to: StudentMainScreen');
            _showSnack(
              context,
              'Welcome back, $studentName! 👋',
              Colors.green[600]!,
            );
            Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(builder: (_) => StudentMainScreen()),
            );
          } else {
            debugPrint(
              '➡️  Routing to: StudentJoinOrgPage (approved but no classId)',
            );
            Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(builder: (_) => StudentJoinOrgPage()),
            );
          }
          break;

        case 'pending':
          debugPrint('➡️  Routing to: StudentPendingScreen');
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(
              builder: (_) => StudentPendingScreen(studentName: studentName),
            ),
          );
          break;

        case 'rejected':
          debugPrint('➡️  Routing to: StudentRejectedScreen');
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(
              builder: (_) => StudentRejectedScreen(studentName: studentName),
            ),
          );
          break;

        default:
          debugPrint(
            '➡️  Routing to: StudentJoinOrgPage (joinStatus=$joinStatus)',
          );
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(builder: (_) => StudentJoinOrgPage()),
          );
      }
    } catch (e, stack) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('❌ STUDENT LOGIN EXCEPTION: $e');
      debugPrint('❌ STACK TRACE: $stack');
      _showSnack(context, 'No internet connection.', Colors.red[600]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _loginLabel('EMAIL ADDRESS'),
            SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              cursorColor: widget.accent,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
              decoration: _loginFieldDeco(
                hint: 'student@email.com',
                icon: Icons.email_outlined,
                accent: widget.accent,
              ),
            ),
            SizedBox(height: 12),
            _loginLabel('PASSWORD'),
            SizedBox(height: 6),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              cursorColor: widget.accent,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
              decoration: _loginFieldDeco(
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                accent: widget.accent,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 17,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            SizedBox(height: 20),
            _signInBtn(
              accent: widget.accent,
              isLoading: _isLoading,
              label: 'Sign In as Student',
              onTap: _isLoading ? null : _login,
            ),
            SizedBox(height: 24),
            _divider('New student?'),
            SizedBox(height: 14),
            _bottomCard(
              accent: widget.accent,
              icon: Icons.add_business_rounded,
              title: 'Create or Join Organization',
              subtitle: 'Set up your school on SchoolSync',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LandingPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
