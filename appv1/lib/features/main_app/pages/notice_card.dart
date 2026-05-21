import 'package:flutter/material.dart';

class NoticeCard extends StatelessWidget {
  final Map<String, dynamic> notice;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoticeCard({
    super.key,
    required this.notice,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  static const _teal = Color(0xFF00796B);
  static const _border = Color(0xFFE9ECEF);

  // ── Helpers ───────────────────────────────────────────

  String _audienceChipLabel(String? a) {
    if (a == 'teachers_only') return 'TEACHERS';
    if (a == 'teachers_and_students') return 'TEACHERS & STUDENTS';
    return (a ?? '').toUpperCase();
  }

  // Card gets red left border only for teachers_only
  bool _isTeachersOnly(String? a) => a == 'teachers_only';

  bool _isExpired(String? iso) {
    if (iso == null) return false;
    try {
      return DateTime.parse(iso).toLocal().isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      const mo = [
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
      return '${mo[d.month]} ${d.day}, ${d.year}';
    } catch (_) {
      return '';
    }
  }

  // Action label based on attachments / audience
  String _actionLabel(Map<String, dynamic> notice) {
    final atts = (notice['attachments'] as List? ?? []);
    if (atts.isNotEmpty) {
      final type = (atts.first as Map)['resourceType']?.toString() ?? '';
      if (type == 'raw') return 'Download Report';
      return 'View Poster';
    }
    final aud = notice['audience']?.toString() ?? '';
    if (aud == 'teachers_only') return 'Confirm Attendance';
    return 'View Full Details';
  }

  // Bottom icons based on attachments
  List<IconData> _bottomIcons(Map<String, dynamic> notice) {
    final atts = (notice['attachments'] as List? ?? []);
    if (atts.isEmpty) return [Icons.article_outlined];
    return atts.take(2).map<IconData>((a) {
      final type = (a as Map)['resourceType']?.toString() ?? '';
      return type == 'raw' ? Icons.picture_as_pdf_rounded : Icons.image_rounded;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = notice['title']?.toString() ?? '';
    final description = notice['description']?.toString() ?? '';
    final audience = notice['audience']?.toString();
    final createdAt = notice['createdAt']?.toString();
    final expired = _isExpired(notice['expiresAt']?.toString());
    final teachOnly = _isTeachersOnly(audience);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(
              color: teachOnly ? const Color(0xFFE53E3E) : Colors.transparent,
              width: 3,
            ),
            bottom: const BorderSide(color: Color(0xFFE9ECEF), width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: chip + date + menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: _audienceChip(audience, expired),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _moreMenu(),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: _teal,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              // Bottom row: icons + action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _bottomIcons(notice).map(
                      (icon) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          icon,
                          size: 16,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ).toList(),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: GestureDetector(
                      onTap: onTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              _actionLabel(notice),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _teal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: _teal,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _audienceChip(String? audience, bool expired) {
    Color chipColor;
    if (expired) {
      chipColor = const Color(0xFFE53E3E);
    } else if (audience == 'teachers_only') {
      chipColor = const Color(0xFF2D7DD2);
    } else {
      chipColor = _teal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: chipColor.withOpacity(0.35)),
      ),
      child: Text(
        expired ? 'EXPIRED' : _audienceChipLabel(audience),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: chipColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _moreMenu() => PopupMenuButton<String>(
    onSelected: (v) {
      if (v == 'edit') onEdit();
      if (v == 'delete') onDelete();
    },
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    icon: const Icon(
      Icons.more_vert_rounded,
      size: 18,
      color: Color(0xFFD1D5DB),
    ),
    itemBuilder: (_) => [
      const PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit_rounded, size: 15, color: Color(0xFF00796B)),
            SizedBox(width: 8),
            Text('Edit', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete_rounded, size: 15, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(fontSize: 13, color: Colors.red)),
          ],
        ),
      ),
    ],
  );
}

// ── Shimmer ────────────────────────────────────────────────

class NoticeShimmer extends StatefulWidget {
  const NoticeShimmer({super.key});
  @override
  State<NoticeShimmer> createState() => _NoticeShimmerState();
}

class _NoticeShimmerState extends State<NoticeShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _a = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _box({double? w, double h = 13, EdgeInsets? margin}) =>
      AnimatedBuilder(
        animation: _a,
        builder: (_, __) => Container(
          width: w,
          height: h,
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: Alignment(_a.value - 1, 0),
              end: Alignment(_a.value + 1, 0),
              colors: const [
                Color(0xFFF3F4F6),
                Color(0xFFE5E7EB),
                Color(0xFFF3F4F6),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _box(w: 90, h: 22),
                const Spacer(),
                _box(w: 70, h: 12),
              ],
            ),
            const SizedBox(height: 10),
            _box(w: double.infinity, h: 16),
            const SizedBox(height: 6),
            _box(w: 200, h: 16),
            const SizedBox(height: 10),
            _box(w: double.infinity, h: 12),
            const SizedBox(height: 5),
            _box(w: 240, h: 12),
            const SizedBox(height: 5),
            _box(w: 180, h: 12),
            const SizedBox(height: 14),
            Row(
              children: [
                _box(w: 16, h: 16),
                const SizedBox(width: 6),
                _box(w: 16, h: 16),
                const Spacer(),
                _box(w: 100, h: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
