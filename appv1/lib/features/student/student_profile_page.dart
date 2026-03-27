import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../main_app/pages/login_page.dart';
import 'student_profile_header.dart';
import 'student_profile_info_card.dart';
import 'student_profile_edit_card.dart';
import 'student_logout_modal.dart';

const Color _accent = Colors.teal;

class StudentProfilePage extends StatefulWidget {
  @override
  _StudentProfilePageState createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';
  bool _isEditing = false;

  Map<String, dynamic> _student = {};

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Fetch profile + org + class names ─────────────────

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('studentId') ?? '';

    if (studentId.isEmpty) {
      setState(() {
        _error = 'Student ID not found. Please login again.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Step 1: student profile
      final res = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/student/profile/$studentId',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;

      if (res.statusCode != 200) {
        setState(() {
          _error = 'Failed to load profile.';
          _isLoading = false;
        });
        return;
      }

      final body = jsonDecode(res.body);
      final student = Map<String, dynamic>.from(body['student'] ?? {});

      // Step 2: fetch org + class names via orgs/:orgId/classes
      final orgId = student['orgId']?.toString() ?? '';
      final classId = student['classId']?.toString() ?? '';

      if (orgId.isNotEmpty) {
        try {
          final clsRes = await http.get(
            Uri.parse(
              'https://appv1backend.onrender.com/api/student/orgs/$orgId/classes',
            ),
            headers: {'Content-Type': 'application/json'},
          );
          if (clsRes.statusCode == 200) {
            final clsBody = jsonDecode(clsRes.body);

            // org name comes from this response
            student['orgName'] = clsBody['orgName']?.toString() ?? '';

            // find matching class name
            if (classId.isNotEmpty) {
              final classes = (clsBody['classes'] as List<dynamic>?) ?? [];
              for (final c in classes) {
                final cls = c as Map<String, dynamic>;
                if (cls['classId']?.toString() == classId) {
                  student['className'] = cls['className']?.toString() ?? '';
                  break;
                }
              }
            }
          }
        } catch (_) {}
      }

      // Step 3: persist to prefs
      for (final e in student.entries) {
        if (e.value != null) prefs.setString(e.key, e.value.toString());
      }

      setState(() {
        _student = student;
        _isLoading = false;
      });
      _fillControllers();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No internet connection.';
        _isLoading = false;
      });
    }
  }

  void _fillControllers() {
    _nameCtrl.text = _student['name'] ?? '';
    _phoneCtrl.text = _student['phone'] ?? '';
    _addressCtrl.text = _student['address'] ?? '';
    const genders = ['Male', 'Female', 'Other'];
    final g = _student['gender']?.toString() ?? '';
    _selectedGender = genders.contains(g) ? g : null;
  }

  // ── Save profile ──────────────────────────────────────

  Future<void> _saveProfile() async {
    final studentId = _student['studentId']?.toString() ?? '';
    if (studentId.isEmpty) return;

    setState(() => _isSaving = true);

    final body = <String, dynamic>{};
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    if (name.isNotEmpty) body['name'] = name;
    if (phone.isNotEmpty) body['phone'] = phone;
    if (address.isNotEmpty) body['address'] = address;
    if (_selectedGender != null) body['gender'] = _selectedGender;

    try {
      final res = await http.put(
        Uri.parse(
          'https://appv1backend.onrender.com/api/student/profile/$studentId',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final updated = json['student'] as Map<String, dynamic>? ?? {};

        final prefs = await SharedPreferences.getInstance();
        for (final e in updated.entries) {
          if (e.value != null) prefs.setString(e.key, e.value.toString());
        }

        setState(() {
          _student = {..._student, ...updated};
          _isEditing = false;
          _isSaving = false;
        });
        _fillControllers();
        _showSnack('Profile updated successfully', isError: false);
      } else {
        setState(() => _isSaving = false);
        _showSnack('Failed to update profile', isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('No internet connection', isError: true);
    }
  }

  // ── Logout ────────────────────────────────────────────

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => StudentLogoutModal(),
    );
    if (confirmed != true) return;

    // Clear all stored session data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    // Navigate to LoginPage and remove entire back stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }
  // ── Snackbar ──────────────────────────────────────────

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        margin: EdgeInsets.all(14),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────

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
            StudentProfileHeader(
              student: _student,
              isEditing: _isEditing,
              isLoading: _isLoading,
              hasError: _error.isNotEmpty,
              onEditToggle: () {
                if (_isEditing) _fillControllers();
                setState(() => _isEditing = !_isEditing);
              },
              onLogout: _logout,
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoader()
                  : _error.isNotEmpty
                  ? _buildError()
                  : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────

  Widget _buildBody() {
    return RefreshIndicator(
      color: _accent,
      onRefresh: _fetchProfile,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(14, 4, 14, 40),
        child: _isEditing
            ? StudentProfileEditCard(
                nameCtrl: _nameCtrl,
                phoneCtrl: _phoneCtrl,
                addressCtrl: _addressCtrl,
                selectedGender: _selectedGender,
                isSaving: _isSaving,
                onGenderChange: (g) => setState(() => _selectedGender = g),
                onSave: _saveProfile,
              )
            : StudentProfileInfoCard(student: _student, showPersonal: true),
      ),
    );
  }

  // ── States ────────────────────────────────────────────

  Widget _buildLoader() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
        SizedBox(height: 14),
        Text(
          'Loading profile...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red[400],
              size: 30,
            ),
          ),
          SizedBox(height: 14),
          Text(
            _error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchProfile,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
