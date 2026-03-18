import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/classroom_card.dart';
import 'classroom_detail_page.dart';
import 'create_classroom_page.dart';

class TeacherClassroomPage extends StatefulWidget {
  @override
  _TeacherClassroomPageState createState() => _TeacherClassroomPageState();
}

class _TeacherClassroomPageState extends State<TeacherClassroomPage> {
  final Color _accent = Colors.teal;
  String _teacherId = '';
  String _orgId = '';
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _classrooms = [];

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    final prefs = await SharedPreferences.getInstance();
    _teacherId = prefs.getString('teacherId') ?? '';
    _orgId = prefs.getString('orgId') ?? '';
    await _fetchClassrooms();
  }

  // ── Fetch by orgId (primary), fallback to teacherId ──
  Future<void> _fetchClassrooms() async {
    if (_orgId.isEmpty && _teacherId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      List<dynamic> raw = [];

      // ── Step 1: Try org-wide fetch ──
      if (_orgId.isNotEmpty) {
        final orgResponse = await http.get(
          Uri.parse(
            'https://appv1backend.onrender.com/api/classroom/org/$_orgId',
          ),
          headers: {'Content-Type': 'application/json'},
        );

        if (!mounted) return;

        if (orgResponse.statusCode == 200) {
          final body = jsonDecode(orgResponse.body);
          if (body is List) {
            raw = body;
          } else if (body['classrooms'] != null) {
            raw = body['classrooms'] as List;
          } else if (body['data'] != null) {
            raw = body['data'] as List;
          }
        }
      }

      // ── Step 2: Fallback to teacher-specific fetch ──
      if (raw.isEmpty && _teacherId.isNotEmpty) {
        final teacherResponse = await http.get(
          Uri.parse(
            'https://appv1backend.onrender.com/api/classroom/teacher/$_teacherId',
          ),
          headers: {'Content-Type': 'application/json'},
        );

        if (!mounted) return;

        if (teacherResponse.statusCode == 200) {
          final body = jsonDecode(teacherResponse.body);
          if (body is List) {
            raw = body;
          } else if (body['classrooms'] != null) {
            raw = body['classrooms'] as List;
          } else if (body['data'] != null) {
            raw = body['data'] as List;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _classrooms = raw.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _deleteClassroom(String classId, int index) async {
    try {
      final response = await http.delete(
        Uri.parse('https://appv1backend.onrender.com/api/classroom/$classId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _classrooms.removeAt(index));
        _showSnackBar('Classroom deleted successfully.', Colors.green[600]!);
      } else {
        _showSnackBar('Failed to delete classroom.', Colors.red[600]!);
      }
    } catch (e) {
      _showSnackBar('No internet connection.', Colors.red[600]!);
    }
  }

  void _showDeleteConfirm(String classId, String className, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(Icons.delete_rounded, color: Colors.red[600]),
            ),
            SizedBox(width: 12),
            Text(
              'Delete Classroom',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$className"? This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
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
              _deleteClassroom(classId, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Classrooms',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          // ── Source indicator ──
                          Row(
                            children: [
                              Icon(
                                _orgId.isNotEmpty
                                    ? Icons.business_rounded
                                    : Icons.person_rounded,
                                color: Colors.white.withOpacity(0.8),
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                _isLoading
                                    ? 'Loading...'
                                    : _orgId.isNotEmpty
                                    ? '${_classrooms.length} org classroom${_classrooms.length == 1 ? '' : 's'}'
                                    : '${_classrooms.length} your classroom${_classrooms.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!_isLoading)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white),
                          onPressed: _fetchClassrooms,
                          tooltip: 'Refresh',
                        ),
                      ),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: _isLoading
                  ? _buildLoading()
                  : _hasError
                  ? _buildError()
                  : _classrooms.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: _accent,
                      onRefresh: _fetchClassrooms,
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 100),
                        itemCount: _classrooms.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final cls = _classrooms[index];
                          final classId = cls['classId']?.toString() ?? '';
                          final className =
                              cls['className']?.toString() ?? 'Class';
                          return ClassroomCard(
                            classroom: cls,
                            index: index,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClassroomDetailPage(
                                    classId: classId,
                                    className: className,
                                  ),
                                ),
                              );
                              _fetchClassrooms();
                            },
                            onDelete: () =>
                                _showDeleteConfirm(classId, className, index),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),

      // ── FAB ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateClassroomPage(teacherId: _teacherId),
            ),
          );
          _fetchClassrooms();
        },
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(Icons.add_rounded),
        label: Text(
          'New Classroom',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _accent, strokeWidth: 3),
        SizedBox(height: 16),
        Text(
          'Loading classrooms...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey[400]),
          SizedBox(height: 14),
          Text(
            'Could not load classrooms',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Check your internet and try again.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _fetchClassrooms,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.refresh),
            label: Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.1),
            ),
            child: Icon(Icons.class_outlined, color: _accent, size: 40),
          ),
          SizedBox(height: 18),
          Text(
            'No Classrooms Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'No classrooms found for your organization.\nTap below to create the first one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}
