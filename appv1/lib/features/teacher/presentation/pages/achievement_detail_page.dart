import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import 'achievement_comments_sheet.dart';

class AchievementDetailPage extends StatefulWidget {
  final String achievementId;
  final String userId;
  final String userName;
  final String userRole;

  const AchievementDetailPage({
    super.key,
    required this.achievementId,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  State<AchievementDetailPage> createState() => _AchievementDetailPageState();
}

class _AchievementDetailPageState extends State<AchievementDetailPage> {
  Map<String, dynamic>? _post;
  bool _loading = true;
  bool _changed = false;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/achievement/${widget.achievementId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        setState(() {
          _post = body['achievement'] as Map<String, dynamic>;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    final likes = (_post!['likes'] as List? ?? []);
    final isLiked = likes.any((l) => l['userId']?.toString() == widget.userId);
    setState(() {
      if (isLiked) {
        _post!['likes'] = likes
            .where((l) => l['userId']?.toString() != widget.userId)
            .toList();
        _post!['likeCount'] = (_post!['likeCount'] as int) - 1;
      } else {
        (_post!['likes'] as List).add({
          'userId': widget.userId,
          'userName': widget.userName,
          'userRole': widget.userRole,
        });
        _post!['likeCount'] = (_post!['likeCount'] as int) + 1;
      }
      _changed = true;
    });
    try {
      await http.post(
        Uri.parse(
          'https://appv1backend.onrender.com/api/achievement/${widget.achievementId}/like',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'userName': widget.userName,
          'userRole': widget.userRole,
        }),
      );
    } catch (_) {}
  }

  void _onCommentsChanged(
    List<Map<String, dynamic>> updatedComments,
    int updatedCount,
  ) {
    setState(() {
      _post!['comments'] = updatedComments;
      _post!['commentCount'] = updatedCount;
      _changed = true;
    });
  }

  void _openComments() {
    if (_post == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AchievementCommentsSheet(
        achievementId: widget.achievementId,
        userId: widget.userId,
        userName: widget.userName,
        userRole: widget.userRole,
        initialComments: ((_post!['comments'] as List?) ?? [])
            .cast<Map<String, dynamic>>(),
        onChanged: _onCommentsChanged,
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      // ✅ FIX 1: Never call Navigator.pop inside onPopInvokedWithResult
      // The pop already happened — calling pop again causes _debugLocked crash
      onPopInvokedWithResult: (didPop, result) {
        // Nothing needed here — back button handles passing _changed
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.teal),
                    )
                  : _post == null
                  ? Center(
                      child: Text(
                        'Post not found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : _buildBody(),
            ),
          ],
        ),
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
              GestureDetector(
                // ✅ FIX 1: Use maybePop — safe, won't crash if navigator is locked
                onTap: () =>
                    Navigator.of(context).maybePop(_changed ? true : null),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievement',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Details & comments',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final post = _post!;
    final images = (post['images'] as List? ?? []).cast<String>();
    final tagged = (post['taggedStudents'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final likes = (post['likes'] as List? ?? []);
    final isLiked = likes.any((l) => l['userId']?.toString() == widget.userId);
    final likeCount = post['likeCount'] as int? ?? 0;
    final commentCount = post['commentCount'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  (post['teacherName']?.toString() ?? 'T')[0].toUpperCase(),
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
                      post['teacherName']?.toString() ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${post['className'] ?? ''} · ${_timeAgo(post['createdAt']?.toString() ?? '')}',
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
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 240,
                child: PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _imageIndex = i),
                  itemBuilder: (_, i) => Image.network(
                    images[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
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
                      width: _imageIndex == i ? 16 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _imageIndex == i
                            ? Colors.teal
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          if (tagged.isNotEmpty) ...[
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: tagged
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
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
            const SizedBox(height: 10),
          ],
          Text(
            post['caption']?.toString() ?? '',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isLiked
                        ? Colors.red.withOpacity(0.08)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isLiked
                          ? Colors.red.withOpacity(0.25)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isLiked
                            ? Colors.red[400]
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$likeCount',
                        style: TextStyle(
                          color: isLiked
                              ? Colors.red[400]
                              : AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _openComments,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$commentCount comments',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
