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

      debugPrint('STUDENTS STATUS: ${response.statusCode}');
      debugPrint('STUDENTS BODY: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> raw = [];
        if (body is List) {
          raw = body;
        } else if (body['requests'] is List) {
          raw = body['requests'] as List;
        } else if (body['data'] is List) {
          raw = body['data'] as List;
        }

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
      debugPrint('FETCH STUDENTS ERROR: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // ── UPDATED: single API call handles everything ──
  Future<void> _removeStudent(Map<String, dynamic> student) async {
    final studentId = student['studentId']?.toString() ?? '';
    final name =
        student['studentName']?.toString() ??
        student['name']?.toString() ??
        'Student';

    if (studentId.isEmpty) return;

    setState(() => _removingMap[studentId] = true);

    try {
      // ── Single call: removes from classroom + rejects request + resets student ──
      final response = await http.delete(
        Uri.parse(
          'https://appv1backend.onrender.com/api/join/class/${widget.classId}/student/$studentId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('REMOVE STATUS: ${response.statusCode}');
      debugPrint('REMOVE BODY: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 404) {
        // ── Success: remove from local state ──
        setState(() {
          _removingMap.remove(studentId);
          _allApproved.removeWhere(
            (s) => s['studentId']?.toString() == studentId,
          );
        });
        _onSearch(); // rebuild _filtered
        _snack('$name removed from classroom.', Colors.orange[700]!);
      } else {
        // ── API error ──
        final body = _tryDecode(response.body);
        setState(() => _removingMap.remove(studentId));
        _snack(
          body['message']?.toString() ?? 'Failed to remove student.',
          Colors.red[600]!,
        );
      }
    } catch (e) {
      debugPrint('REMOVE ERROR: $e');
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

  // ── Safe JSON decode helper ──
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(
                Icons.person_remove_rounded,
                color: Colors.red[600],
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Remove Student',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
        content: Text(
          'Remove $name from this classroom?\nThey can re-apply after removal.',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.5,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
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
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Remove',
              style: TextStyle(fontWeight: FontWeight.bold),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        // ── Search bar ──
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _searchCtrl,
              cursorColor: _accent,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _accent,
                  size: 20,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: _searchCtrl.clear,
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 13,
                ),
              ),
            ),
          ),
        ),

        // ── Count chip ──
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_rounded, color: _accent, size: 12),
                    SizedBox(width: 5),
                    Text(
                      '${_allApproved.length} Student${_allApproved.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_searchCtrl.text.trim().isNotEmpty) ...[
                SizedBox(width: 8),
                Text(
                  '${_filtered.length} match${_filtered.length == 1 ? '' : 'es'}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),

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
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 40),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey[100], height: 1, indent: 72),
                    itemBuilder: (_, index) =>
                        _studentTile(_filtered[index], index),
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            // ── Gradient avatar ──
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14),

            // ── Name + email ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    email.isNotEmpty ? email : studentId,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Remove / loading ──
            isRemoving
                ? SizedBox(
                    width: 36,
                    height: 36,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                        color: Colors.red[400],
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () => _confirmRemove(student),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.08),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.person_remove_rounded,
                        color: Colors.red[400],
                        size: 16,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() => Expanded(
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.08),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                color: _accent,
                size: 34,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'No Approved Students',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Students approved from the\nRequests tab will appear here.',
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
    ),
  );

  Widget _buildNoResults() => Expanded(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 46, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'No students found',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try a different name or email',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
          Icon(Icons.cloud_off_rounded, size: 46, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'Could not load students',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchApprovedStudents,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: Icon(Icons.refresh, size: 15),
            label: Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    ),
  );
}
