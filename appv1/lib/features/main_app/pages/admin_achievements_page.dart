import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
// admin_achievements_page.dart
import 'dart:convert';
import 'package:appv1/features/student/achievement_comments_sheet.dart';
import 'package:appv1/features/teacher/presentation/pages/achievement_create_page.dart';
import 'package:appv1/features/teacher/presentation/pages/achievement_feed_card.dart';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class AdminAchievementsPage extends StatefulWidget {
  const AdminAchievementsPage({super.key});

  @override
  State<AdminAchievementsPage> createState() => _AdminAchievementsPageState();
}

class _AdminAchievementsPageState extends State<AdminAchievementsPage> {
  String _orgId = '';
  String _adminId = '';
  String _adminName = '';
  String _orgName = '';

  bool _loading = true;
  bool _error = false;
  bool _navigating = false;

  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orgId = prefs.getString('orgId') ?? '';
      _adminId = prefs.getString('userId') ?? '';
      _adminName =
          prefs.getString('adminName') ??
          prefs.getString('userName') ??
          prefs.getString('userOrg') ??
          'Admin';
      _orgName = prefs.getString('orgName') ?? prefs.getString('userOrg') ?? '';
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
    });
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/achievement/org/$_orgId',
        ),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _posts = (body['achievements'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
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

  // ── Like toggle ───────────────────────────────────────
  Future<void> _toggleLike(int index) async {
    final post = _posts[index];
    final achId = post['achievementId'].toString();
    final likes = List<dynamic>.from(post['likes'] as List? ?? []);

    // Ensure userId/userName are never empty — backend rejects empty strings
    final likeUserId = _adminId.isNotEmpty ? _adminId : 'Admin';
    final likeUserName = _adminName.isNotEmpty ? _adminName : 'Admin';

    final liked = likes.any((l) => l['userId']?.toString() == likeUserId);

    setState(() {
      if (liked) {
        _posts[index]['likes'] = likes
            .where((l) => l['userId']?.toString() != likeUserId)
            .toList();
        _posts[index]['likeCount'] = (post['likeCount'] as int? ?? 1) - 1;
      } else {
        likes.add({
          'userId': likeUserId,
          'userName': likeUserName,
          'userRole': 'admin',
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
          'userId': likeUserId,
          'userName': likeUserName,
          'userRole': 'admin',
        }),
      );
    } catch (_) {}
  }

  // ── Comments ──────────────────────────────────────────
  void _openComments(int index) {
    final post = _posts[index];
    // Ensure userId/userName are never empty — backend rejects empty strings
    final commentUserId = _adminId.isNotEmpty ? _adminId : 'Admin';
    final commentUserName = _adminName.isNotEmpty ? _adminName : 'Admin';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AchievementCommentsSheet(
        achievementId: post['achievementId'].toString(),
        userId: commentUserId,
        userName: commentUserName,
        userRole: 'admin',
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

  // ── Create ────────────────────────────────────────────
  void _openCreate() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    try {
      final created = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AchievementCreatePage(
            teacherId: '',
            teacherName: '',
            classId: '',
            className: '',
            orgId: _orgId,
            orgName: _orgName,
            isAdmin: true,
          ),
        ),
      );
      if (created == true && mounted) _fetchFeed();
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  // ── Edit ──────────────────────────────────────────────
  void _openEdit(int index) async {
    if (_navigating) return;
    setState(() => _navigating = true);
    try {
      final post = _posts[index];
      final edited = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AchievementCreatePage(
            teacherId: post['teacherId']?.toString() ?? '',
            teacherName: post['teacherName']?.toString() ?? '',
            classId: post['classId']?.toString() ?? '',
            className: post['className']?.toString() ?? '',
            orgId: _orgId,
            orgName: _orgName,
            existingPost: post,
            isAdmin: true,
          ),
        ),
      );
      if (edited == true && mounted) _fetchFeed();
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  // ── Delete ────────────────────────────────────────────
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        title: const Text(
          'Delete Post',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: const Text('This post will be permanently deleted. Continue?'),
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
                borderRadius: BorderRadius.circular(3),
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

  // ════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? _buildSkeleton()
          : _error
          ? _buildError()
          : _posts.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              color: Colors.teal,
              onRefresh: _fetchFeed,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _posts.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AchievementFeedCard(
                    post: _posts[i],
                    teacherId: _posts[i]['teacherId']?.toString() ?? '',
                    onLike: () => _toggleLike(i),
                    onComment: () => _openComments(i),
                    onEdit: () => _openEdit(i),
                    onDelete: () => _confirmDelete(i),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin_achievement_fab',
        onPressed: _navigating ? null : _openCreate,
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  // ── Skeleton loader ───────────────────────────────────
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

  // ── Error state ───────────────────────────────────────
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

  // ── Empty state ───────────────────────────────────────
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

