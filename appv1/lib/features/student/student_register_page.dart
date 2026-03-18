import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_join_org_page.dart';

class StudentRegisterPage extends StatefulWidget {
  @override
  _StudentRegisterPageState createState() => _StudentRegisterPageState();
}

class _StudentRegisterPageState extends State<StudentRegisterPage> {
  static const Color _accent = Colors.orange;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://appv1backend.onrender.com/api/student/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'password': _passCtrl.text.trim(),
        }),
      );

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      // ── Guard: widget may have been disposed during await ──
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> body = {};
        try {
          body = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          _snack('Could not parse server response.', Colors.red[600]!);
          return;
        }

        // ── Extract student data ──
        final student =
            (body['student'] as Map<String, dynamic>?) ??
            (body['data'] as Map<String, dynamic>?) ??
            {};

        // ── Save to SharedPreferences ──
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'studentId',
          student['studentId']?.toString() ?? '',
        );
        await prefs.setString(
          'studentName',
          student['name']?.toString() ?? _nameCtrl.text.trim(),
        );
        await prefs.setString(
          'studentEmail',
          student['email']?.toString() ?? _emailCtrl.text.trim(),
        );
        await prefs.setString('userRole', 'student');
        await prefs.setBool('isLoggedIn', true);

        // ── Final mounted check before navigation ──
        if (!mounted) return;

        // ── Navigate using context directly, no rootNavigator, no delay ──
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentJoinOrgPage()),
        );
      } else {
        Map<String, dynamic> errorBody = {};
        try {
          errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        _snack(
          errorBody['message']?.toString() ??
              'Registration failed. (${response.statusCode})',
          Colors.red[600]!,
        );
      }
    } catch (e, stack) {
      debugPrint('REGISTER ERROR: $e');
      debugPrint('STACK: $stack');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack(
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Something went wrong.',
        Colors.red[600]!,
      );
    }
  }

  Map<String, dynamic> _extractStudent(Map<String, dynamic> body) {
    if (body['student'] is Map) return body['student'] as Map<String, dynamic>;
    if (body['data'] is Map) return body['data'] as Map<String, dynamic>;
    return body;
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Register and join your classroom',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),

                    SizedBox(height: 14),
                    // ── Flow steps banner ──
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _flowStep(Icons.person_add_rounded, 'Register'),
                          _flowArrow(),
                          _flowStep(Icons.business_rounded, 'Pick Org'),
                          _flowArrow(),
                          _flowStep(Icons.class_rounded, 'Join Class'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form ──
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Full Name'),
                    SizedBox(height: 6),
                    _field(
                      _nameCtrl,
                      'e.g. Arjun Sharma',
                      Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'Name is required' : null,
                    ),
                    SizedBox(height: 12),

                    _label('Email Address'),
                    SizedBox(height: 6),
                    _field(
                      _emailCtrl,
                      'student@email.com',
                      Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    SizedBox(height: 12),

                    _label('Phone Number'),
                    SizedBox(height: 6),
                    _field(
                      _phoneCtrl,
                      '9876543210',
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v!.isEmpty) return 'Phone is required';
                        if (v.length < 10) return 'Enter a valid phone number';
                        return null;
                      },
                    ),
                    SizedBox(height: 12),

                    _label('Password'),
                    SizedBox(height: 6),
                    _passwordField(),
                    SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _accent.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, size: 15),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
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

  Widget _flowStep(IconData icon, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white, size: 14),
      SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white, fontSize: 9)),
    ],
  );

  Widget _flowArrow() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Icon(
      Icons.arrow_forward_rounded,
      color: Colors.white.withOpacity(0.6),
      size: 13,
    ),
  );

  Widget _passwordField() => Container(
    decoration: _boxDeco(),
    child: TextFormField(
      controller: _passCtrl,
      obscureText: _obscure,
      cursorColor: _accent,
      style: TextStyle(fontSize: 13),
      validator: (v) {
        if (v!.isEmpty) return 'Password is required';
        if (v.length < 6) return 'Minimum 6 characters';
        return null;
      },
      decoration: _deco('Enter password', Icons.lock_outline_rounded).copyWith(
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey[400],
            size: 18,
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) => Container(
    decoration: _boxDeco(),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      cursorColor: _accent,
      style: TextStyle(fontSize: 13),
      validator: validator,
      decoration: _deco(hint, icon),
    ),
  );

  BoxDecoration _boxDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 5,
        offset: Offset(0, 2),
      ),
    ],
  );

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: AppColors.textSecondary.withOpacity(0.5),
      fontSize: 13,
    ),
    prefixIcon: Icon(icon, color: _accent, size: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _accent.withOpacity(0.4), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    errorStyle: TextStyle(color: Colors.red[400], fontSize: 11),
  );

  Widget _label(String t) => Text(
    t,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.3,
    ),
  );
}
