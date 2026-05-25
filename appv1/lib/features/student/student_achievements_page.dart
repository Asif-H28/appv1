import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:appv1/features/teacher/presentation/pages/achievement_comments_sheet.dart';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class StudentAchievementsPage extends StatefulWidget {
  const StudentAchievementsPage({super.key});

  @override
  State<StudentAchievementsPage> createState() =>
      _StudentAchievementsPageState();
}

class _StudentAchievementsPageState extends State<StudentAchievementsPage> {
  String _orgId = '';
  String _studentId = '';
  String _studentName = '';

  bool _loading = true;
  bool _error = false;
  List<Map<String, dynamic>> _posts = [];

  int _currentPage = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // shows on-screen in empty/error states
  String _debugInfo = '';

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

    final orgId = prefs.getString('orgId') ?? '';
    final studentId = prefs.getString('studentId') ?? '';
    final studentName = prefs.getString('studentName') ?? '';

    // ── PRINT every key stored in SharedPrefs ──
    debugPrint('==== [Achievements] all prefs keys: ${prefs.getKeys()}');
    debugPrint('==== [Achievements] orgId       = "$orgId"');
    debugPrint('==== [Achievements] studentId   = "$studentId"');
    debugPrint('==== [Achievements] studentName = "$studentName"');

    setState(() {
      _orgId = orgId;
      _studentId = studentId;
      _studentName = studentName;
      _debugInfo = 'orgId="$orgId"  studentId="$studentId"';
    });

    await _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    if (_orgId.isEmpty) {
      debugPrint('==== [Achievements] SKIPPED fetch — orgId is empty');
      setState(() {
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = false;
      _currentPage = 1;
    });

    final url = '${ApiConstants.apiBaseUrl}/achievement/org/$_orgId?page=1&limit=3';
    debugPrint('==== [Achievements] GET $url');

    try {
      final res = await http.get(
        Uri.parse(url),
        headers: await ApiService.getHeaders(),
      );

      debugPrint('==== [Achievements] status = ${res.statusCode}');
      debugPrint('==== [Achievements] body   = ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;

        // ── PRINT top-level keys so we know the exact shape ──
        debugPrint('==== [Achievements] body keys = ${body.keys.toList()}');

        // Try common key names defensively
        final list =
            (body['achievements'] as List?) ??
            (body['data'] as List?) ??
            (body['posts'] as List?) ??
            [];

        final pagination = body['pagination'] as Map?;
        final totalPages = pagination?['pages'] as int? ?? 1;

        debugPrint('==== [Achievements] list length = ${list.length}');

        setState(() {
          _posts = list
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _hasMore = _currentPage < totalPages;
          _loading = false;
          _debugInfo = 'orgId="$_orgId" | posts=${_posts.length}';
        });
      } else {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('==== [Achievements] ERROR: $e');
      debugPrint('==== [Achievements] STACK: $st');
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
    debugPrint('==== [Achievements] LOAD MORE GET $url');

    try {
      final res = await http.get(
        Uri.parse(url),
        headers: await ApiService.getHeaders(),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final list = (body['achievements'] as List?) ??
            (body['data'] as List?) ??
            (body['posts'] as List?) ??
            [];

        final pagination = body['pagination'] as Map?;
        final totalPages = pagination?['pages'] as int? ?? 1;

        setState(() {
          _currentPage = nextPage;
          _posts.addAll(
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          );
          _hasMore = _currentPage < totalPages;
          _loadingMore = false;
          _debugInfo = 'orgId="$_orgId" | posts=${_posts.length}';
        });
      } else {
        setState(() {
          _loadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('==== [Achievements] LOAD MORE ERROR: $e');
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
    final liked = likes.any((l) => l['userId']?.toString() == _studentId);

    setState(() {
      if (liked) {
        _posts[index]['likes'] = likes
            .where((l) => l['userId']?.toString() != _studentId)
            .toList();
        _posts[index]['likeCount'] = ((post['likeCount'] as int? ?? 1) - 1)
            .clamp(0, 9999);
      } else {
        likes.add({
          'userId': _studentId,
          'userName': _studentName,
          'userRole': 'student',
        });
        _posts[index]['likes'] = likes;
        _posts[index]['likeCount'] = (post['likeCount'] as int? ?? 0) + 1;
      }
    });

    try {
      await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/achievement/$achId/like'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'userId': _studentId,
          'userName': _studentName,
          'userRole': 'student',
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
        userId: _studentId,
        userName: _studentName,
        userRole: 'student',
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2),
      );
    }

    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 40),
            const SizedBox(height: 12),
            Text(
              'Failed to load achievements',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Text(
                _debugInfo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 10),
              ),
            ),
            TextButton.icon(
              onPressed: _fetchFeed,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.teal,
                size: 16,
              ),
              label: const Text(
                'Retry',
                style: TextStyle(color: Colors.teal, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: Colors.grey[300],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No achievements yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            // ── shows orgId + post count on screen ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Text(
                _debugInfo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orange, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.teal,
      onRefresh: _fetchFeed,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          if (i == _posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2),
              ),
            );
          }
          return _StudentAchievementCard(
            post: _posts[i],
            studentId: _studentId,
            onLike: () => _toggleLike(i),
            onComment: () => _openComments(i),
          );
        },
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _StudentAchievementCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String studentId;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const _StudentAchievementCard({
    required this.post,
    required this.studentId,
    required this.onLike,
    required this.onComment,
  });

  @override
  State<_StudentAchievementCard> createState() =>
      _StudentAchievementCardState();
}

class _StudentAchievementCardState extends State<_StudentAchievementCard> {
  int _imgIndex = 0;

