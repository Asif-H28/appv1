import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class StudentJoinOrgPage extends StatefulWidget {
  @override
  _StudentJoinOrgPageState createState() => _StudentJoinOrgPageState();
}

class _StudentJoinOrgPageState extends State<StudentJoinOrgPage> {
  static const Color _accent = Colors.orange;

  // ── Step control ──
  int _step = 0; // 0=orgs 1=classes 2=confirm 3=done

  // ── Data ──
  List<Map<String, dynamic>> _orgs = [];
  List<Map<String, dynamic>> _classes = [];
  Map<String, dynamic>? _selectedOrg;
  Map<String, dynamic>? _selectedClass;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String _studentId = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getString('studentId') ?? '';
    await _fetchOrgs();
  }

  Future<void> _fetchOrgs() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://appv1backend.onrender.com/api/student/orgs'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['orgs'] != null)
          raw = body['orgs'] as List;
        else if (body['data'] != null)
          raw = body['data'] as List;
        else if (body['organizations'] != null)
          raw = body['organizations'] as List;

        setState(() {
          _orgs = raw.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _snack('Failed to load organizations.', Colors.red[600]!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  Future<void> _fetchClasses(String orgId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/student/orgs/$orgId/classes',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
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
          _step = 1;
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
      final response = await http.post(
        Uri.parse('https://appv1backend.onrender.com/api/student/join-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentId': _studentId, 'classId': classId}),
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _step = 3);
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
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
                padding: EdgeInsets.fromLTRB(20, 14, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Back (only on step 1+) ──
                    if (_step > 0 && _step < 3)
                      GestureDetector(
                        onTap: () => setState(() {
                          _step--;
                          if (_step == 0) _selectedOrg = null;
                          if (_step == 1) _selectedClass = null;
                        }),
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
                    if (_step > 0 && _step < 3) SizedBox(height: 12),

                    // ── Step indicator ──
                    if (_step < 3)
                      Row(
                        children: [
                          _stepDot(0),
                          _stepLine(),
                          _stepDot(1),
                          _stepLine(),
                          _stepDot(2),
                        ],
                      ),
                    if (_step < 3) SizedBox(height: 12),

                    Text(
                      _step == 0
                          ? 'Select Organization'
                          : _step == 1
                          ? 'Select Class'
                          : _step == 2
                          ? 'Confirm Request'
                          : 'Request Sent!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      _step == 0
                          ? 'Choose your school / institution'
                          : _step == 1
                          ? 'Choose your classroom in ${_selectedOrg?['name'] ?? ''}'
                          : _step == 2
                          ? 'Review and send your join request'
                          : 'Waiting for teacher approval',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ──
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                      strokeWidth: 2.5,
                    ),
                  )
                : _step == 0
                ? _buildOrgList()
                : _step == 1
                ? _buildClassList()
                : _step == 2
                ? _buildConfirm()
                : _buildDone(),
          ),
        ],
      ),
    );
  }

  // ── Step 0: Org list ──
  Widget _buildOrgList() {
    if (_orgs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_outlined, size: 48, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(
              'No organizations found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            _outlineBtn('Refresh', _fetchOrgs),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: _orgs.length,
      separatorBuilder: (_, __) => SizedBox(height: 10),
      itemBuilder: (_, i) {
        final org = _orgs[i];
        final orgId = org['orgId']?.toString() ?? org['_id']?.toString() ?? '';
        return _orgCard(org, () {
          setState(() => _selectedOrg = org);
          _fetchClasses(orgId);
        });
      },
    );
  }

  Widget _orgCard(Map<String, dynamic> org, VoidCallback onTap) {
    final name = org['name']?.toString() ?? 'Organization';
    final type = org['orgType']?.toString() ?? '';
    final city = org['city']?.toString() ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.07),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: _accent.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.business_rounded, color: _accent, size: 22),
            ),
            SizedBox(width: 12),
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
                  ),
                  if (type.isNotEmpty || city.isNotEmpty)
                    Text(
                      [type, city].where((s) => s.isNotEmpty).join(' • '),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _accent),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Class list ──
  Widget _buildClassList() {
    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.class_outlined, size: 48, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(
              'No classes available',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'This organization has no classes yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: _classes.length,
      separatorBuilder: (_, __) => SizedBox(height: 10),
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
    final name = cls['className']?.toString() ?? 'Class';
    final teacher = cls['teacherName']?.toString() ?? '';
    final studentCount =
        cls['studentCount']?.toString() ??
        (cls['students'] as List?)?.length.toString() ??
        '0';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.07),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: _accent.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.class_rounded, color: _accent, size: 22),
            ),
            SizedBox(width: 12),
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
                  ),
                  Row(
                    children: [
                      if (teacher.isNotEmpty) ...[
                        Icon(
                          Icons.person_outline,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 3),
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
                      SizedBox(width: 3),
                      Text(
                        '$studentCount students',
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
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _accent),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Confirm ──
  Widget _buildConfirm() {
    final orgName = _selectedOrg?['name']?.toString() ?? 'Organization';
    final className = _selectedClass?['className']?.toString() ?? 'Class';
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        children: [
          // ── Summary card ──
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
              border: Border.all(color: _accent.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                _confirmRow(Icons.business_rounded, 'Organization', orgName),
                Divider(height: 20, color: Colors.grey[200]),
                _confirmRow(Icons.class_rounded, 'Classroom', className),
              ],
            ),
          ),
          SizedBox(height: 20),

          // ── Info banner ──
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _accent, size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your request will be reviewed by the teacher. You\'ll be notified once approved.',
                    style: TextStyle(color: _accent, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _sendJoinRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _accent.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
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
                        Icon(Icons.send_rounded, size: 15),
                        SizedBox(width: 8),
                        Text(
                          'Send Join Request',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
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

  Widget _confirmRow(IconData icon, String label, String value) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9),
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
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
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

  // ── Step 3: Done ──
  Widget _buildDone() => Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.1),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.green[600],
              size: 42,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Request Sent!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your join request has been sent to the teacher.\nYou\'ll be notified once it\'s approved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          SizedBox(height: 28),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.pending_actions_rounded, color: _accent, size: 20),
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
        ],
      ),
    ),
  );

  // ── Helpers ──
  Widget _stepDot(int step) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _step >= step ? Colors.white : Colors.white.withOpacity(0.3),
    ),
    child: Center(
      child: _step > step
          ? Icon(Icons.check_rounded, color: _accent, size: 14)
          : Text(
              '${step + 1}',
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

  Widget _outlineBtn(String label, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: _accent,
      side: BorderSide(color: _accent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
    child: Text(
      label,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );
}
