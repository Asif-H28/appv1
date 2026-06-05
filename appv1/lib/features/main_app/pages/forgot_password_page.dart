import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

enum ForgotStep { email, otp, newPassword }

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const String _baseUrl = '${ApiConstants.baseUrl}';

  ForgotStep _step = ForgotStep.email;
  bool _isLoading = false;

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String _resetToken = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[600] : Colors.teal[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 1. Request OTP
  Future<void> _requestOTP() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack('Please enter your email', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('\n[OTP FLOW] 1. Request OTP');
    debugPrint('Payload: {"email": "$email"}');
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/auth/forgot-password'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({'email': email}),
      );

      debugPrint('[OTP FLOW] Response Status: ${res.statusCode}');
      debugPrint('[OTP FLOW] Response Body: ${res.body}');

      if (!mounted) return;
      if (res.statusCode == 200) {
        _showSnack('OTP sent to your email');
        setState(() => _step = ForgotStep.otp);
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['message'] ?? 'Failed to send OTP', isError: true);
      }
    } catch (e) {
      debugPrint('[OTP FLOW] Error: $e');
      _showSnack('Network error', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Verify OTP
  Future<void> _verifyOTP() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      _showSnack('Please enter the OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('\n[OTP FLOW] 2. Verify OTP');
    debugPrint('Payload: {"email": "$email", "otp": "$otp"}');
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/auth/verify-otp'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      debugPrint('[OTP FLOW] Response Status: ${res.statusCode}');
      debugPrint('[OTP FLOW] Response Body: ${res.body}');

      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        _resetToken = body['resetToken'] ?? '';
        if (_resetToken.isNotEmpty) {
          _showSnack('OTP Verified');
          setState(() => _step = ForgotStep.newPassword);
        } else {
          _showSnack('Error: No reset token received', isError: true);
        }
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['message'] ?? 'Invalid OTP', isError: true);
      }
    } catch (e) {
      debugPrint('[OTP FLOW] Error: $e');
      _showSnack('Network error', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Reset Password
  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    final newPassword = _passCtrl.text.trim();
    if (newPassword.length < 6) {
      _showSnack('Password must be at least 6 characters', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('\n[OTP FLOW] 3. Reset Password');
    debugPrint(
      'Payload: {"email": "$email", "resetToken": "$_resetToken", "newPassword": "***"}',
    );
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/auth/reset-password'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'email': email,
          'resetToken': _resetToken,
          'newPassword': newPassword,
        }),
      );

      debugPrint('[OTP FLOW] Response Status: ${res.statusCode}');
      debugPrint('[OTP FLOW] Response Body: ${res.body}');

      if (!mounted) return;
      if (res.statusCode == 200) {
        _showSnack('Password reset successfully!');
        Navigator.pop(context); // Go back to login
      } else {
        final body = jsonDecode(res.body);
        _showSnack(
          body['message'] ?? 'Failed to reset password',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('[OTP FLOW] Error: $e');
      _showSnack('Network error', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI Components ─────────────────────────────────────

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.5),
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: Colors.teal, size: 16),
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
        borderSide: const BorderSide(color: Colors.teal, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    );
  }

  Widget _buildButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.teal.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildStepEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your Registered email address and we will send you an OTP to reset your password.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDeco('Email Address', Icons.email_outlined),
        ),
        const SizedBox(height: 24),
        _buildButton('Send OTP', _requestOTP),
      ],
    );
  }

  Widget _buildStepOTP() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter OTP',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the 4-digit OTP sent to ${_emailCtrl.text}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '0000',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 20,
              letterSpacing: 8,
            ),
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
              borderSide: const BorderSide(color: Colors.teal, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        _buildButton('Verify OTP', _verifyOTP),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() => _step = ForgotStep.email);
              _otpCtrl.clear();
            },
            child: const Text(
              'Change Email',
              style: TextStyle(
                color: Colors.teal,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepNewPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Create a new password for your account.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          decoration: _inputDeco('New Password', Icons.lock_outline),
        ),
        const SizedBox(height: 24),
        _buildButton('Reset Password', _resetPassword),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset,
                  size: 36,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 32),
              if (_step == ForgotStep.email) _buildStepEmail(),
              if (_step == ForgotStep.otp) _buildStepOTP(),
              if (_step == ForgotStep.newPassword) _buildStepNewPassword(),
            ],
          ),
        ),
      ),
    );
  }
}
