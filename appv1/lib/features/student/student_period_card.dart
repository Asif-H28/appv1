import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_theme_manager.dart';

// Shared period card used in both home + timetable page

class StudentPeriodCard extends StatelessWidget {
  final Map<String, dynamic> slot;
  const StudentPeriodCard({required this.slot});

  // ── Type config ────────────────────────────────────

  static const Map<String, _TypeConfig> _typeMap = {
    'class': _TypeConfig(Colors.teal, 'Class', Icons.menu_book_rounded),
    'break': _TypeConfig(
      Color(0xFF78909C),
      'Short Break',
      Icons.coffee_rounded,
    ),
    'lunch': _TypeConfig(
      Color(0xFF8D6E63),
      'Lunch Break',
      Icons.lunch_dining_rounded,
    ),
    'free': _TypeConfig(
      Color(0xFF90A4AE),
      'Free Period',
      Icons.free_cancellation_rounded,
    ),
    'pt': _TypeConfig(
      Color(0xFF43A047),
      'Physical Training',
      Icons.directions_run_rounded,
    ),
    'lab': _TypeConfig(Color(0xFF5E35B1), 'Lab Session', Icons.science_rounded),
  };

  _TypeConfig _cfg(String type) =>
      _typeMap[type] ??
      const _TypeConfig(Colors.teal, 'Period', Icons.circle_outlined);

  bool _isCurrentPeriod() {
    final now = TimeOfDay.now();
    final start = _parseTime(slot['startTime']?.toString() ?? '');
    final end = _parseTime(slot['endTime']?.toString() ?? '');
    if (start == null || end == null) return false;
    final nowM = now.hour * 60 + now.minute;
    final startM = start.hour * 60 + start.minute;
    final endM = end.hour * 60 + end.minute;
    return nowM >= startM && nowM < endM;
  }

  TimeOfDay? _parseTime(String t) {
    try {
      final p = t.split(':');
      return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    } catch (_) {
      return null;
    }
  }

  String _formatTime12(BuildContext context, String t) {
    if (t.isEmpty) return t;
    try {
      final parts = t.split(':');
      final tod = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      return tod.format(context);
    } catch (_) {
      return t;
    }
  }

  int get _pNum => slot['periodNumber'] is int
      ? slot['periodNumber'] as int
      : int.tryParse(slot['periodNumber']?.toString() ?? '') ?? 0;

  String _duration() {
    final s = _parseTime(slot['startTime']?.toString() ?? '');
    final e = _parseTime(slot['endTime']?.toString() ?? '');
    if (s == null || e == null) return '';
    final mins = (e.hour * 60 + e.minute) - (s.hour * 60 + s.minute);
    if (mins <= 0) return '';
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) => _buildCard(context, theme),
    );
  }

  Widget _buildCard(BuildContext context, StudentThemeConfig theme) {
    final type = slot['type']?.toString() ?? 'class';
    final subject = slot['subjectName']?.toString() ?? '';
    final teacher = slot['teacherName']?.toString() ?? '';
    final startRaw = slot['startTime']?.toString() ?? '';
    final endRaw = slot['endTime']?.toString() ?? '';
    final start = _formatTime12(context, startRaw);
    final end = _formatTime12(context, endRaw);
    final cfg = _cfg(type);
    final isCurr = _isCurrentPeriod();
    final isClass = type == 'class' || type == 'lab';
    final dur = _duration();

    // Force primary color for class/lab, keep others muted
    final color = (type == 'class' || type == 'lab')
        ? theme.primary
        : cfg.color;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCurr ? theme.primary : theme.dividerColor,
          width: isCurr ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurr
                ? theme.primary.withOpacity(0.08)
                : Colors.black.withOpacity(0.025),
            blurRadius: isCurr ? 10 : 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
              ),
            ),

            // Period number column
            Container(
              width: 50,
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.04),
                border: Border(right: BorderSide(color: theme.dividerColor)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'P$_pNum',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 3),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      type == 'class'
                          ? 'CLASS'
                          : type == 'lab'
                          ? 'LAB'
                          : type.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (isCurr) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        'NOW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time row
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: theme.textSecondary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          '$start – $end',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (dur.isNotEmpty) ...[
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              dur,
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 5),

                    // Subject / type label
                    Row(
                      children: [
                        Icon(cfg.icon, size: 13, color: color),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            isClass && subject.isNotEmpty ? subject : cfg.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isClass ? theme.textPrimary : color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Teacher (class/lab only)
                    if (isClass && teacher.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Center(
                              child: Text(
                                teacher
                                    .trim()
                                    .split(' ')
                                    .take(2)
                                    .map(
                                      (w) => w.isNotEmpty
                                          ? w[0].toUpperCase()
                                          : '',
                                    )
                                    .join(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              teacher,
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Type config model ──────────────────────────────────

class _TypeConfig {
  final Color color;
  final String label;
  final IconData icon;
  const _TypeConfig(this.color, this.label, this.icon);
}
