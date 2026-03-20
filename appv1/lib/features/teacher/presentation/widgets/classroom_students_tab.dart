import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

class ClassroomStudentsTab extends StatefulWidget {
  final String classId;
  final List<String> students;
  final VoidCallback onRefresh;

  const ClassroomStudentsTab({
    required this.classId,
    required this.students,
    required this.onRefresh,
  });

  @override
  _ClassroomStudentsTabState createState() => _ClassroomStudentsTabState();
}

class _ClassroomStudentsTabState extends State<ClassroomStudentsTab> {
  static const Color _accent = Colors.teal;

  List<Map<String, dynamic>> _allApproved = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  bool _hasError = false;
  final _searchCtrl = TextEditingController();
  final Map<String, bool> _removingMap = {};

  static const List<List<Color>> _gradients = [
    [Color(0xFF00897B), Color(0xFF4DB6AC)],
    [Color(0xFF00796B), Color(0xFF80CBC4)],
    [Color(0xFF26A69A), Color(0xFF80CBC4)],
    [Color(0xFF00ACC1), Color(0xFF4DD0E1)],
    [Color(0xFF0097A7), Color(0xFF80DEEA)],
  ];

  @override
  void initState() {
    super.initState();
    _fetchApprovedStudents();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_allApproved)
          : _allApproved.where((s) {
              final name =
                  (s['studentName']?.toString() ?? s['name']?.toString() ?? '')
                      .toLowerCase();
              final email =
                  (s['studentEmail']?.toString() ??
                          s['email']?.toString() ??
                          '')
                      .toLowerCase();
              final id = (s['studentId']?.toString() ?? '').toLowerCase();
              return name.contains(q) || email.contains(q) || id.contains(q);
            }).toList();
    });
  }

  Future<void> _fetchApprovedStudents() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/join/class/${widget.classId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['requests'] is List)
          raw = body['requests'] as List;
        else if (body['data'] is List)
          raw = body['data'] as List;

        final approved = raw
            .map((e) => e as Map<String, dynamic>)
            .where((r) => r['status']?.toString() == 'approved')
            .toList();

        if (!mounted) return;
        setState(() {
          _allApproved = approved;
          _isLoading = false;
        });
        _onSearch();
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _removeStudent(Map<String, dynamic> student) async {
    final studentId = student['studentId']?.toString() ?? '';
    final name =
        student['studentName']?.toString() ??
        student['name']?.toString() ??
        'Student';
    if (studentId.isEmpty) return;
    setState(() => _removingMap[studentId] = true);
    try {
      final response = await http.delete(
        Uri.parse(
          'https://appv1backend.onrender.com/api/join/class/${widget.classId}/student/$studentId',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 404) {
        setState(() {
          _removingMap.remove(studentId);
          _allApproved.removeWhere(
            (s) => s['studentId']?.toString() == studentId,
          );
        });
        _onSearch();
        _snack('$name removed from classroom.', Colors.orange[700]!);
      } else {
        final body = _tryDecode(response.body);
        setState(() => _removingMap.remove(studentId));
        _snack(
          body['message']?.toString() ?? 'Failed to remove student.',
          Colors.red[600]!,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _removingMap.remove(studentId));
      _snack(
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Failed to remove student.',
        Colors.red[600]!,
      );
    }
  }

  Map<String, dynamic> _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _confirmRemove(Map<String, dynamic> student) {
    final name =
        student['studentName']?.toString() ??
        student['name']?.toString() ??
        'this student';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 0),
        actionsPadding: EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.person_remove_rounded,
                color: Colors.red[600],
                size: 16,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Remove Student',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        content: Text(
          'Remove $name from this classroom?\nThey can re-apply after removal.',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.5,
            fontSize: 12.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeStudent(student);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Remove',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
      );
    }
    if (_hasError) return _buildError();

    return Column(
      children: [
        // ── Search + count header ──
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar — no focus border, no blue outline
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[400],
                        size: 17,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        cursorColor: _accent,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchCtrl.clear(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.grey[400],
                            size: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 8),

              // Count + refresh row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: _accent.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_rounded, color: _accent, size: 11),
                        SizedBox(width: 4),
                        Text(
                          '${_allApproved.length} Student${_allApproved.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_searchCtrl.text.trim().isNotEmpty) ...[
                    SizedBox(width: 6),
                    Text(
                      '${_filtered.length} result${_filtered.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                  Spacer(),
                  GestureDetector(
                    onTap: _fetchApprovedStudents,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Colors.grey[500],
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Divider(height: 1, color: Colors.grey[100]),

        // ── List / Empty states ──
        _allApproved.isEmpty
            ? _buildEmpty()
            : _filtered.isEmpty
            ? _buildNoResults()
            : Expanded(
                child: RefreshIndicator(
                  color: _accent,
                  onRefresh: _fetchApprovedStudents,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 40),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey[100], height: 1),
                    itemBuilder: (_, i) => _studentTile(_filtered[i], i),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _studentTile(Map<String, dynamic> student, int index) {
    final name =
        student['studentName']?.toString() ??
        student['name']?.toString() ??
        'Student';
    final email =
        student['studentEmail']?.toString() ??
        student['email']?.toString() ??
        '';
    final studentId = student['studentId']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final gradient = _gradients[index % _gradients.length];
    final isRemoving = _removingMap[studentId] == true;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  email.isNotEmpty ? email : studentId,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          isRemoving
              ? SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.red[400],
                    strokeWidth: 2,
                  ),
                )
              : GestureDetector(
                  onTap: () => _confirmRemove(student),
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Icon(
                      Icons.person_remove_rounded,
                      color: Colors.red[400],
                      size: 14,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Expanded(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.07),
            ),
            child: Icon(Icons.people_outline_rounded, color: _accent, size: 26),
          ),
          SizedBox(height: 12),
          Text(
            'No Approved Students',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Approved requests will appear here.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
        ],
      ),
    ),
  );

  Widget _buildNoResults() => Expanded(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: Colors.grey[400]),
          SizedBox(height: 10),
          Text(
            'No students found',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try a different name or email',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
        ],
      ),
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 42, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'Could not load students',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _fetchApprovedStudents,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              elevation: 0,
            ),
            icon: Icon(Icons.refresh, size: 14),
            label: Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}
