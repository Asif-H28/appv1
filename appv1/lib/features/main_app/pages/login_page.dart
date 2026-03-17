import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../onboarding/presentation/pages/landing_page.dart';
import '../../teacher/presentation/pages/teacher_main_screen.dart';
import '../../teacher/presentation/pages/teacher_pending_screen.dart';
import '../main_app_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _tabAccent =>
      [AppColors.primary, Colors.teal, Colors.orange][_selectedTab];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Stack(
          children: [
            // ── Decorative background blobs ──
            Positioned(
              top: -60,
              right: -60,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 400),
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _tabAccent.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              top: 200,
              left: -30,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 400),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _tabAccent.withOpacity(0.07),
                ),
              ),
            ),

            Column(
              children: [
                // ─── Gradient Header ───
                AnimatedContainer(
                  duration: Duration(milliseconds: 350),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_tabAccent, _tabAccent.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Logo row ──
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.sync_alt,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SchoolSync',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'School Management Platform',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 22),

                          Text(
                            'Welcome back 👋',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sign in to continue to your organization',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13.5,
                            ),
                          ),
                          SizedBox(height: 24),

                          // ─── Tab Bar ───
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: _tabAccent,
                              unselectedLabelColor: Colors.white.withOpacity(
                                0.85,
                              ),
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              unselectedLabelStyle: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              padding: EdgeInsets.all(4),
                              dividerColor: Colors.transparent,
                              tabs: [
                                _buildTab(
                                  Icons.admin_panel_settings_outlined,
                                  'Admin',
                                  0,
                                ),
                                _buildTab(Icons.school_outlined, 'Teacher', 1),
                                _buildTab(Icons.person_outline, 'Student', 2),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── White Body ───
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _AdminLoginTab(accentColor: AppColors.primary),
                        _TeacherLoginTab(accentColor: Colors.teal),
                        _TeacherLoginTab(accentColor: Colors.teal),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, int index) {
    final isSelected = _selectedTab == index;
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  ADMIN LOGIN TAB
// ─────────────────────────────────────────
class _AdminLoginTab extends StatefulWidget {
  final Color accentColor;
  const _AdminLoginTab({required this.accentColor});

  @override
  __AdminLoginTabState createState() => __AdminLoginTabState();
}

class __AdminLoginTabState extends State<_AdminLoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://appv1backend.onrender.com/api/org/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminEmail': _emailController.text.trim(),
          'adminPassword': _passwordController.text,
        }),
      );

      if (!mounted) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userRole', 'admin');
        await prefs.setString('userEmail', _emailController.text.trim());
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Welcome back, Admin!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainAppScreen(initialTab: 0)),
        );
      } else {
        setState(() => _isLoading = false);
        _showError(
          body['message']?.toString() ??
              'Login failed. Please check your credentials.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Something went wrong. Please try again.',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card with role icon ──
            // Container(
            //   padding: EdgeInsets.all(18),
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [
            //         widget.accentColor.withOpacity(0.08),
            //         widget.accentColor.withOpacity(0.03),
            //       ],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //     borderRadius: BorderRadius.circular(20),
            //     border: Border.all(color: widget.accentColor.withOpacity(0.15)),
            //   ),
            //   child: Row(
            //     children: [
            //       Container(
            //         width: 52,
            //         height: 52,
            //         decoration: BoxDecoration(
            //           gradient: LinearGradient(
            //             colors: [
            //               widget.accentColor,
            //               widget.accentColor.withOpacity(0.7),
            //             ],
            //             begin: Alignment.topLeft,
            //             end: Alignment.bottomRight,
            //           ),
            //           borderRadius: BorderRadius.circular(16),
            //           boxShadow: [
            //             BoxShadow(
            //               color: widget.accentColor.withOpacity(0.35),
            //               blurRadius: 10,
            //               offset: Offset(0, 4),
            //             ),
            //           ],
            //         ),
            //         child: Icon(
            //           Icons.admin_panel_settings,
            //           color: Colors.white,
            //           size: 26,
            //         ),
            //       ),
            //       SizedBox(width: 14),
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               'Admin Sign In',
            //               style: TextStyle(
            //                 fontSize: 17,
            //                 fontWeight: FontWeight.bold,
            //                 color: AppColors.textPrimary,
            //               ),
            //             ),
            //             SizedBox(height: 2),
            //             Text(
            //               'Access your organization dashboard',
            //               style: TextStyle(
            //                 color: AppColors.textSecondary,
            //                 fontSize: 12,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //       Container(
            //         padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            //         decoration: BoxDecoration(
            //           color: widget.accentColor.withOpacity(0.1),
            //           borderRadius: BorderRadius.circular(20),
            //         ),
            //         child: Text(
            //           'Admin',
            //           style: TextStyle(
            //             color: widget.accentColor,
            //             fontSize: 11,
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // SizedBox(height: 28),

            // ── Email ──
            _inputLabel('Email Address'),
            SizedBox(height: 8),
            _inputContainer(
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                cursorColor: widget.accentColor,
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
                decoration: _inputDeco(
                  hint: 'admin@organization.com',
                  icon: Icons.email_outlined,
                ),
              ),
            ),
            SizedBox(height: 16),

            // ── Password ──
            _inputLabel('Password'),
            SizedBox(height: 8),
            _inputContainer(
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                cursorColor: widget.accentColor,
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
                decoration:
                    _inputDeco(
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
              ),
            ),

            // ── Forgot password ──
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                ),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6),

            // ── Sign In Button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAdminLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: widget.accentColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  child: _isLoading
                      ? Row(
                          key: ValueKey('loading'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Signing in...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: ValueKey('idle'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
            ),

            SizedBox(height: 32),

            // ── Divider ──
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'New to SchoolSync?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
              ],
            ),
            SizedBox(height: 20),

            // ── Create / Join Org Card ──
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LandingPage()),
              ),
              child: Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.accentColor.withOpacity(0.07),
                      widget.accentColor.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: widget.accentColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_business_rounded,
                        color: widget.accentColor,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create or Join Organization',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Set up your school on SchoolSync',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: widget.accentColor,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _inputLabel(String label) => Text(
    label,
    style: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 13.5,
    ),
  );

  Widget _inputContainer({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
      border: Border.all(color: Colors.grey.withOpacity(0.12)),
    ),
    child: child,
  );

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.5),
        fontSize: 14,
      ),
      prefixIcon: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: Icon(icon, color: widget.accentColor, size: 20),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: widget.accentColor.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorStyle: TextStyle(color: Colors.red[400], fontSize: 12),
    );
  }
}

