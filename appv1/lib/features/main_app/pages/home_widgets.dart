import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KpiCard — teal accent with left-border highlight
// ─────────────────────────────────────────────────────────────────────────────

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color bg;
  const _KpiData(this.label, this.value, this.icon, this.accent, this.bg);
}

class KpiCard extends StatelessWidget {
  // Accept the private data class via dynamic so home_page.dart can pass it.
  final dynamic data;

  const KpiCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String label = data.label as String;
    final String value = data.value as String;
    final IconData icon = data.icon as IconData;
    final Color accent = data.accent as Color;
    final Color bg = data.bg as Color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border(
          left: BorderSide(color: accent, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(icon, color: accent, size: 17),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: accent,
                    size: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QuickBtn — teal icon tile with top accent line
// ─────────────────────────────────────────────────────────────────────────────

class QuickBtn extends StatefulWidget {
  final dynamic item;
  const QuickBtn({super.key, required this.item});

  @override
  State<QuickBtn> createState() => _QuickBtnState();
}

class _QuickBtnState extends State<QuickBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final IconData icon = widget.item.icon as IconData;
    final String label = widget.item.label as String;
    final VoidCallback? onTap = widget.item.onTap as VoidCallback?;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        transform: _pressed
            ? (Matrix4.identity()..scale(0.96))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border(
            top: const BorderSide(color: Color(0xFF009688), width: 2.5),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF009688).withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF009688).withOpacity(0.10),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(icon, color: const Color(0xFF009688), size: 20),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AchievementHCard — polished with teal left accent + engagement row
// ─────────────────────────────────────────────────────────────────────────────

class AchievementHCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const AchievementHCard({super.key, required this.post});

  String _ago(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      const mo = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${d.day} ${mo[d.month]}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = (post['images'] as List? ?? []).cast<String>();
    final likes = post['likeCount'] as int? ?? 0;
    final comments = post['commentCount'] as int? ?? 0;
    final caption = post['caption']?.toString() ?? '';
    final teacherInitial =
        (post['teacherName']?.toString() ?? 'T')[0].toUpperCase();

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border(
          left: const BorderSide(color: Color(0xFF009688), width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF009688).withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
            child: SizedBox(
              height: 105,
              width: double.infinity,
              child: images.isNotEmpty
                  ? Image.network(
                      images[0],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
          ),
          // ── Body ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Teacher + time
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF009688), Color(0xFF26A69A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        teacherInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        post['teacherName']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2D3748),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _ago(post['createdAt']?.toString() ?? ''),
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Class badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF009688).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: const Color(0xFF009688).withOpacity(0.20),
                    ),
                  ),
                  child: Text(
                    post['className']?.toString() ?? '',
                    style: const TextStyle(
                      color: Color(0xFF009688),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                // Caption
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF2D3748),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 8),
                // Engagement
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7F6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: Color(0xFF009688),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likes',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF009688),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.chat_bubble_rounded,
                        size: 11,
                        color: Color(0xFF718096),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$comments',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
    color: const Color(0xFF009688).withOpacity(0.07),
    alignment: Alignment.center,
    child: Icon(
      Icons.emoji_events_rounded,
      color: const Color(0xFF009688).withOpacity(0.28),
      size: 34,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HomeShimmer — teal shimmer loader
// ─────────────────────────────────────────────────────────────────────────────

class HomeShimmer extends StatefulWidget {
  const HomeShimmer({super.key});
  @override
  State<HomeShimmer> createState() => _HomeShimmerState();
}

class _HomeShimmerState extends State<HomeShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box({double? w, double h = 16, EdgeInsets? margin}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: w,
        height: h,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: [
              const Color(0xFFE0F2F1),
              const Color(0xFFB2DFDB),
              const Color(0xFFE0F2F1),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(h: 160),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(w: 80, h: 10),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.65,
                  children: List.generate(4, (_) => _box(h: double.infinity)),
                ),
                const SizedBox(height: 22),
                _box(w: 100, h: 10),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final w = (constraints.maxWidth - 24) / 4;
                    return Row(
                      children: List.generate(
                        4,
                        (i) => Container(
                          width: w,
                          height: 76,
                          margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                          child: _box(h: 76),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
                _box(w: 130, h: 10),
                const SizedBox(height: 12),
                _box(h: 90),
                const SizedBox(height: 22),
                _box(w: 150, h: 10),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: List.generate(
                      3,
                      (i) => Container(
                        width: 200,
                        height: 220,
                        margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                        child: _box(h: 220, w: 200),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
