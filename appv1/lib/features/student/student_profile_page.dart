import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../main_app/pages/login_page.dart';
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

  // â”€â”€ Fetch profile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/student/profile/$studentId',
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
      final orgId = student['orgId']?.toString() ?? '';
      final classId = student['classId']?.toString() ?? '';

      if (orgId.isNotEmpty) {
        try {
          final clsRes = await http.get(
            Uri.parse(
              '${ApiConstants.apiBaseUrl}/student/orgs/$orgId/classes',
            ),
            headers: {'Content-Type': 'application/json'},
          );
          if (clsRes.statusCode == 200) {
            final clsBody = jsonDecode(clsRes.body);
            student['orgName'] = clsBody['orgName']?.toString() ?? '';
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

  // â”€â”€ Save profile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          '${ApiConstants.apiBaseUrl}/student/profile/$studentId',
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

  // â”€â”€ Logout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // â”€â”€ Logout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => StudentLogoutModal(),
    );
    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('studentId') ?? '';

    // âœ… Step 1 â€” Clear FCM token on backend BEFORE clearing local session
    if (studentId.isNotEmpty) {
      try {
        await http.post(
          Uri.parse(
            '${ApiConstants.apiBaseUrl}/notification/fcm/student/clear',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'studentId': studentId}),
        );
        debugPrint('[FCM] Token cleared on logout');
      } catch (e) {
        debugPrint('[FCM] Token clear failed: $e');
        // âœ… Don't block logout even if this fails
      }
    }

    // âœ… Step 2 â€” Clear local session
    await prefs.clear();
    if (!mounted) return;

    // âœ… Step 3 â€” Navigate to login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

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
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _isLoading
          ? _buildLoader()
          : _error.isNotEmpty
          ? _buildError()
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      color: _accent,
      onRefresh: _fetchProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // âœ… Avatar card â€” replaces old duplicate header
            _buildAvatarCard(),
            // âœ… Action buttons row
            _buildActionRow(),
            const SizedBox(height: 8),
            // âœ… Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
              child: _isEditing
                  ? StudentProfileEditCard(
                      nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl,
                      addressCtrl: _addressCtrl,
                      selectedGender: _selectedGender,
                      isSaving: _isSaving,
                      onGenderChange: (g) =>
                          setState(() => _selectedGender = g),
                      onSave: _saveProfile,
                    )
                  : StudentProfileInfoCard(
                      student: _student,
                      showPersonal: true,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Avatar card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildAvatarCard() {
    final name = _student['name']?.toString() ?? '';
    final email = _student['email']?.toString() ?? '';
    final orgName = _student['orgName']?.toString() ?? '';
    final className = _student['className']?.toString() ?? '';
    final joinStatus = _student['joinStatus']?.toString() ?? '';
    final isVerified = joinStatus == 'approved';

    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        children: [
          // Avatar circle
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(isVerified ? 1.0 : 0.4),
                    width: isVerified ? 2.5 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isVerified
                          ? Icons.verified_rounded
                          : joinStatus == 'pending'
                          ? Icons.hourglass_top_rounded
                          : Icons.help_outline_rounded,
                      size: 14,
                      color: isVerified
                          ? Colors.blue[600]
                          : joinStatus == 'pending'
                          ? Colors.orange[400]
                          : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name + verified
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 11,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),

          // Email
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 11,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              if (orgName.isNotEmpty) _pill(Icons.domain_rounded, orgName),
              if (className.isNotEmpty) _pill(Icons.class_rounded, className),
              if (!isVerified && joinStatus.isNotEmpty) _statusPill(joinStatus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _statusPill(String joinStatus) {
    Color color;
    IconData icon;
    String label;
    switch (joinStatus) {
      case 'pending':
        color = Colors.orange[300]!;
        icon = Icons.hourglass_top_rounded;
        label = 'Pending';
        break;
      case 'rejected':
        color = Colors.red[300]!;
        icon = Icons.cancel_rounded;
        label = 'Rejected';
        break;
      default:
        color = Colors.grey[300]!;
        icon = Icons.help_outline_rounded;
        label = 'Not Applied';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Edit / Logout action row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          // Edit / Cancel button
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isEditing) _fillControllers();
                setState(() => _isEditing = !_isEditing);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _isEditing
                      ? Colors.grey.shade100
                      : Colors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: _isEditing
                        ? Colors.grey.shade300
                        : Colors.teal.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                      size: 15,
                      color: _isEditing ? Colors.grey[600] : Colors.teal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isEditing ? 'Cancel Edit' : 'Edit Profile',
                      style: TextStyle(
                        color: _isEditing ? Colors.grey[600] : Colors.teal,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Logout button
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 15, color: Colors.red[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ States â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildLoader() => const Center(
    child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 14),
          Text(
            _error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
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

