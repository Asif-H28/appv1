// achievement_feed_card.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AchievementFeedCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String teacherId;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AchievementFeedCard({
    super.key,
    required this.post,
    required this.teacherId,
    required this.onLike,
    required this.onComment,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<AchievementFeedCard> createState() => _AchievementFeedCardState();
}

class _AchievementFeedCardState extends State<AchievementFeedCard> {
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
    final likeCount = post['likeCount'] as int? ?? 0;
    final commentCount = post['commentCount'] as int? ?? 0;

    // ✅ FIX 1 — clamp _imgIndex to prevent RangeError after list rebuild
    if (_imgIndex >= images.length) _imgIndex = 0;

    // ✅ FIX 2 — isOwner driven by callbacks, not teacherId comparison
    // This safely handles admin posts where teacherId is null
    final isOwner = widget.onEdit != null || widget.onDelete != null;

    // Like check — safe for admin (userId may differ from teacherId)
    final isLiked = likes.any(
      (l) => l['userId']?.toString() == widget.teacherId,
    );

    // ── Author display: admin posts show "Admin" with org icon ──
    final authorName = post['teacherName']?.toString() ?? '';
    final subLine = post['className']?.toString() ?? '';
    final timeStr = _timeAgo(post['createdAt']?.toString() ?? '');
    final isAdminPost = authorName.isEmpty && subLine.isEmpty;

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
          // ── Author row ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                // Avatar — shows 'A' for admin post, initial otherwise
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isAdminPost
                        ? 'A'
                        : authorName.isNotEmpty
                        ? authorName[0].toUpperCase()
                        : 'T',
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
                        isAdminPost ? 'Admin' : authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isAdminPost ? timeStr : '$subLine · $timeStr',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Edit / Delete buttons (shown when isOwner) ──
                if (isOwner)
                  Row(
                    children: [
                      if (widget.onEdit != null)
                        GestureDetector(
                          onTap: widget.onEdit,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.teal,
                              size: 15,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      if (widget.onDelete != null)
                        GestureDetector(
                          onTap: widget.onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red[400],
                              size: 15,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Images ──────────────────────────────────
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
            // Dot indicators
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

          // ── Tagged students + Caption ────────────────
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

          // ── Like + Comment ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                _ActionChip(
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
                _ActionChip(
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

// ── Action chip ───────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color activeBg;
  final Color activeBorder;
  final VoidCallback onTap;

  const _ActionChip({
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
