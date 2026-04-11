import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════
// KPI CAROUSEL CARD — Clay Morphism
// ═══════════════════════════════════════════════════════

class KpiCarouselCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final List<Color> gradientColors;
  final Color clayColor;
  final Widget illustration;

  const KpiCarouselCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.gradientColors,
    required this.clayColor,
    required this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.55),
            blurRadius: 0,
            offset: const Offset(4, 5),
          ),
          BoxShadow(
            color: gradientColors[0].withOpacity(0.28),
            blurRadius: 14,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.18),
            blurRadius: 5,
            spreadRadius: -2,
            offset: const Offset(-3, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // blob top-right
            Positioned(
              top: -20,
              right: -14,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -12,
              right: 46,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            // top sheen
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            label.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _bar(32, 0.9),
                            const SizedBox(width: 3),
                            _bar(16, 0.45),
                            const SizedBox(width: 3),
                            _bar(8, 0.25),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // illustration circle
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: illustration,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(double w, double opacity) => Container(
    width: w,
    height: 3,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(3),
      color: Colors.white.withOpacity(opacity),
    ),
  );
}

// ═══════════════════════════════════════════════════════
// ILLUSTRATION — Classroom
// ═══════════════════════════════════════════════════════

class ClassroomIllustration extends StatelessWidget {
  const ClassroomIllustration({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ClassroomPainter(), size: const Size(78, 78));
}

class _ClassroomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final wt70 = Paint()..color = Colors.white.withOpacity(0.70);
    final wt30 = Paint()..color = Colors.white.withOpacity(0.30);
    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, h * 0.14, w * 0.80, h * 0.36),
        const Radius.circular(2),
      ),
      wt30,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, h * 0.14, w * 0.80, h * 0.36),
        const Radius.circular(2),
      ),
      stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(w * 0.20, h * (0.25 + i * 0.08)),
        Offset(w * (i == 1 ? 0.48 : 0.56), h * (0.25 + i * 0.08)),
        wt70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round,
      );
    }
    for (int i = 0; i < 3; i++) {
      final dx = w * (0.14 + i * 0.26);
      final dy = h * 0.62;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx, dy, w * 0.18, h * 0.08),
          const Radius.circular(2),
        ),
        wt30..style = PaintingStyle.fill,
      );
      canvas.drawLine(
        Offset(dx + w * 0.03, dy + h * 0.08),
        Offset(dx + w * 0.03, dy + h * 0.16),
        stroke..strokeWidth = 1.1,
      );
      canvas.drawLine(
        Offset(dx + w * 0.15, dy + h * 0.08),
        Offset(dx + w * 0.15, dy + h * 0.16),
        stroke..strokeWidth = 1.1,
      );
    }
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(w * (0.23 + i * 0.26), h * 0.57),
        w * 0.05,
        white,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════
// ILLUSTRATION — Students
// ═══════════════════════════════════════════════════════

class StudentsIllustration extends StatelessWidget {
  const StudentsIllustration({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _StudentsPainter(), size: const Size(78, 78));
}

class _StudentsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final white = Paint()..color = Colors.white;
    final wt70 = Paint()..color = Colors.white.withOpacity(0.70);
    final wt40 = Paint()..color = Colors.white.withOpacity(0.40);

    final offsets = [
      Offset(w * 0.22, h * 0.30),
      Offset(w * 0.50, h * 0.25),
      Offset(w * 0.78, h * 0.30),
    ];
    final paints = [wt40, white, wt70];
    final scales = [0.8, 1.0, 0.8];

