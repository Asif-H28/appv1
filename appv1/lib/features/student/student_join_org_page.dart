import 'package:appv1/features/student/student_main_screen.dart';
import 'package:appv1/features/student/student_rejected_screen.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../main_app/pages/login_page.dart';

const Color _accent = Colors.teal;

class StudentJoinOrgPage extends StatefulWidget {
  @override
  _StudentJoinOrgPageState createState() => _StudentJoinOrgPageState();
}

class _StudentJoinOrgPageState extends State<StudentJoinOrgPage> {
  int _step = 1;

  List<Map<String, dynamic>> _classes = [];
  Map<String, dynamic>? _selectedClass;

  bool _isLoading = false;
  bool _isSubmitting = false;

  String _studentId = '';
  String _orgId = '';
  String _orgName = '';

  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _checkStatus() async {
    if (_isCheckingStatus) return;
    setState(() => _isCheckingStatus = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('studentId') ?? '';

      if (studentId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please sign out and login again.')),
          );
        }
        setState(() => _isCheckingStatus = false);
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/student/profile/$studentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final student = body['student'] as Map<String, dynamic>? ?? {};
        final status = student['joinStatus']?.toString() ?? 'pending';

        // Update local prefs
        await prefs.setString('joinStatus', status);
        if (student['classId'] != null) {
          await prefs.setString('classId', student['classId'].toString());
        }

        if (status == 'approved') {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const StudentMainScreen()),
            (route) => false,
          );
        } else if (status == 'rejected') {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => StudentRejectedScreen(studentName: student['name'] ?? 'Student')),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your request is still under review. Please wait.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to check status. Try again later.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error. Please check your internet.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    _studentId = prefs.getString('studentId') ?? '';

    // ── Read orgId from tempOrg JSON or flat key ──
    final tempOrgRaw = prefs.getString('tempOrg');
    if (tempOrgRaw != null && tempOrgRaw.isNotEmpty) {
      try {
        final tempOrg = jsonDecode(tempOrgRaw) as Map<String, dynamic>;
        _orgId = tempOrg['orgId']?.toString() ?? '';
      } catch (_) {}
    }
    if (_orgId.isEmpty) _orgId = prefs.getString('tempOrgId') ?? '';

    // ── Check if orgName already cached ──
    _orgName = prefs.getString('tempOrgName') ?? '';

    if (mounted) setState(() {});

    // ── Fetch org name from API if not cached ──
    if (_orgName.isEmpty && _orgId.isNotEmpty) {
      await _fetchOrgName(prefs);
    }

    await _fetchClasses();
  }

  // ── NEW: fetch org details to get orgName ──────────────
  Future<void> _fetchOrgName(SharedPreferences prefs) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/org/$_orgId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final org = body['org'] as Map<String, dynamic>?;
        final name = org?['orgName']?.toString() ?? '';
        if (name.isNotEmpty) {
          _orgName = name;
          // ── Cache it so next time we don't need to fetch ──
          await prefs.setString('tempOrgName', name);
          if (mounted) setState(() {});
        }
      }
    } catch (_) {
      // silently fail — header will show 'Loading...'
    }
  }

  // ─── Helpers ─────────────────────────────────────────────

  String _className(Map<String, dynamic>? cls) =>
      cls?['className']?.toString() ?? 'Class';

  // ─── API ───────────────────────────────────────────────────

  Future<void> _fetchClasses() async {
    if (_orgId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/student/orgs/$_orgId/classes',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['classes'] != null)
          raw = body['classes'] as List;
        else if (body['data'] != null)
          raw = body['data'] as List;
        setState(() {
          _classes = raw.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _snack('Failed to load classes.', Colors.red[600]!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  Future<void> _sendJoinRequest() async {
    if (_selectedClass == null || _studentId.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final classId =
          _selectedClass!['classId']?.toString() ??
          _selectedClass!['_id']?.toString() ??
          '';
      final res = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/student/join-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentId': _studentId, 'classId': classId}),
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('joinStatus', 'pending');
        await prefs.setString('orgId', _orgId);
        setState(() => _step = 3);
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _snack(
          body['message']?.toString() ?? 'Failed to send request.',
          Colors.red[600]!,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _snack('No internet connection.', Colors.red[600]!);
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            // ── Gradient header ──
            Container(
              width: double.infinity,
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
                  padding: EdgeInsets.fromLTRB(14, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_step == 2) ...[
                            GestureDetector(
                              onTap: () => setState(() {
                                _step = 1;
                                _selectedClass = null;
                              }),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                          ],
                          Container(
                            padding: EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.group_add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Join a Class',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // ✅ Shows API org name or "Loading..."
                                Text(
                                  _orgName.isNotEmpty ? _orgName : 'Loading...',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),

                      if (_step < 3) ...[
                        Row(children: [_stepDot(1), _stepLine(), _stepDot(2)]),
                        SizedBox(height: 12),
                      ],

                      Text(
                        _step == 1
                            ? 'Select Class 📚'
                            : _step == 2
                            ? 'Confirm Request ✅'
                            : 'Request Sent! 🎉',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        _step == 1
                            ? 'Choose your classroom in ${_orgName.isNotEmpty ? _orgName : '...'}'
                            : _step == 2
                            ? 'Review and send your join request'
                            : 'Waiting for teacher approval',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ──
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: _accent,
                              strokeWidth: 2.5,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Loading classes...',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _step == 1
                    ? _buildClassList()
                    : _step == 2
                    ? _buildConfirm()
                    : _buildDone(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 1: Class list ──────────────────────────────────

  Widget _buildClassList() {
    if (_classes.isEmpty) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(14, 20, 14, 40),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.04),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _accent.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withOpacity(0.1),
                    ),
                    child: Icon(Icons.class_outlined, color: _accent, size: 28),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'No Classes Available',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'This organization has no classes yet.\nContact your teacher or admin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),
            GestureDetector(
              onTap: _fetchClasses,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: _accent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 40),
      itemCount: _classes.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (_, i) {
        final cls = _classes[i];
        return _classCard(cls, () {
          setState(() {
            _selectedClass = cls;
            _step = 2;
          });
        });
      },
    );
  }

  Widget _classCard(Map<String, dynamic> cls, VoidCallback onTap) {
    final name = _className(cls);
    final teacher = cls['teacherName']?.toString() ?? '';
    final count =
        cls['studentCount']?.toString() ??
        (cls['students'] as List?)?.length.toString() ??
        '0';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _accent.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _accent.withOpacity(0.2)),
                  ),
                  child: Icon(Icons.class_rounded, color: _accent, size: 20),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          if (teacher.isNotEmpty) ...[
                            Icon(
                              Icons.person_outline,
                              size: 11,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 2),
                            Text(
                              teacher,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          Icon(
                            Icons.people_outline,
                            size: 11,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '$count students',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _accent.withOpacity(0.25)),
                  ),
                  child: Text(
                    'Join',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Step 2: Confirm ───────────────────────────────────

  Widget _buildConfirm() {
    final className = _className(_selectedClass);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14, 16, 14, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _accent.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                _confirmRow(
                  Icons.business_rounded,
                  'ORGANIZATION',
                  // ✅ real API org name here
                  _orgName.isNotEmpty ? _orgName : 'Loading...',
                ),
                Divider(height: 16, color: Colors.grey[100]),
                _confirmRow(Icons.class_rounded, 'CLASSROOM', className),
              ],
            ),
          ),
          SizedBox(height: 12),

          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _accent, size: 15),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your request will be reviewed by the teacher. You\'ll be notified once approved.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

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
                onPressed: _isSubmitting ? null : _sendJoinRequest,
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
                child: _isSubmitting
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
                            'Sending...',
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
                            Icons.send_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Send Join Request',
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
        ],
      ),
    );
  }

  Widget _confirmRow(IconData icon, String label, String value) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Icon(icon, color: _accent, size: 18),
      ),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  // ─── Step 3: Done ──────────────────────────────────────

  Widget _buildDone() => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.1),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.green[600],
              size: 38,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Request Sent!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your join request has been sent to the teacher.\nYou\'ll be notified once it\'s approved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.pending_actions_rounded, color: _accent, size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Status: Pending approval from teacher',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Check status button ──
          GestureDetector(
            onTap: _checkStatus,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isCheckingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Check Approval Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // ── Sign out button ──
          GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginPage()),
                  (route) => false,
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ─── Step indicator ───────────────────────────────────

  Widget _stepDot(int step) => Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _step >= step ? Colors.white : Colors.white.withOpacity(0.25),
    ),
    child: Center(
      child: _step > step
          ? Icon(Icons.check_rounded, color: _accent, size: 14)
          : Text(
              step == 1 ? '1' : '2',
              style: TextStyle(
                color: _step == step ? _accent : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
    ),
  );

  Widget _stepLine() => Expanded(
    child: Container(height: 2, color: Colors.white.withOpacity(0.3)),
  );
}
