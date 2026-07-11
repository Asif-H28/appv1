import 'package:flutter/material.dart';
import 'package:appv1/features/student/student_theme_manager.dart';

class StudentResultDetailPage extends StatelessWidget {
  final Map<String, dynamic> result;
  final int rank;

  const StudentResultDetailPage({
    super.key,
    required this.result,
    required this.rank,
  });

  Color _gradeColor(String g) {
    switch (g.toUpperCase()) {
      case 'A+':
      case 'A':
        return Colors.teal;
      case 'B+':
      case 'B':
        return Colors.blue[600]!;
      case 'C':
        return Colors.orange[700]!;
      default:
        return Colors.red[600]!;
    }
  }

  Color _statusColor(String s) =>
      s.toLowerCase() == 'pass' ? Colors.teal : Colors.red[600]!;

  Color _statusBg(String s) => s.toLowerCase() == 'pass'
      ? Colors.teal.withOpacity(0.08)
      : Colors.red.withOpacity(0.08);

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
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
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        final grade = result['grade']?.toString() ?? '-';
        final status = result['overallStatus']?.toString() ?? 'pass';
        final scored = result['totalScoredMarks'] ?? 0;
        final max = result['totalMaximumMarks'] ?? 0;
        final pct = (result['percentage'] as num?)?.toDouble() ?? 0.0;
        final studentName = result['studentName']?.toString() ?? '';
        final testModule = result['testModule']?.toString() ?? '';
        final publishedAt = result['publishedAt']?.toString() ?? '';
        final subjects = (result['subjectResults'] as List? ?? [])
            .cast<Map<String, dynamic>>();

        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                testModule,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'Rank #$rank',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: _gradeColor(grade).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: _gradeColor(
                                        grade,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    grade,
                                    style: TextStyle(
                                      color: _gradeColor(grade),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$scored / $max marks',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: theme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${pct.toStringAsFixed(1)}% · Rank #$rank',
                                        style: TextStyle(
                                          color: theme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusBg(status),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    status[0].toUpperCase() +
                                        status.substring(1),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                backgroundColor: Colors.grey[100],
                                color: _statusColor(status),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Subject results
                      Text(
                        'SUBJECT RESULTS',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...subjects.map((s) {
                        final subStatus = s['status']?.toString() ?? 'pass';
                        final subPct =
                            s['maximumScore'] != null &&
                                (s['maximumScore'] as num) > 0
                            ? ((s['scoredMarks'] as num) /
                                      (s['maximumScore'] as num) *
                                      100)
                                  .toDouble()
                            : 0.0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s['subjectName']?.toString() ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: theme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${s['scoredMarks']} / ${s['maximumScore']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: theme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusBg(subStatus),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      subStatus[0].toUpperCase() +
                                          subStatus.substring(1),
                                      style: TextStyle(
                                        color: _statusColor(subStatus),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: subPct / 100,
                                  backgroundColor: Colors.grey[100],
                                  color: _statusColor(subStatus),
                                  minHeight: 4,
                                ),
                              ),
                              if (s['remarks'] != null &&
                                  s['remarks'].toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  s['remarks'].toString(),
                                  style: TextStyle(
                                    color: theme.textSecondary,
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Pass mark: ${s['minimumScore']}',
                                style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      if (publishedAt.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Published on ${_formatDate(publishedAt)}',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
