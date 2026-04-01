import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AchievementCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isLiked;
  final bool isOwner;
  final VoidCallback onLike;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AchievementCard({
    super.key,
    required this.post,
    required this.isLiked,
    required this.isOwner,
    required this.onLike,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard> {
  int _imageIndex = 0;

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
    final post = widget.post;
    final images = (post['images'] as List? ?? []).cast<String>();
    final tagged = (post['taggedStudents'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final likeCount = post['likeCount'] as int? ?? 0;
    final commentCount = post['commentCount'] as int? ?? 0;
    final caption = post['caption']?.toString() ?? '';
    final teacherName = post['teacherName']?.toString() ?? '';
    final className = post['className']?.toString() ?? '';
    final createdAt = post['createdAt']?.toString() ?? '';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Author row ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      teacherName.isNotEmpty
                          ? teacherName[0].toUpperCase()
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
                          teacherName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$className  ·  ${_timeAgo(createdAt)}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isOwner)
                    _OwnerMenu(
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                    ),
                ],
              ),
            ),

            // ── Image carousel ──────────────────────
            if (images.isNotEmpty) ...[
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _imageIndex = i),
                  itemBuilder: (_, i) => Image.network(
                    images[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[100],
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                    ),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            color: Colors.grey[100],
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.teal,
                                strokeWidth: 2,
                              ),
                            ),
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

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tagged students ──────────────
                  if (tagged.isNotEmpty) ...[
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: tagged.map((s) {
                        return Container(
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
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── Caption ──────────────────────
                  if (caption.isNotEmpty)
                    Text(
                      caption,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),

                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF5F5F5)),
                  const SizedBox(height: 8),

                  // ── Like + Comment row ────────────
                  Row(
                    children: [
                      _ActionBtn(
                        icon: widget.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: '$likeCount',
                        color: widget.isLiked
                            ? Colors.red[400]!
                            : AppColors.textSecondary,
                        onTap: widget.onLike,
                      ),
                      const SizedBox(width: 16),
                      _ActionBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: '$commentCount',
                        color: AppColors.textSecondary,
                        onTap: widget.onTap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _OwnerMenu({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Colors.grey[500], size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              const Text('Edit', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: Colors.red[400],
              ),
              const SizedBox(width: 10),
              Text(
                'Delete',
                style: TextStyle(fontSize: 13, color: Colors.red[500]),
              ),
            ],
          ),
        ),
      ],
      onSelected: (val) {
        if (val == 'edit') onEdit?.call();
        if (val == 'delete') onDelete?.call();
      },
    );
  }
}
