import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

const Color _accent = Colors.teal;

class StudentTestCard extends StatelessWidget {
  final Map<String, dynamic> test;
  final VoidCallback onTap;
  const StudentTestCard({required this.test, required this.onTap});

  String get _module => test['testModule']?.toString() ?? 'Test';

  String get _teacherName => test['teacherName']?.toString() ?? '';

  List<dynamic> get _subjects => test['subjects'] as List<dynamic>? ?? [];

  int get _totalMarks => _subjects.fold<int>(
    0,
    (sum, s) =>
        sum +
        ((s as Map<String, dynamic>)['maximumScore'] as num? ?? 0).toInt(),
  );

  String get _createdAt {
    final raw = test['createdAt']?.toString() ?? '';
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
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
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  // ── Subject color cycle ───────────────────────────────
  static const List<Color> _subjectColors = [
    Color(0xFF00897B),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFE53935),
    Color(0xFFFF8F00),
    Color(0xFF43A047),
  ];

  @override
  Widget build(BuildContext context) {
    final subjects = _subjects;
    final subjectCount = subjects.length;
    final totalMarks = _totalMarks;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top gradient banner ──
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, _accent.withOpacity(0.4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: icon + module name + arrow ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Quiz icon with gradient bg ──
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_accent, _accent.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(
                          Icons.quiz_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _module,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5),

                            // ── Teacher + date ──
                            Row(
                              children: [
                                if (_teacherName.isNotEmpty) ...[
                                  Icon(
                                    Icons.person_rounded,
                                    size: 11,
                                    color: _accent,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    _teacherName,
                                    style: TextStyle(
                                      color: _accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                ],
                                if (_createdAt.isNotEmpty)
                                  Text(
                                    _createdAt,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // ── Row 2: stat pills ──
                  Row(
                    children: [
                      _statPill(
                        icon: Icons.book_outlined,
                        label:
                            '$subjectCount Subject${subjectCount != 1 ? 's' : ''}',
                        color: _accent,
                      ),
                      SizedBox(width: 8),
                      _statPill(
                        icon: Icons.score_rounded,
                        label: '$totalMarks Total Marks',
                        color: Colors.indigo[600]!,
                      ),
                    ],
                  ),

                  SizedBox(height: 14),

                  // ── Row 3: subject avatar dots + view result ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Colored subject dots ──
                      SizedBox(
                        height: 28,
                        child: Row(
                          children: [
                            // show max 4 dots, rest as +N
                            ...List.generate(
                              subjects.length > 4 ? 4 : subjects.length,
                              (i) {
                                final sub = subjects[i] as Map<String, dynamic>;
                                final name =
                                    sub['subjectName']?.toString() ?? '';
                                final color =
                                    _subjectColors[i % _subjectColors.length];
                                return Padding(
                                  padding: EdgeInsets.only(right: 5),
                                  child: Tooltip(
                                    message: name,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: color.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // ── +N overflow chip ──
                            if (subjects.length > 4)
                              Container(
                                height: 28,
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${subjects.length - 4}',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      Spacer(),

                      // ── View Result CTA ──
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_accent, _accent.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'View Result',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ],
                        ),
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

  // ── Stat pill ─────────────────────────────────────────

  Widget _statPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
