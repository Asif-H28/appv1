import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

class StudentsManagementView extends StatefulWidget {
  final String classId;
  final List<Map<String, dynamic>> allApproved;
  final VoidCallback onRefresh;

  const StudentsManagementView({
    required this.classId,
    required this.allApproved,
    required this.onRefresh,
  });

  @override
  State<StudentsManagementView> createState() => _StudentsManagementViewState();
}

class _StudentsManagementViewState extends State<StudentsManagementView> {
  static const Color _accent = Colors.teal;

  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];
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
    _filtered = List.from(widget.allApproved);
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void didUpdateWidget(StudentsManagementView old) {
    super.didUpdateWidget(old);
    _onSearch();
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
          ? List.from(widget.allApproved)
          : widget.allApproved.where((s) {
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
          '${ApiConstants.apiBaseUrl}/join/class/${widget.classId}/student/$studentId',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 404) {
        setState(() => _removingMap.remove(studentId));
        widget.onRefresh();
        _snack('$name removed.', Colors.orange[700]!);
      } else {
        setState(() => _removingMap.remove(studentId));
        _snack('Failed to remove student.', Colors.red[600]!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _removingMap.remove(studentId));
      _snack('No internet connection.', Colors.red[600]!);
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        titlePadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        contentPadding: EdgeInsets.fromLTRB(16, 10, 16, 0),
        actionsPadding: EdgeInsets.fromLTRB(16, 8, 16, 14),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.person_remove_rounded,
                color: Colors.red[600],
                size: 15,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Remove Student',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Remove $name from this classroom?\nThey can re-apply after removal.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: Theme(
                    data: ThemeData(
                      colorScheme: ColorScheme.light(
                        primary: Colors.red[600]!,
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _removeStudent(student);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: Text(
                        'Remove',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
    return Column(
      children: [
        // â”€â”€ Search + count â”€â”€
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            children: [
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
                          '${widget.allApproved.length} Student${widget.allApproved.length == 1 ? '' : 's'}',
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
                    onTap: widget.onRefresh,
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

        Container(height: 1, color: Colors.grey[100]),

        widget.allApproved.isEmpty
            ? _buildEmpty()
            : _filtered.isEmpty
            ? _buildNoResults()
            : Expanded(
                child: RefreshIndicator(
                  color: _accent,
                  onRefresh: () async => widget.onRefresh(),
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
              borderRadius: BorderRadius.circular(3),
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
}