    for (int i = 0; i < 3; i++) {
      final cx = offsets[i].dx, cy = offsets[i].dy;
      final s = scales[i];
      final p = paints[i];
      canvas.drawCircle(
        Offset(cx, cy),
        w * 0.08 * s,
        p..style = PaintingStyle.fill,
      );
      final body = Path()
        ..moveTo(cx - w * 0.07 * s, cy + h * 0.14)
        ..quadraticBezierTo(cx, cy + h * 0.10, cx + w * 0.07 * s, cy + h * 0.14)
        ..lineTo(cx + w * 0.09 * s, cy + h * 0.34)
        ..lineTo(cx - w * 0.09 * s, cy + h * 0.34)
        ..close();
      canvas.drawPath(body, p..style = PaintingStyle.fill);
      canvas.drawLine(
        Offset(cx - w * 0.07 * s, cy + h * 0.18),
        Offset(cx - w * 0.15 * s, cy + h * 0.27),
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * s
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(cx + w * 0.07 * s, cy + h * 0.18),
        Offset(cx + w * 0.15 * s, cy + h * 0.27),
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * s
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawLine(
      Offset(w * 0.08, h * 0.80),
      Offset(w * 0.92, h * 0.80),
      wt40
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════
// ILLUSTRATION — Teacher
// ═══════════════════════════════════════════════════════

class TeacherIllustration extends StatelessWidget {
  const TeacherIllustration({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _TeacherPainter(), size: const Size(78, 78));
}

class _TeacherPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final wt60 = Paint()
      ..color = Colors.white.withOpacity(0.60)
      ..style = PaintingStyle.fill;
    final wt30 = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(w * 0.50, h * 0.22), w * 0.12, white);
    final cap = Path()
      ..moveTo(w * 0.35, h * 0.14)
      ..lineTo(w * 0.65, h * 0.14)
      ..lineTo(w * 0.50, h * 0.06)
      ..close();
    canvas.drawPath(cap, wt60);
    canvas.drawLine(
      Offset(w * 0.50, h * 0.10),
      Offset(w * 0.63, h * 0.17),
      stroke..strokeWidth = 1.2,
    );
    final body = Path()
      ..moveTo(w * 0.36, h * 0.36)
      ..quadraticBezierTo(w * 0.50, h * 0.30, w * 0.64, h * 0.36)
      ..lineTo(w * 0.66, h * 0.60)
      ..lineTo(w * 0.34, h * 0.60)
      ..close();
    canvas.drawPath(body, white..style = PaintingStyle.fill);
    canvas.drawLine(
      Offset(w * 0.64, h * 0.40),
      Offset(w * 0.82, h * 0.32),
      stroke..strokeWidth = 2.0,
    );
    canvas.drawCircle(Offset(w * 0.82, h * 0.31), 2.5, white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.74, h * 0.36, w * 0.18, h * 0.22),
        const Radius.circular(2),
      ),
      wt30,
    );
    for (int i = 0; i < 2; i++) {
      canvas.drawLine(
        Offset(w * 0.77, h * (0.42 + i * 0.07)),
        Offset(w * 0.89, h * (0.42 + i * 0.07)),
        stroke..strokeWidth = 1.0,
      );
    }
    canvas.drawLine(
      Offset(w * 0.08, h * 0.80),
      Offset(w * 0.92, h * 0.80),
      wt30
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════
// ILLUSTRATION — Achievement
// ═══════════════════════════════════════════════════════

class AchievementIllustration extends StatelessWidget {
  const AchievementIllustration({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _AchievementPainter(), size: const Size(78, 78));
}

class _AchievementPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final wt70 = Paint()
      ..color = Colors.white.withOpacity(0.70)
      ..style = PaintingStyle.fill;
    final wt40 = Paint()
      ..color = Colors.white.withOpacity(0.40)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cup = Path()
      ..moveTo(w * 0.30, h * 0.22)
      ..lineTo(w * 0.70, h * 0.22)
      ..lineTo(w * 0.64, h * 0.52)
      ..quadraticBezierTo(w * 0.50, h * 0.60, w * 0.36, h * 0.52)
      ..close();
    canvas.drawPath(cup, white);
    canvas.drawArc(
      Rect.fromLTWH(w * 0.14, h * 0.26, w * 0.18, h * 0.20),
      math.pi * 0.5,
      math.pi,
      false,
      stroke..strokeWidth = 2.2,
    );
    canvas.drawArc(
      Rect.fromLTWH(w * 0.68, h * 0.26, w * 0.18, h * 0.20),
      math.pi * 1.5,
      math.pi,
      false,
      stroke..strokeWidth = 2.2,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.44, h * 0.58, w * 0.12, h * 0.12),
      wt70,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.70, w * 0.40, h * 0.08),
        const Radius.circular(3),
      ),
      wt40,
    );
    _drawStar(
      canvas,
      Offset(w * 0.50, h * 0.38),
      w * 0.10,
      Paint()
        ..color = Colors.white.withOpacity(0.50)
        ..style = PaintingStyle.fill,
    );
    final sp = Paint()
      ..color = Colors.white.withOpacity(0.80)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _drawSparkle(canvas, Offset(w * 0.15, h * 0.16), w * 0.035, sp);
    _drawSparkle(canvas, Offset(w * 0.82, h * 0.20), w * 0.028, sp);
    _drawSparkle(canvas, Offset(w * 0.78, h * 0.62), w * 0.022, sp);
  }

  void _drawStar(Canvas c, Offset center, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final oa = math.pi / 2 + i * (2 * math.pi / 5) * -1;
      final ia = oa + math.pi / 5;
      final o = Offset(
        center.dx + r * math.cos(oa),
        center.dy - r * math.sin(oa),
      );
      final inn = Offset(
        center.dx + r * 0.4 * math.cos(ia),
        center.dy - r * 0.4 * math.sin(ia),
      );
      if (i == 0)
        path.moveTo(o.dx, o.dy);
      else
        path.lineTo(o.dx, o.dy);
      path.lineTo(inn.dx, inn.dy);
    }
    path.close();
    c.drawPath(path, p);
  }

  void _drawSparkle(Canvas c, Offset center, double r, Paint p) {
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      c.drawLine(
        Offset(
          center.dx + math.cos(a) * r * 0.3,
          center.dy + math.sin(a) * r * 0.3,
        ),
        Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
