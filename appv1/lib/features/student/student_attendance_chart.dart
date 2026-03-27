import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';

const Color _accent = Colors.teal;

class StudentAttendanceChart extends StatefulWidget {
  final int totalPresent;
  final int totalAbsent;
  final double percentage;
  final Color statusColor;
  final List<Map<String, dynamic>> records;

  const StudentAttendanceChart({
    required this.totalPresent,
    required this.totalAbsent,
    required this.percentage,
    required this.statusColor,
    required this.records,
  });

  @override
  _StudentAttendanceChartState createState() => _StudentAttendanceChartState();
}

class _StudentAttendanceChartState extends State<StudentAttendanceChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _anim;

  String _selectedMonth = '';
  String _selectedView = 'Week'; // 'Week' | 'Month'

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    // default to latest month
    final months = _allMonths;
    if (months.isNotEmpty) _selectedMonth = months.first;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── All unique months from records (newest first) ─────

  List<String> get _allMonths {
    final seen = <String>{};
    final list = <String>[];
    for (final r in widget.records) {
      final dt = DateTime.tryParse(r['date']?.toString() ?? '');
      if (dt == null) continue;
      final key = _monthKey(dt);
      if (seen.add(key)) list.add(key);
    }
    return list; // already sorted newest-first from parent sort
  }

  String _monthKey(DateTime dt) {
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
    return '${m[dt.month]} ${dt.year}';
  }

  // ── Build data points ─────────────────────────────────
  //
  // VIEW = Week  → X-axis = Week 1..5 within selected month
  // VIEW = Month → X-axis = all available months (last 6)

  List<_LinePoint> get _presentPoints => _buildPoints(true);
  List<_LinePoint> get _absentPoints => _buildPoints(false);

  List<_LinePoint> _buildPoints(bool forPresent) {
    if (_selectedView == 'Week') {
      return _buildWeekPoints(forPresent);
    } else {
      return _buildMonthPoints(forPresent);
    }
  }

  List<_LinePoint> _buildWeekPoints(bool forPresent) {
    // filter records to selected month
    final filtered = widget.records.where((r) {
      final dt = DateTime.tryParse(r['date']?.toString() ?? '');
      if (dt == null) return false;
      return _monthKey(dt) == _selectedMonth;
    }).toList();

    // group by week number (1-5)
    final map = <int, int>{};
    for (final r in filtered) {
      final dt = DateTime.tryParse(r['date']?.toString() ?? '');
      if (dt == null) continue;
      final wk = ((dt.day - 1) ~/ 7) + 1;
      final att = r['attendance']?.toString().toLowerCase() ?? '';
      final isP = att == 'present';
      if (forPresent ? isP : !isP) {
        map[wk] = (map[wk] ?? 0) + 1;
      }
    }

    // fill weeks 1-5
    final points = <_LinePoint>[];
    for (int w = 1; w <= 5; w++) {
      points.add(_LinePoint(label: 'W$w', value: (map[w] ?? 0).toDouble()));
    }
    return points;
  }

  List<_LinePoint> _buildMonthPoints(bool forPresent) {
    final months = _allMonths.reversed.toList(); // oldest → newest
    final last6 = months.length > 6
        ? months.sublist(months.length - 6)
        : months;

    return last6.map((mk) {
      final filtered = widget.records.where((r) {
        final dt = DateTime.tryParse(r['date']?.toString() ?? '');
        if (dt == null) return false;
        return _monthKey(dt) == mk;
      }).toList();

      int count = 0;
      for (final r in filtered) {
        final att = r['attendance']?.toString().toLowerCase() ?? '';
        final isP = att == 'present';
        if (forPresent ? isP : !isP) count++;
      }
      // short label e.g. "Jan"
      return _LinePoint(label: mk.split(' ').first, value: count.toDouble());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Pie chart card ──
        _buildPieChartCard(),
        SizedBox(height: 12),

        // ── Line graph card ──
        _buildLineChartCard(),
      ],
    );
  }

  // ── Pie chart ─────────────────────────────────────────

  Widget _buildPieChartCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Present vs Absent', Icons.pie_chart_rounded),
          SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => CustomPaint(
                    painter: _PieChartPainter(
                      presentRatio: widget.totalPresent + widget.totalAbsent > 0
                          ? widget.totalPresent /
                                (widget.totalPresent + widget.totalAbsent)
                          : 0,
                      progress: _anim.value,
                      presentColor: Colors.green[600]!,
                      absentColor: Colors.red[600]!,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pieLegendRow(
                      color: Colors.green[600]!,
                      label: 'Present',
                      count: widget.totalPresent,
                      total: widget.totalPresent + widget.totalAbsent,
                    ),
                    SizedBox(height: 14),
                    _pieLegendRow(
                      color: Colors.red[600]!,
                      label: 'Absent',
                      count: widget.totalAbsent,
                      total: widget.totalPresent + widget.totalAbsent,
                    ),
                    SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: widget.statusColor.withOpacity(0.25),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.percentage.toStringAsFixed(1)}% Overall',
                          style: TextStyle(
                            color: widget.statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Line chart card ───────────────────────────────────

  Widget _buildLineChartCard() {
    final months = _allMonths;
    final presentPoints = _presentPoints;
    final absentPoints = _absentPoints;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          _sectionHeader('Attendance Trend', Icons.show_chart_rounded),
          SizedBox(height: 12),

          // ── View toggle: Week / Month ──
          Row(
            children: [
              _toggleBtn('Week', _selectedView == 'Week'),
              SizedBox(width: 8),
            ],
          ),
          SizedBox(height: 12),

          // ── Month selector (only in Week view) ──
          if (_selectedView == 'Week' && months.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Month',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: months.length,
                    separatorBuilder: (_, __) => SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final m = months[i];
                      final isSelected = _selectedMonth == m;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMonth = m;
                            _animController.forward(from: 0);
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? _accent : Colors.grey[100],
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: isSelected ? _accent : Colors.grey[200]!,
                            ),
                          ),
                          child: Text(
                            m,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 14),
              ],
            ),

          // ── Line chart ──
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              height: 200,
              child: CustomPaint(
                size: Size(double.infinity, 200),
                painter: _LineChartPainter(
                  presentPoints: presentPoints,
                  absentPoints: absentPoints,
                  progress: _anim.value,
                  presentColor: Colors.teal,
                  absentColor: Colors.red[600]!,
                  gridColor: Colors.grey[200]!,
                  labelColor: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          SizedBox(height: 14),

          // ── Legend ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _lineLegend(Colors.teal, 'Present', isDashed: false),
              SizedBox(width: 20),
              _lineLegend(Colors.red[600]!, 'Absent', isDashed: true),
            ],
          ),

          SizedBox(height: 10),

          // ── X-axis label ──
          Center(
            child: Text(
              _selectedView == 'Week' ? 'Week' : 'Month',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────

  Widget _toggleBtn(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = label;
          _animController.forward(from: 0);
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _accent : Colors.grey[100],
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: isSelected ? _accent : Colors.grey[200]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _lineLegend(Color color, String label, {required bool isDashed}) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 16,
          child: CustomPaint(
            painter: _LegendLinePainter(color: color, isDashed: isDashed),
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _pieLegendRow({
    required Color color,
    required String label,
    required int count,
    required int total,
  }) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
        ),
        Text(
          '$count days',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12.5,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(width: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            '$pct%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Row(
    children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      SizedBox(width: 8),
      Icon(icon, size: 15, color: _accent),
      SizedBox(width: 5),
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
      ),
    ],
  );

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(3),
    border: Border.all(color: Colors.grey[200]!),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: Offset(0, 3),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────

class _LinePoint {
  final String label;
  final double value;
  const _LinePoint({required this.label, required this.value});
}

// ─────────────────────────────────────────────────────────
// LINE CHART PAINTER — replicates your reference image
// ─────────────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<_LinePoint> presentPoints;
  final List<_LinePoint> absentPoints;
  final double progress;
  final Color presentColor;
  final Color absentColor;
  final Color gridColor;
  final Color labelColor;

  _LineChartPainter({
    required this.presentPoints,
    required this.absentPoints,
    required this.progress,
    required this.presentColor,
    required this.absentColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (presentPoints.isEmpty) return;

    const double padL = 32;
    const double padR = 16;
    const double padT = 16;
    const double padB = 36;

    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;

    // ── Max value for Y-axis ──
    final allValues = [
      ...presentPoints.map((p) => p.value),
      ...absentPoints.map((p) => p.value),
    ];
    final maxVal = allValues.isEmpty ? 1.0 : allValues.reduce(math.max);
    final yMax = maxVal == 0 ? 5.0 : (maxVal * 1.2).ceilToDouble();

    final n = presentPoints.length;

    // ── Grid lines ──
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = padT + chartH - (chartH * i / gridLines);
      canvas.drawLine(Offset(padL, y), Offset(padL + chartW, y), gridPaint);

      // Y label
      final yVal = (yMax * i / gridLines).toStringAsFixed(0);
      _drawText(canvas, yVal, Offset(0, y - 6), labelColor, 9);
    }

    // ── X labels ──
    for (int i = 0; i < n; i++) {
      final x = padL + (chartW * i / (n - 1).clamp(1, 999));
      _drawText(
        canvas,
        presentPoints[i].label,
        Offset(x - 12, size.height - padB + 8),
        labelColor,
        9,
      );
    }

    // ── Axes ──
    final axisPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1;
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + chartH), axisPaint);
    canvas.drawLine(
      Offset(padL, padT + chartH),
      Offset(padL + chartW, padT + chartH),
      axisPaint,
    );

    // ── Draw both lines with animation ──
    _drawLine(
      canvas: canvas,
      points: presentPoints,
      color: presentColor,
      isDashed: false,
      markerShape: _MarkerShape.diamond,
      padL: padL,
      padT: padT,
      chartW: chartW,
      chartH: chartH,
      yMax: yMax,
      progress: progress,
    );

    _drawLine(
      canvas: canvas,
      points: absentPoints,
      color: absentColor,
      isDashed: true,
      markerShape: _MarkerShape.square,
      padL: padL,
      padT: padT,
      chartW: chartW,
      chartH: chartH,
      yMax: yMax,
      progress: progress,
    );
  }

  void _drawLine({
    required Canvas canvas,
    required List<_LinePoint> points,
    required Color color,
    required bool isDashed,
    required _MarkerShape markerShape,
    required double padL,
    required double padT,
    required double chartW,
    required double chartH,
    required double yMax,
    required double progress,
  }) {
    final n = points.length;
    if (n == 0) return;

    // compute pixel positions
    final List<Offset> offsets = [];
    for (int i = 0; i < n; i++) {
      final x = padL + (chartW * i / (n - 1).clamp(1, 999));
      final y =
          padT + chartH - (chartH * (points[i].value / yMax).clamp(0.0, 1.0));
      offsets.add(Offset(x, y));
    }

    // animated clip
    final totalPoints = (progress * (n - 1)).clamp(0.0, (n - 1).toDouble());
    final fullIdx = totalPoints.floor();
    final frac = totalPoints - fullIdx;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // draw segment by segment with dashed support
    for (int i = 0; i < fullIdx && i < n - 1; i++) {
      _drawSegment(canvas, offsets[i], offsets[i + 1], linePaint, isDashed);
    }
    // partial last segment
    if (fullIdx < n - 1 && frac > 0) {
      final partial = Offset.lerp(
        offsets[fullIdx],
        offsets[fullIdx + 1],
        frac,
      )!;
      _drawSegment(canvas, offsets[fullIdx], partial, linePaint, isDashed);
    }

    // markers up to animated position
    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= fullIdx && i < n; i++) {
      _drawMarker(canvas, offsets[i], markerShape, markerPaint, borderPaint);
    }
  }

  void _drawSegment(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint,
    bool isDashed,
  ) {
    if (!isDashed) {
      canvas.drawLine(a, b, paint);
      return;
    }
    // dashed line
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    const dashLen = 6.0;
    const gapLen = 4.0;
    double covered = 0;
    bool drawing = true;
    while (covered < length) {
      final seg = drawing ? dashLen : gapLen;
      final end = math.min(covered + seg, length);
      if (drawing) {
        final t1 = covered / length;
        final t2 = end / length;
        canvas.drawLine(
          Offset(a.dx + dx * t1, a.dy + dy * t1),
          Offset(a.dx + dx * t2, a.dy + dy * t2),
          paint,
        );
      }
      covered += seg;
      drawing = !drawing;
    }
  }

  void _drawMarker(
    Canvas canvas,
    Offset center,
    _MarkerShape shape,
    Paint fill,
    Paint border,
  ) {
    const size = 5.0;
    if (shape == _MarkerShape.diamond) {
      final path = Path()
        ..moveTo(center.dx, center.dy - size)
        ..lineTo(center.dx + size, center.dy)
        ..lineTo(center.dx, center.dy + size)
        ..lineTo(center.dx - size, center.dy)
        ..close();
      canvas.drawPath(path, border..color = Colors.white);
      canvas.drawPath(path, fill);
    } else {
      canvas.drawRect(
        Rect.fromCenter(center: center, width: size * 1.8, height: size * 1.8),
        border..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromCenter(center: center, width: size * 1.6, height: size * 1.6),
        fill,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.progress != progress || old.presentPoints != presentPoints;
}

enum _MarkerShape { diamond, square }

// ─────────────────────────────────────────────────────────
// LEGEND LINE PAINTER
// ─────────────────────────────────────────────────────────

class _LegendLinePainter extends CustomPainter {
  final Color color;
  final bool isDashed;
  _LegendLinePainter({required this.color, required this.isDashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    if (!isDashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    } else {
      double x = 0;
      bool draw = true;
      while (x < size.width) {
        if (draw)
          canvas.drawLine(
            Offset(x, y),
            Offset(math.min(x + 6, size.width), y),
            paint,
          );
        x += draw ? 6 : 4;
        draw = !draw;
      }
    }
    // center marker
    final cx = size.width / 2;
    final mp = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    if (!isDashed) {
      final path = Path()
        ..moveTo(cx, y - 4)
        ..lineTo(cx + 4, y)
        ..lineTo(cx, y + 4)
        ..lineTo(cx - 4, y)
        ..close();
      canvas.drawPath(path, mp);
    } else {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, y), width: 7, height: 7),
        mp,
      );
    }
  }

  @override
  bool shouldRepaint(_LegendLinePainter old) => false;
}

// ─────────────────────────────────────────────────────────
// PIE CHART PAINTER (unchanged)
// ─────────────────────────────────────────────────────────

class _PieChartPainter extends CustomPainter {
  final double presentRatio;
  final double progress;
  final Color presentColor;
  final Color absentColor;

  _PieChartPainter({
    required this.presentRatio,
    required this.progress,
    required this.presentColor,
    required this.absentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 10;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    const start = -math.pi / 2;

    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    final pSweep = 2 * math.pi * presentRatio * progress;
    canvas.drawArc(
      rect,
      start,
      pSweep,
      false,
      Paint()
        ..color = presentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      rect,
      start + pSweep,
      2 * math.pi * (1 - presentRatio) * progress,
      false,
      Paint()
        ..color = absentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PieChartPainter old) =>
      old.progress != progress || old.presentRatio != presentRatio;
}
