import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
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
  static const Color _accent = Colors.teal;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.5,
    ),
  );

  InputDecoration _deco({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: AppColors.textSecondary.withOpacity(0.5),
      fontSize: 13,
    ),
    prefixIcon: Icon(icon, color: _accent, size: 16),
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
      borderSide: BorderSide(color: _accent.withOpacity(0.5), width: 1.5),
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

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
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

  // ─── Register logic ────────────────────────────────────

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final regRes = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/student/register'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'password': _passCtrl.text,
          'orgId': widget.orgId, // ✅ now included in register body
        }),
      );
      if (!mounted) return;

      Map<String, dynamic> regBody = {};
      try {
        regBody = jsonDecode(regRes.body) as Map<String, dynamic>;
      } catch (_) {
        setState(() => _isLoading = false);
        _showSnack('Unexpected server response.', Colors.red[600]!);
        return;
      }

      if (regRes.statusCode != 200 && regRes.statusCode != 201) {
        setState(() => _isLoading = false);
        _showSnack(
          regBody['message']?.toString() ??
              'Registration failed. Please try again.',
          Colors.red[600]!,
        );
        return;
      }

      // Extract student data
      final studentData =
          regBody['student'] as Map<String, dynamic>? ??
          regBody['data'] as Map<String, dynamic>? ??
          regBody;
      final studentId = studentData['studentId']?.toString() ?? '';

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Save to prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('studentId', studentId);
      await prefs.setString(
        'studentName',
        studentData['name']?.toString() ?? _nameCtrl.text.trim(),
      );
      await prefs.setString(
        'studentEmail',
        studentData['email']?.toString() ?? _emailCtrl.text.trim(),
      );
      await prefs.setString('userRole', 'student');

      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Account created! Sign in as Student.', Colors.teal[600]!);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Something went wrong. Please try again.',
        Colors.red[600]!,
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 20 + bottomInset),
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
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // ── Sheet header ──
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Icon(Icons.person_rounded, color: _accent, size: 20),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Registration',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Joining ${widget.orgName}',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 11.5,
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
                      padding: EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // ── Org ID chip ──
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.domain_rounded, color: _accent, size: 12),
                    SizedBox(width: 5),
                    Text(
                      'Org ID: ${widget.orgId}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // ── Full Name ──
              _label('FULL NAME'),
              SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                cursorColor: _accent,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2) return 'Enter a valid name';
                  return null;
                },
                decoration: _deco(
                  hint: 'e.g. Arjun Sharma',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              SizedBox(height: 12),

              // ── Email ──
              _label('EMAIL ADDRESS'),
              SizedBox(height: 6),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                cursorColor: _accent,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
                decoration: _deco(
                  hint: 'student@email.com',
                  icon: Icons.email_outlined,
                ),
              ),
              SizedBox(height: 12),

              // ── Phone ──
              _label('PHONE NUMBER'),
              SizedBox(height: 6),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                cursorColor: _accent,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Phone is required';
                  if (v.length < 10) return 'Enter a valid phone number';
                  return null;
                },
                decoration: _deco(
                  hint: '9876543210',
                  icon: Icons.phone_outlined,
                ),
              ),
              SizedBox(height: 12),

              // ── Password ──
              _label('CREATE PASSWORD'),
              SizedBox(height: 6),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                cursorColor: _accent,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
                decoration: _deco(
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
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

              // ── Submit button ──
              Theme(
                data: ThemeData(
                  colorScheme: ColorScheme.light(
                    primary: _accent,
                    onPrimary: Colors.white,
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _accent.withOpacity(0.45),
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: _isLoading
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
                                'Creating Account...',
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
                              Icon(
                                Icons.person_add_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Create Student Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // ── Note ──
              Center(
                child: Text(
                  'After registering, sign in and join a class\nfrom your student dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
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
}

