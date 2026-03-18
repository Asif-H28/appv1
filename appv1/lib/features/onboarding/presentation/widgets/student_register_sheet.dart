import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../main_app/pages/login_page.dart';

class StudentRegisterSheet extends StatefulWidget {
  final String orgName;
  final String orgId;

  const StudentRegisterSheet({required this.orgName, required this.orgId});

  @override
  _StudentRegisterSheetState createState() => _StudentRegisterSheetState();
}

class _StudentRegisterSheetState extends State<StudentRegisterSheet> {
  static const Color _accent = Colors.orange;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // ── Step 1: Register student ──
      final registerResponse = await http.post(
        Uri.parse('https://appv1backend.onrender.com/api/student/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      debugPrint('STUDENT REGISTER STATUS: ${registerResponse.statusCode}');
      debugPrint('STUDENT REGISTER BODY: ${registerResponse.body}');

      if (!mounted) return;

      Map<String, dynamic> registerBody = {};
      try {
        registerBody =
            jsonDecode(registerResponse.body) as Map<String, dynamic>;
      } catch (_) {
        setState(() => _isLoading = false);
        _showError('Unexpected server response.');
        return;
      }

      if (registerResponse.statusCode != 200 &&
          registerResponse.statusCode != 201) {
        setState(() => _isLoading = false);
        _showError(
          registerBody['message']?.toString() ??
              'Registration failed. Please try again.',
        );
        return;
      }

      // ── Extract studentId ──
      final studentData =
          registerBody['student'] as Map<String, dynamic>? ??
          registerBody['data'] as Map<String, dynamic>? ??
          registerBody;
      final studentId = studentData['studentId']?.toString() ?? '';

      debugPrint('Extracted studentId: $studentId');

      // ── Step 2: Send join request ──
      if (studentId.isNotEmpty && widget.orgId.isNotEmpty) {
        try {
          final joinResponse = await http.post(
            Uri.parse(
              'https://appv1backend.onrender.com/api/student/join-request',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'studentId': studentId, 'orgId': widget.orgId}),
          );
          debugPrint('JOIN STATUS: ${joinResponse.statusCode}');
          debugPrint('JOIN BODY: ${joinResponse.body}');
        } catch (e) {
          debugPrint('Join request error (non-fatal): $e');
          // Non-fatal — student can join a class later from dashboard
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // ── Save basic info to prefs ──
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('studentId', studentId);
      await prefs.setString(
        'studentName',
        studentData['name']?.toString() ?? _nameController.text.trim(),
      );
      await prefs.setString(
        'studentEmail',
        studentData['email']?.toString() ?? _emailController.text.trim(),
      );
      await prefs.setString('userRole', 'student');

      if (!mounted) return;
      Navigator.pop(context); // close sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ Account created! Sign in as Student.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('STUDENT REGISTER ERROR: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Something went wrong. Please try again.',
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text(msg)),
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accent, _accent.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_rounded,
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
                          'Student Registration',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Joining ${widget.orgName}',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // ── Org chip ──
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.domain_rounded, color: _accent, size: 13),
                    SizedBox(width: 6),
                    Text(
                      'Org ID: ${widget.orgId}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // ── Full Name ──
              _sheetLabel('Full Name'),
              SizedBox(height: 8),
              _sheetInputBox(
                child: TextFormField(
                  controller: _nameController,
                  cursorColor: _accent,
                  style: TextStyle(fontSize: 15),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Name is required';
                    if (v.trim().length < 2) return 'Enter a valid name';
                    return null;
                  },
                  decoration: _sheetDeco(
                    hint: 'e.g. Arjun Sharma',
                    icon: Icons.person_outline_rounded,
                    accent: _accent,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // ── Email ──
              _sheetLabel('Email Address'),
              SizedBox(height: 8),
              _sheetInputBox(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: _accent,
                  style: TextStyle(fontSize: 15),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  decoration: _sheetDeco(
                    hint: 'student@email.com',
                    icon: Icons.email_outlined,
                    accent: _accent,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // ── Phone ──
              _sheetLabel('Phone Number'),
              SizedBox(height: 8),
              _sheetInputBox(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  cursorColor: _accent,
                  style: TextStyle(fontSize: 15),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Phone is required';
                    if (v.length < 10) return 'Enter a valid phone number';
                    return null;
                  },
                  decoration: _sheetDeco(
                    hint: '9876543210',
                    icon: Icons.phone_outlined,
                    accent: _accent,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // ── Password ──
              _sheetLabel('Create Password'),
              SizedBox(height: 8),
              _sheetInputBox(
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  cursorColor: _accent,
                  style: TextStyle(fontSize: 15),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  decoration:
                      _sheetDeco(
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        accent: _accent,
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
              SizedBox(height: 28),

              // ── Register Button ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                    child: _isLoading
                        ? Row(
                            key: ValueKey('loading'),
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                'Creating Account...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: ValueKey('idle'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Create Student Account',
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

              // ── Note ──
              Center(
                child: Text(
                  'After registering, sign in and join a class\nfrom your student dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 13.5,
    ),
  );

  Widget _sheetInputBox({required Widget child}) => Container(
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

  InputDecoration _sheetDeco({
    required String hint,
    required IconData icon,
    required Color accent,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: AppColors.textSecondary.withOpacity(0.5),
      fontSize: 14,
    ),
    prefixIcon: Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Icon(icon, color: accent, size: 20),
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
      borderSide: BorderSide(color: accent.withOpacity(0.4), width: 1.5),
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
