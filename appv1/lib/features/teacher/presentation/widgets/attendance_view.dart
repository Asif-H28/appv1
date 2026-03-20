import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class AttendanceView extends StatefulWidget {
  final String classId;
  final List<Map<String, dynamic>> students;

  const AttendanceView({required this.classId, required this.students});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  static const Color _accent = Colors.teal;

  final Map<String, String?> _attendance = {};
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _saved = false;
  bool _isLoadingExisting = false;
  String? _existingAttendanceId;

  @override
  void initState() {
    super.initState();
    _initAttendance();
    _fetchExistingAttendance();
  }

  void _initAttendance() {
    for (final s in widget.students) {
      final id = s['studentId']?.toString() ?? '';
      if (id.isNotEmpty) _attendance[id] = null;
    }
  }

  Future<void> _fetchExistingAttendance() async {
    setState(() {
      _isLoadingExisting = true;
      _saved = false;
    });
    final dateStr = _formatDate(_selectedDate);
    try {
      final response = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/attendance/class/${widget.classId}/date/$dateStr',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final att = body['attendance'] as Map<String, dynamic>?;
        if (att != null) {
          _existingAttendanceId = att['attendanceId']?.toString();
          final list = att['students'] as List? ?? [];
          for (final s in list) {
            final id = (s as Map)['studentId']?.toString() ?? '';
            final status = s['attendance']?.toString() ?? '';
            if (id.isNotEmpty) _attendance[id] = status;
          }
          setState(() => _saved = true);
        } else {
          _resetAttendance();
        }
      } else {
        _resetAttendance();
      }
    } catch (_) {
      _resetAttendance();
    }
    if (mounted) setState(() => _isLoadingExisting = false);
  }

  void _resetAttendance() {
    _existingAttendanceId = null;
    _saved = false;
    for (final key in _attendance.keys) _attendance[key] = null;
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  int get _markedCount => _attendance.values.where((v) => v != null).length;
  int get _presentCount =>
      _attendance.values.where((v) => v == 'Present').length;
  int get _absentCount => _attendance.values.where((v) => v == 'Absent').length;
  bool get _allMarked =>
      widget.students.isNotEmpty && _markedCount == widget.students.length;

  void _markAll(String status) {
    setState(() {
      for (final key in _attendance.keys) _attendance[key] = status;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(
            primary: _accent,
            onPrimary: Colors.white,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _resetAttendance();
      });
      _fetchExistingAttendance();
    }
  }

  Future<void> _saveAttendance() async {
    if (!_allMarked) {
      _snack('Mark attendance for all students first.', Colors.orange[700]!);
      return;
    }
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final teacherId = prefs.getString('teacherId') ?? '';
    final teacherName = prefs.getString('teacherName') ?? '';
    final orgId = prefs.getString('orgId') ?? '';
    final dateStr = _formatDate(_selectedDate);

    final students = widget.students.map((s) {
      final id = s['studentId']?.toString() ?? '';
      final name = s['studentName']?.toString() ?? s['name']?.toString() ?? '';
      return {
        'studentId': id,
        'name': name,
        'attendance': _attendance[id] ?? 'Absent',
      };
    }).toList();

    try {
      http.Response response;
      if (_existingAttendanceId != null) {
        response = await http.put(
          Uri.parse(
            'https://appv1backend.onrender.com/api/attendance/$_existingAttendanceId',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'students': students}),
        );
      } else {
        response = await http.post(
          Uri.parse('https://appv1backend.onrender.com/api/attendance/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'attendanceDate': dateStr,
            'classId': widget.classId,
            'orgId': orgId,
            'teacherId': teacherId,
            'teacherName': teacherName,
            'students': students,
          }),
        );
      }
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        _existingAttendanceId =
            body['attendance']?['attendanceId']?.toString() ??
            _existingAttendanceId;
        setState(() => _saved = true);
        _snack('Attendance saved!', Colors.green[600]!);
      } else {
        _snack('Failed to save attendance.', Colors.red[600]!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    if (widget.students.isEmpty) return _buildNoStudents();

    return Column(
      children: [
        _buildHeader(),
        Container(height: 1, color: Colors.grey[100]),
        Expanded(
          child: _isLoadingExisting
              ? Center(
                  child: CircularProgressIndicator(
                    color: _accent,
                    strokeWidth: 2.5,
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 100),
                  itemCount: widget.students.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.grey[100], height: 1),
                  itemBuilder: (_, i) => _attendanceTile(widget.students[i]),
                ),
        ),
        _buildSaveBar(),
      ],
    );
  }

  // ── Header: date row + quick actions + progress ──
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: date picker + mark-all buttons
          Row(
            children: [
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _accent.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: _accent,
                        size: 13,
                      ),
                      SizedBox(width: 6),
                      Text(
                        _displayDate(_selectedDate),
                        style: TextStyle(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: _accent,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: () => _markAll('Present'),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Text(
                    'All P',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6),
              GestureDetector(
                onTap: () => _markAll('Absent'),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Text(
                    'All A',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Row 2: saved badge (only when saved) — own line, no overflow
          if (_saved) ...[
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.green.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green[600],
                    size: 11,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Attendance already saved for this date',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 8),

          // Row 3: stat badges + progress
          Row(
            children: [
              _statBadge(
                '${widget.students.length}',
                'Total',
                Colors.grey[600]!,
              ),
              SizedBox(width: 6),
              _statBadge('$_presentCount', 'Present', Colors.green[600]!),
              SizedBox(width: 6),
              _statBadge('$_absentCount', 'Absent', Colors.red[400]!),
              Spacer(),
              Text(
                '$_markedCount / ${widget.students.length} marked',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: widget.students.isEmpty
                  ? 0
                  : _markedCount / widget.students.length,
              minHeight: 4,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky save button ──
  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Theme(
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
            onPressed: (_isSaving || !_allMarked) ? null : _saveAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[200],
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: _isSaving
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
                        'Saving...',
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
                        _saved ? Icons.update_rounded : Icons.save_rounded,
                        size: 16,
                        color: _allMarked ? Colors.white : Colors.grey[400],
                      ),
                      SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          _allMarked
                              ? (_saved
                                    ? 'Update Attendance'
                                    : 'Save Attendance')
                              : '$_markedCount / ${widget.students.length} marked — mark all to save',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: _allMarked ? Colors.white : Colors.grey[400],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _attendanceTile(Map<String, dynamic> student) {
    final name =
        student['studentName']?.toString() ??
        student['name']?.toString() ??
        'Student';
    final studentId = student['studentId']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final status = _attendance[studentId];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          _attendanceBtn(
            label: 'P',
            active: status == 'Present',
            activeColor: Colors.green[600]!,
            onTap: () => setState(() => _attendance[studentId] = 'Present'),
          ),
          SizedBox(width: 6),
          _attendanceBtn(
            label: 'A',
            active: status == 'Absent',
            activeColor: Colors.red[500]!,
            onTap: () => setState(() => _attendance[studentId] = 'Absent'),
          ),
        ],
      ),
    );
  }

  Widget _attendanceBtn({
    required String label,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        width: 44,
        height: 32,
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: active ? activeColor : Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey[500],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 10),
        ),
      ],
    ),
  );

  Widget _buildNoStudents() => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
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
            child: Icon(Icons.fact_check_outlined, color: _accent, size: 26),
          ),
          SizedBox(height: 12),
          Text(
            'No Students Enrolled',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Add students to take attendance.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
