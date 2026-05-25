import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/drawer_helper.dart';
import 'achievement_create_page.dart';
import 'achievement_comments_sheet.dart';
import 'achievement_feed_card.dart';
import 'teacher_settings_page.dart';

class TeacherAchievementsPage extends StatefulWidget {
  const TeacherAchievementsPage({super.key});

  @override
  State<TeacherAchievementsPage> createState() =>
      _TeacherAchievementsPageState();
}

class _TeacherAchievementsPageState extends State<TeacherAchievementsPage> {
  String _orgId = '';
  String _teacherId = '';
  String _teacherName = '';
  String _classId = '';
  String _className = '';
  String _orgName = '';

  bool _loading = true;
  bool _error = false;
  bool _navigating = false;
  List<Map<String, dynamic>> _posts = [];

  int _currentPage = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orgId = prefs.getString('orgId') ?? '';
      _teacherId = prefs.getString('teacherId') ?? '';
      _teacherName = prefs.getString('teacherName') ?? '';
      _classId = prefs.getString('classId') ?? '';
      _className = prefs.getString('className') ?? '';
      _orgName = prefs.getString('orgName') ?? '';
    });
    await _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    if (_orgId.isEmpty) {
      setState(() {
        _loading = false;
        _error = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = false;
      _currentPage = 1;
    });
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/achievement/org/$_orgId?page=1&limit=3',
        ),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final list = (body['achievements'] as List? ?? []);
        final pagination = body['pagination'] as Map?;
        final totalPages = pagination?['pages'] as int? ?? 1;

        setState(() {
          _posts = list
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _hasMore = _currentPage < totalPages;
          _loading = false;
        });
      } else {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _error = true;
          _loading = false;
        });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;

    setState(() {
      _loadingMore = true;
    });

    final nextPage = _currentPage + 1;
    final url = '${ApiConstants.apiBaseUrl}/achievement/org/$_orgId?page=$nextPage&limit=3';

    try {
      final res = await http.get(
        Uri.parse(url),
        headers: await ApiService.getHeaders(),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final list = (body['achievements'] as List? ?? []);
        final pagination = body['pagination'] as Map?;
        final totalPages = pagination?['pages'] as int? ?? 1;

        setState(() {
          _currentPage = nextPage;
          _posts.addAll(
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          );
          _hasMore = _currentPage < totalPages;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _toggleLike(int index) async {
    final post = _posts[index];
    final achId = post['achievementId'].toString();
    final likes = List.from(post['likes'] as List? ?? []);
    final liked = likes.any((l) => l['userId']?.toString() == _teacherId);

    setState(() {
      if (liked) {
        _posts[index]['likes'] = likes
            .where((l) => l['userId']?.toString() != _teacherId)
            .toList();
        _posts[index]['likeCount'] = (post['likeCount'] as int? ?? 1) - 1;
      } else {
        likes.add({
          'userId': _teacherId,
          'userName': _teacherName,
          'userRole': 'teacher',
        });
        _posts[index]['likes'] = likes;
        _posts[index]['likeCount'] = (post['likeCount'] as int? ?? 0) + 1;
      }
    });

    try {
      await http.post(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/achievement/$achId/like',
        ),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'userId': _teacherId,
          'userName': _teacherName,
          'userRole': 'teacher',
        }),
      );
    } catch (_) {}
  }

  void _openComments(int index) {
    final post = _posts[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AchievementCommentsSheet(
        achievementId: post['achievementId'].toString(),
        userId: _teacherId,
        userName: _teacherName,
        userRole: 'teacher',
        initialComments: ((post['comments'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        onChanged: (updatedComments, updatedCount) {
          if (mounted) {
            setState(() {
              _posts[index]['comments'] = updatedComments;
              _posts[index]['commentCount'] = updatedCount;
            });
          }
        },
      ),
    );
  }

  void _openCreate() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    try {
      final created = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AchievementCreatePage(
            teacherId: _teacherId,
            teacherName: _teacherName,
            classId: _classId,
            className: _className,
            orgId: _orgId,
            orgName: _orgName,
          ),
        ),
      );
      if (created == true && mounted) _fetchFeed();
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  void _openEdit(int index) async {
    if (_navigating) return;
    setState(() => _navigating = true);
    try {
      final edited = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AchievementCreatePage(
            teacherId: _teacherId,
            teacherName: _teacherName,
            classId: _classId,
            className: _className,
            orgId: _orgId,
            orgName: _orgName,
            existingPost: _posts[index],
          ),
        ),
      );
      if (edited == true && mounted) _fetchFeed();
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Post',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: const Text('Are you sure you want to delete this post?'),
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
              _deletePost(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(int index) async {
    final achId = _posts[index]['achievementId'].toString();
    try {
      await http.delete(
        Uri.parse('${ApiConstants.apiBaseUrl}/achievement/$achId'),
        headers: await ApiService.getHeaders(),
      );
      if (mounted) setState(() => _posts.removeAt(index));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? _buildSkeleton()
                : _error
                ? _buildError()
                : _posts.isEmpty
                ? _buildEmpty()
                  : RefreshIndicator(
                      color: Colors.teal,
                      onRefresh: _fetchFeed,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _posts.length + (_hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _posts.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: AchievementFeedCard(
                              post: _posts[i],
                              teacherId: _teacherId,
                              onLike: () => _toggleLike(i),
                              onComment: () => _openComments(i),
                              onEdit:
                                  _posts[i]['teacherId']?.toString() == _teacherId
                                  ? () => _openEdit(i)
                                  : null,
                              onDelete:
                                  _posts[i]['teacherId']?.toString() == _teacherId
                                  ? () => _confirmDelete(i)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'teacher_achievement_fab',
        onPressed: _navigating ? null : _openCreate,
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievements',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Celebrate student wins',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
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
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 280,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.grey[400], size: 34),
          const SizedBox(height: 10),
          Text(
            'Failed to load',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _fetchFeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_outlined, color: Colors.teal[200], size: 44),
          const SizedBox(height: 12),
          Text(
            'No achievements yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to celebrate a student win!',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

