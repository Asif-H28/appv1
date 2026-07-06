import 'package:flutter/material.dart';
import 'student_theme_manager.dart';

class StudentAttendanceSummaryCard extends StatelessWidget {
  final int totalDays;
  final int totalPresent;
  final int totalAbsent;
  final double percentage;
  final Color statusColor;
  final String statusLabel;

  const StudentAttendanceSummaryCard({
    required this.totalDays,
    required this.totalPresent,
    required this.totalAbsent,
    required this.percentage,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Gradient top bar ──
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withOpacity(0.4)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  children: [
                    // ── Top row: ring + details ──
                    Row(
                      children: [
                        // ── Circular percentage ring ──
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: CircularProgressIndicator(
                                  value: percentage / 100,
                                  strokeWidth: 7,
                                  backgroundColor: theme.dividerColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    statusColor,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: theme.textPrimary,
                                      height: 1,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Attended',
                                    style: TextStyle(
                                      color: theme.textSecondary,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20),

                        // ── Stats ──
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: statusColor,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 14),

                              // 3 stat rows
                              _statRow(
                                label: 'Total Days',
                                value: '$totalDays',
                                color: theme.primary,
                                theme: theme,
                              ),
                              SizedBox(height: 8),
                              _statRow(
                                label: 'Present',
                                value: '$totalPresent',
                                color: Colors.green[600]!,
                                theme: theme,
                              ),
                              SizedBox(height: 8),
                              _statRow(
                                label: 'Absent',
                                value: '$totalAbsent',
                                color: Colors.red[600]!,
                                theme: theme,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // ── Progress bar ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Attendance Progress',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: theme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$totalPresent / $totalDays days',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: totalDays > 0 ? totalPresent / totalDays : 0,
                            minHeight: 8,
                            backgroundColor: theme.dividerColor,
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        ),
                        SizedBox(height: 6),
                        // 75% threshold marker hint
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 11,
                              color: theme.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '75% attendance required to avoid shortage',
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statRow({
    required String label,
    required String value,
    required Color color,
    required StudentThemeConfig theme,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: theme.textSecondary, fontSize: 12),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
