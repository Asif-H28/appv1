import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'students_management_view.dart';
import 'attendance_view.dart';

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

class _ClassroomStudentsTabState extends State<ClassroomStudentsTab>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Colors.teal;
  late TabController _innerTab;
  int _activeTab = 0;

  List<Map<String, dynamic>> _allApproved = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 2, vsync: this);
    _innerTab.addListener(() {
      if (!_innerTab.indexIsChanging)
        setState(() => _activeTab = _innerTab.index);
    });
    _fetchApprovedStudents();
  }

  @override
  void dispose() {
    _innerTab.dispose();
    super.dispose();
  }

  Future<void> _fetchApprovedStudents() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/join/class/${widget.classId}',
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
        setState(() {
          _allApproved = raw
              .map((e) => e as Map<String, dynamic>)
              .where((r) => r['status']?.toString() == 'approved')
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
      );
    if (_hasError) return _buildError();

    return Column(
      children: [
        // ── Inner tab bar ──
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(
            children: [
              _tabChip(0, Icons.people_rounded, 'Students'),
              SizedBox(width: 8),
              _tabChip(1, Icons.fact_check_rounded, 'Attendance'),
            ],
          ),
        ),
        Container(height: 1, color: Colors.grey[100]),

        Expanded(
          child: TabBarView(
            controller: _innerTab,
            children: [
              StudentsManagementView(
                classId: widget.classId,
                allApproved: _allApproved,
                onRefresh: _fetchApprovedStudents,
              ),
              AttendanceView(classId: widget.classId, students: _allApproved),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabChip(int index, IconData icon, String label) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () {
        _innerTab.animateTo(index);
        setState(() => _activeTab = index);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _accent : Colors.grey[100],
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: active ? _accent : Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
            SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          Theme(
            data: ThemeData(
              colorScheme: ColorScheme.light(
                primary: _accent,
                onPrimary: Colors.white,
              ),
            ),
            child: SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: _fetchApprovedStudents,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                icon: Icon(Icons.refresh, size: 14, color: Colors.white),
                label: Text(
                  'Retry',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
