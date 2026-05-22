import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/drawer_helper.dart';
import '../widgets/classroom_card.dart';
import 'classroom_detail_page.dart';
import 'create_classroom_page.dart';
import 'teacher_settings_page.dart';

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
  String _errorDetails = '';
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

  Future<void> _fetchClassrooms() async {
    if (_orgId.isEmpty && _teacherId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorDetails = 'Teacher ID and Org ID are both empty.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorDetails = '';
    });
    try {
      List<dynamic> raw = [];

      if (_orgId.isNotEmpty) {
        final res = await http.get(
          Uri.parse(
            '${ApiConstants.apiBaseUrl}/classroom/org/$_orgId',
          ),
          headers: await ApiService.getHeaders(),
        );
        if (!mounted) return;
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is List)
            raw = body;
          else if (body['classrooms'] != null)
            raw = body['classrooms'] as List;
          else if (body['data'] != null)
            raw = body['data'] as List;
        }
      }

      if (raw.isEmpty && _teacherId.isNotEmpty) {
        final res = await http.get(
          Uri.parse(
            '${ApiConstants.apiBaseUrl}/classroom/teacher/$_teacherId',
          ),
          headers: await ApiService.getHeaders(),
        );
        if (!mounted) return;
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is List)
            raw = body;
          else if (body['classrooms'] != null)
            raw = body['classrooms'] as List;
          else if (body['data'] != null)
            raw = body['data'] as List;
        }
      }

      if (!mounted) return;
      setState(() {
        _classrooms = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _isLoading = false;
        _hasError = false;
      });
    } catch (e, st) {
      debugPrint('[FetchClassrooms] ❌ EXCEPTION: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorDetails = '$e\n$st';
      });
    }
  }

  Future<void> _deleteClassroom(String classId, int index) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.apiBaseUrl}/classroom/$classId'),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _classrooms.removeAt(index));
        _snack('Classroom deleted.', Colors.green[600]!);
      } else {
        _snack('Failed to delete classroom.', Colors.red[600]!);
      }
    } catch (_) {
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  void _confirmDelete(String classId, String className, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.delete_rounded,
                color: Colors.red[600],
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Delete Classroom',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Delete "$className"? This cannot be undone.',
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
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteClassroom(classId, index);
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
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  children: [
                    // Logo icon
                    Builder(
                      builder: (context) => GestureDetector(
                        onTap: () => openParentDrawer(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SchoolSync',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            _isLoading
                                ? 'Loading...'
                                : _orgId.isNotEmpty
                                ? '${_classrooms.length} org classroom${_classrooms.length == 1 ? '' : 's'}'
                                : '${_classrooms.length} your classroom${_classrooms.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Refresh button
                    if (!_isLoading) ...[
                      GestureDetector(
                        onTap: _fetchClassrooms,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // New Classroom button
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateClassroomPage(teacherId: _teacherId),
                          ),
                        );
                        _fetchClassrooms();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: _accent, size: 15),
                            const SizedBox(width: 5),
                            Text(
                              'New',
                              style: TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TeacherSettingsPage()),
                        );
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              clipBehavior: Clip.antiAlias,
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
                        padding: EdgeInsets.fromLTRB(
                          14,
                          14,
                          14,
                          40 + MediaQuery.of(context).padding.bottom,
                        ),
                        itemCount: _classrooms.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                                _confirmDelete(classId, className, index),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() => Center(
    child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
  );

  Widget _buildError() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Could not load classrooms',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (_errorDetails.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _errorDetails,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: _fetchClassrooms,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 14, color: Colors.white),
              label: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: _accent.withOpacity(0.08),
            ),
            child: Icon(Icons.class_outlined, color: _accent, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            'No Classrooms Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'No classrooms found for your organization.\nTap below to create the first one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateClassroomPage(teacherId: _teacherId),
                  ),
                );
                _fetchClassrooms();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              icon: const Icon(
                Icons.add_rounded,
                size: 15,
                color: Colors.white,
              ),
              label: const Text(
                'New Classroom',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

