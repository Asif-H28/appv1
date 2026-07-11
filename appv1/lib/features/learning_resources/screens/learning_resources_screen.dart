import 'package:flutter/material.dart';
import 'package:appv1/features/student/student_theme_manager.dart';

import 'package:appv1/features/learning_resources/services/lesson_video_service.dart';
import 'package:appv1/features/learning_resources/widgets/video_card.dart';
import 'package:appv1/features/learning_resources/widgets/add_video_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';

class LearningResourcesScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const LearningResourcesScreen({super.key, required this.classData});

  @override
  State<LearningResourcesScreen> createState() => _LearningResourcesScreenState();
}

class _LearningResourcesScreenState extends State<LearningResourcesScreen> {
  StudentThemeConfig get theme => StudentThemeManager.themeNotifier.value;
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _videos = [];
  bool _isTeacher = false;
  String _orgId = '';
  String _teacherId = '';
  String _teacherName = '';

  bool _showMenu = true;
  String _videoType = 'lesson'; // 'lesson' or 'general'
  String? _selectedSubjectId;
  String? _selectedLessonId;

  List<dynamic> _subjects = [];
  List<dynamic> _lessons = [];

  @override
  void initState() {
    super.initState();
    _subjects = widget.classData['subjects'] as List<dynamic>? ?? [];
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? '';
    
    setState(() {
      _isTeacher = role == 'teacher' || role == 'admin';
      _orgId = prefs.getString('orgId') ?? '';
      _teacherId = prefs.getString('teacherId') ?? '';
      _teacherName = prefs.getString('teacherName') ?? 'Teacher';
      _isLoading = false;
    });
  }

  Future<void> _fetchVideos() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final classId = widget.classData['classId'];
    if (classId == null || _orgId.isEmpty) {
      setState(() {
        _error = 'Missing class or organization info';
        _isLoading = false;
      });
      return;
    }

    final result = await LessonVideoService.fetchVideos(
      orgId: _orgId,
      classId: classId,
      videoType: _videoType,
      subjectId: _videoType == 'lesson' ? _selectedSubjectId : null,
      lessonId: _videoType == 'lesson' ? _selectedLessonId : null,
    );

    if (mounted) {
      if (result['success']) {
        setState(() {
          _videos = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load videos';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteVideo(String videoId) async {
    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.dio.delete('/lesson-video/$videoId');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video deleted successfully')),
        );
        _fetchVideos();
      } else {
        setState(() {
          _error = 'Failed to delete video';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error deleting video';
        _isLoading = false;
      });
    }
  }

  void _onSubjectChanged(String? subjectId) {
    setState(() {
      _selectedSubjectId = subjectId;
      _selectedLessonId = null;
      _lessons = [];

      if (subjectId != null) {
        final subject = _subjects.firstWhere(
          (s) => s['_id'] == subjectId || s['id'] == subjectId,
          orElse: () => null,
        );
        if (subject != null) {
          _lessons = subject['lessons'] as List<dynamic>? ?? [];
        }
      }
    });
    _fetchVideos();
  }

  void _showAddVideoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddVideoSheet(
        classData: widget.classData,
        teacherId: _teacherId,
        teacherName: _teacherName,
        orgId: _orgId,
        onSuccess: () {
          _fetchVideos();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showMenu) {
      return Scaffold(
        backgroundColor: theme.background,
        body: _buildMenu(),
      );
    }

    return Scaffold(
      backgroundColor: theme.background,
      floatingActionButton: _isTeacher
          ? FloatingActionButton(
              backgroundColor: theme.primary,
              onPressed: _showAddVideoSheet,
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showMenu = true),
                      child: Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_back, color: theme.primary),
                      ),
                    ),
                    Text(
                      _videoType == 'lesson' ? 'Lesson Videos' : 'General Videos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (_videoType == 'lesson') ...[
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: Text('All Subjects'),
                              value: _selectedSubjectId,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Subjects'),
                                ),
                                ..._subjects.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s['_id'] ?? s['id'],
                                    child: Text(s['name'] ?? 'Unknown'),
                                  );
                                }).toList()
                              ],
                              onChanged: _onSubjectChanged,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: Text('All Lessons'),
                              value: _selectedLessonId,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Lessons'),
                                ),
                                ..._lessons.map((l) {
                                  return DropdownMenuItem<String>(
                                    value: l['_id'] ?? l['id'],
                                    child: Text(l['name'] ?? 'Unknown'),
                                  );
                                }).toList()
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedLessonId = val;
                                });
                                _fetchVideos();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: theme.primary))
                : _error.isNotEmpty
                    ? Center(
                        child: Text(
                          _error,
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    : _videos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
                                SizedBox(height: 16),
                                Text(
                                  'No videos found.',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                ),
                                if (_isTeacher) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    "Tap '+' to share your first resource.",
                                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                  ),
                                ]
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: _videos.length,
                            itemBuilder: (context, index) {
                              final video = _videos[index];
                              return VideoCard(
                                videoData: video,
                                isTeacher: _isTeacher,
                                onDelete: () {
                                  _deleteVideo(video['_id'] ?? video['id'] ?? '');
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'VIDEO CATEGORIES',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.play_lesson,
                  label: 'Lesson Videos',
                  color: theme.primary,
                  onTap: () {
                    setState(() {
                      _videoType = 'lesson';
                      _showMenu = false;
                    });
                    _fetchVideos();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Divider(height: 1, color: Colors.grey[100]),
                ),
                _buildMenuItem(
                  icon: Icons.video_library,
                  label: 'General Videos',
                  color: theme.primary,
                  onTap: () {
                    setState(() {
                      _videoType = 'general';
                      _showMenu = false;
                    });
                    _fetchVideos();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