  String _timeAgo(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      const m = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${m[d.month]}';
    } catch (_) {
      return '';
    }
  }

  Widget _brokenImage() => Container(
    height: 180,
    color: Colors.grey[100],
    alignment: Alignment.center,
    child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 32),
  );

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final images = (post['images'] as List? ?? []).cast<String>();
    final tagged = (post['taggedStudents'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final likes = (post['likes'] as List? ?? []);
    final isLiked = likes.any(
      (l) => l['userId']?.toString() == widget.studentId,
    );
    final likeCount = post['likeCount'] as int? ?? 0;
    final commentCount = post['commentCount'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ((post['teacherName']?.toString() ?? '').isNotEmpty
                            ? post['teacherName'].toString()
                            : (post['orgName']?.toString() ?? '').isNotEmpty
                            ? post['orgName'].toString()
                            : 'U')[0]
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (post['teacherName']?.toString() ?? '').isNotEmpty
                            ? post['teacherName'].toString()
                            : post['orgName']?.toString() ?? 'Admin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${(post['className']?.toString() ?? '').isNotEmpty ? post['className'].toString() : 'Admin'} � '
                        '${_timeAgo(post['createdAt']?.toString() ?? '')}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (images.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: images.length == 1
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: Image.network(
                        images[0],
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _brokenImage(),
                      ),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 180,
                        maxHeight: 360,
                      ),
                      child: PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _imgIndex = i),
                        itemBuilder: (_, i) => Image.network(
                          images[i],
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _brokenImage(),
                        ),
                      ),
                    ),
            ),
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: _imgIndex == i ? 14 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _imgIndex == i ? Colors.teal : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tagged.isNotEmpty) ...[
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: tagged
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '🏷 ${s['studentName']}',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  post['caption']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                _ActionBtn(
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '$likeCount',
                  active: isLiked,
                  activeColor: Colors.red[400]!,
                  activeBg: Colors.red.withOpacity(0.07),
                  activeBorder: Colors.red.withOpacity(0.2),
                  onTap: widget.onLike,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '$commentCount',
                  active: false,
                  activeColor: Colors.teal,
                  activeBg: Colors.transparent,
                  activeBorder: Colors.transparent,
                  onTap: widget.onComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color activeBg;
  final Color activeBorder;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.activeBg,
    required this.activeBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.grey[100],
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: active ? activeBorder : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? activeColor : AppColors.textSecondary,
              size: 17,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? activeColor : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