// ─────────────────────────────────────────
//  COMING SOON TAB
// ─────────────────────────────────────────
// ─────────────────────────────────────────
//  TEACHER LOGIN TAB  (add to login_page.dart)
// ─────────────────────────────────────────
class _TeacherLoginTab extends StatefulWidget {
  final Color accentColor;
  const _TeacherLoginTab({required this.accentColor});

  @override
  __TeacherLoginTabState createState() => __TeacherLoginTabState();
}

class __TeacherLoginTabState extends State<_TeacherLoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleTeacherLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // ── Step 1: Login ──
      final response = await http.post(
        Uri.parse('https://appv1backend.onrender.com/api/teacher/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 || body['success'] != true) {
        setState(() => _isLoading = false);
        _showError(
          body['message']?.toString() ??
              'Login failed. Please check your credentials.',
        );
        return;
      }

      final teacher = body['teacher'] as Map<String, dynamic>? ?? {};
      final teacherId = teacher['teacherId']?.toString() ?? '';
      final token = body['token']?.toString() ?? '';

      // ── Step 2: Fetch teacher profile to check verified status ──
      final profileResponse = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/teacher/$teacherId/profile',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;
      final profileBody =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;

      final profileData =
          profileBody['teacher'] as Map<String, dynamic>? ?? teacher;
      final isVerified = profileData['verified'] == true;

      // ── Persist auth data ──
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRole', 'teacher');
      await prefs.setString('userEmail', _emailController.text.trim());
      await prefs.setString('authToken', token);
      await prefs.setString('teacherId', teacherId);
      await prefs.setString(
        'teacherName',
        profileData['name']?.toString() ?? '',
      );
      await prefs.setString('orgId', profileData['orgId']?.toString() ?? '');
      await prefs.setBool('teacherVerified', isVerified);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (isVerified) {
        // ── Verified → go to Teacher Portal ──
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Welcome, ${profileData['name'] ?? 'Teacher'}! 👋',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.teal[600],
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
        // ── Not verified → go to pending screen ──
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherPendingScreen(
              teacherName: profileData['name']?.toString() ?? 'Teacher',
              orgId: profileData['orgId']?.toString() ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Something went wrong. Please try again.',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ──
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.accentColor.withOpacity(0.08),
                    widget.accentColor.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: widget.accentColor.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.accentColor,
                          widget.accentColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Access your classroom dashboard',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Teacher',
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28),

            // ── Email ──
            _inputLabel('Email Address'),
            SizedBox(height: 8),
            _inputContainer(
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                cursorColor: widget.accentColor,
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
                decoration: _inputDeco(
                  hint: 'teacher@school.com',
                  icon: Icons.email_outlined,
                ),
              ),
            ),
            SizedBox(height: 16),

            // ── Password ──
            _inputLabel('Password'),
            SizedBox(height: 8),
            _inputContainer(
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                cursorColor: widget.accentColor,
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
                decoration:
                    _inputDeco(
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                ),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6),

            // ── Sign In Button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleTeacherLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: widget.accentColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  child: _isLoading
                      ? Row(
                          key: ValueKey('loading'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Signing in...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: ValueKey('idle'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign In as Teacher',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
            ),
            SizedBox(height: 32),

            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'New to SchoolSync?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
              ],
            ),
            SizedBox(height: 20),

            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LandingPage()),
              ),
              child: Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.accentColor.withOpacity(0.07),
                      widget.accentColor.withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: widget.accentColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_business_rounded,
                        color: widget.accentColor,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create or Join Organization',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Set up your school on SchoolSync',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: widget.accentColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputLabel(String label) => Text(
    label,
    style: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 13.5,
    ),
  );

  Widget _inputContainer({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
      border: Border.all(color: Colors.grey.withOpacity(0.12)),
    ),
    child: child,
  );

  InputDecoration _inputDeco({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.5),
          fontSize: 14,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: widget.accentColor, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: widget.accentColor.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: TextStyle(color: Colors.red[400], fontSize: 12),
      );
}
