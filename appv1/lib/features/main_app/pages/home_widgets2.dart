import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════
// QuickBtn — clean professional, centered, small vector
// ═══════════════════════════════════════════════════════

class QuickBtn extends StatefulWidget {
  final dynamic item;
  const QuickBtn({super.key, required this.item});
  @override
  State<QuickBtn> createState() => _QuickBtnState();
}

class _QuickBtnState extends State<QuickBtn> {
  bool _pressed = false;

  static final Map<String, CustomPainter> _painters = {
    'Classrooms': _QAClassroomPainter(),
    'Leave Request': _QALeavePainter(),
    'Notice': _QANoticePainter(),
    'School': _QASchoolPainter(),
  };

  @override
  Widget build(BuildContext context) {
    final String label = widget.item.label as String;
    final VoidCallback? onTap = widget.item.onTap as VoidCallback?;
    final painter = _painters[label] ?? _QAClassroomPainter();

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        transform: _pressed
            ? (Matrix4.identity()..scale(0.96))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: const Color(0xFF009688).withOpacity(0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF009688).withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF009688).withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.center,
              child: CustomPaint(painter: painter, size: const Size(20, 20)),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 9.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── QA Vector painters ──────────────────────────────────

class _QAClassroomPainter extends CustomPainter {
  const _QAClassroomPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = const Color(0xFF009688)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pf = Paint()
      ..color = const Color(0xFF009688).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.08, w * 0.90, h * 0.42),
        const Radius.circular(1.5),
      ),
      pf,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.08, w * 0.90, h * 0.42),
        const Radius.circular(1.5),
      ),
      p,
    );
    canvas.drawLine(
      Offset(w * 0.15, h * 0.22),
      Offset(w * 0.65, h * 0.22),
      p..strokeWidth = 1.1,
    );
    canvas.drawLine(
      Offset(w * 0.15, h * 0.30),
      Offset(w * 0.55, h * 0.30),
      p..strokeWidth = 1.1,
    );
    canvas.drawLine(
      Offset(w * 0.15, h * 0.38),
      Offset(w * 0.60, h * 0.38),
      p..strokeWidth = 1.1,
    );

    for (int i = 0; i < 2; i++) {
      final dx = w * (0.08 + i * 0.50);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx, h * 0.60, w * 0.35, h * 0.10),
          const Radius.circular(1),
        ),
        pf..color = const Color(0xFF009688).withOpacity(0.10),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx, h * 0.60, w * 0.35, h * 0.10),
          const Radius.circular(1),
        ),
        p..strokeWidth = 1.3,
      );
      canvas.drawLine(
        Offset(dx + w * 0.05, h * 0.70),
        Offset(dx + w * 0.05, h * 0.88),
        p..strokeWidth = 1.1,
      );
      canvas.drawLine(
        Offset(dx + w * 0.30, h * 0.70),
        Offset(dx + w * 0.30, h * 0.88),
        p..strokeWidth = 1.1,
      );
      canvas.drawCircle(
        Offset(dx + w * 0.175, h * 0.54),
        w * 0.07,
        Paint()
          ..color = const Color(0xFF009688).withOpacity(0.55)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _QALeavePainter extends CustomPainter {
  const _QALeavePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = const Color(0xFF009688)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pf = Paint()
      ..color = const Color(0xFF009688).withOpacity(0.10)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.18, w * 0.88, h * 0.74),
        const Radius.circular(1.5),
      ),
      pf,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.18, w * 0.88, h * 0.74),
        const Radius.circular(1.5),
      ),
      p,
    );
    canvas.drawLine(
      Offset(w * 0.06, h * 0.36),
      Offset(w * 0.94, h * 0.36),
      p..strokeWidth = 1.1,
    );
    canvas.drawLine(
      Offset(w * 0.30, h * 0.10),
      Offset(w * 0.30, h * 0.26),
      p..strokeWidth = 1.8,
    );
    canvas.drawLine(
      Offset(w * 0.70, h * 0.10),
      Offset(w * 0.70, h * 0.26),
      p..strokeWidth = 1.8,
    );

    final cx = w * 0.50, cy = h * 0.60;
    final xp = Paint()
      ..color = const Color(0xFF009688)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - w * 0.16, cy - h * 0.12),
      Offset(cx + w * 0.16, cy + h * 0.12),
      xp,
    );
    canvas.drawLine(
      Offset(cx + w * 0.16, cy - h * 0.12),
      Offset(cx - w * 0.16, cy + h * 0.12),
      xp,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _QANoticePainter extends CustomPainter {
  const _QANoticePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = const Color(0xFF009688)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pf = Paint()
      ..color = const Color(0xFF009688).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final body = Path()
      ..moveTo(w * 0.14, h * 0.36)
      ..lineTo(w * 0.14, h * 0.64)
      ..lineTo(w * 0.36, h * 0.64)
      ..lineTo(w * 0.72, h * 0.80)
      ..lineTo(w * 0.72, h * 0.20)
      ..lineTo(w * 0.36, h * 0.36)
      ..close();
    canvas.drawPath(body, pf);
    canvas.drawPath(body, p);

    for (int i = 1; i <= 2; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(w * 0.78, h * 0.50),
          width: w * 0.14 * i,
          height: h * 0.22 * i,
        ),
        -math.pi * 0.38,
        math.pi * 0.76,
        false,
        p..strokeWidth = 1.3,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _QASchoolPainter extends CustomPainter {
  const _QASchoolPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = const Color(0xFF009688)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pf = Paint()
      ..color = const Color(0xFF009688).withOpacity(0.10)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, h * 0.40, w * 0.80, h * 0.52),
        const Radius.circular(1.5),
      ),
      pf,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, h * 0.40, w * 0.80, h * 0.52),
        const Radius.circular(1.5),
      ),
      p,
    );
    final roof = Path()
      ..moveTo(w * 0.06, h * 0.42)
      ..lineTo(w * 0.50, h * 0.14)
      ..lineTo(w * 0.94, h * 0.42)
      ..close();
    canvas.drawPath(
      roof,
      pf..color = const Color(0xFF009688).withOpacity(0.14),
    );
    canvas.drawPath(roof, p);

    for (int i = 0; i < 2; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * (0.18 + i * 0.40), h * 0.46, w * 0.22, h * 0.18),
          const Radius.circular(1),
        ),
        Paint()
          ..color = const Color(0xFF009688).withOpacity(0.25)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * (0.18 + i * 0.40), h * 0.46, w * 0.22, h * 0.18),
          const Radius.circular(1),
        ),
        p..strokeWidth = 1.2,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.39, h * 0.65, w * 0.22, h * 0.27),
        const Radius.circular(1),
      ),
      Paint()
        ..color = const Color(0xFF009688).withOpacity(0.20)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.39, h * 0.65, w * 0.22, h * 0.27),
        const Radius.circular(1),
      ),
      p..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════
// AchievementHCard
// ═══════════════════════════════════════════════════════

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
    final initial = (post['teacherName']?.toString() ?? 'T')[0].toUpperCase();

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: const Border(
          left: BorderSide(color: Color(0xFF009688), width: 3),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        initial,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
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

// ═══════════════════════════════════════════════════════
// HomeShimmer
// ═══════════════════════════════════════════════════════

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
    _anim = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
            colors: const [
              Color(0xFFE0F2F1),
              Color(0xFFB2DFDB),
              Color(0xFFE0F2F1),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(w: 80, h: 10),
                const SizedBox(height: 14),
                _box(h: 158),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: _box(w: i == 0 ? 20 : 6, h: 6),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
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
                          height: 80,
                          margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                          child: _box(h: 80),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 26),
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
                        height: 232,
                        margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                        child: _box(h: 232, w: 200),
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
