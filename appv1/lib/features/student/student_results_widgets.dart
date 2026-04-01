import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_result_detail_page.dart';

// ── Top bar: test selector + tab switcher ──────────────

class ResultsTopBar extends StatefulWidget {
  final List<Map<String, dynamic>> tests;
  final Map<String, dynamic>? selectedTest;
  final bool testsLoading;
  final TabController tabController;
  final ValueChanged<Map<String, dynamic>> onTestSelected;

  const ResultsTopBar({
    super.key,
    required this.tests,
    required this.selectedTest,
    required this.testsLoading,
    required this.tabController,
    required this.onTestSelected,
  });

  @override
  State<ResultsTopBar> createState() => _ResultsTopBarState();
}

class _ResultsTopBarState extends State<ResultsTopBar> {
  bool _open = false;

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
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
      return '${d.day} ${m[d.month]} ${d.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: _buildSelector()),
          const SizedBox(width: 10),
          _buildTabToggle(),
        ],
      ),
    );
  }

  // ── Test selector (showModalBottomSheet) ───────────

  Widget _buildSelector() {
    if (widget.testsLoading) {
      return Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.tests.isEmpty
          ? null
          : () {
              setState(() => _open = !_open);
              _showTestSheet();
            },
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _open ? Colors.teal : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.quiz_outlined,
                color: Colors.teal,
                size: 13,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.selectedTest?['testModule']?.toString() ?? 'Select Test',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: widget.selectedTest != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              _open
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: _open ? Colors.teal : Colors.grey[500],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showTestSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Select Test',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.tests.length} tests',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: widget.tests.length,
                itemBuilder: (_, i) {
                  final t = widget.tests[i];
                  final isSel = widget.selectedTest?['testId'] == t['testId'];
                  final dateStr = t['createdAt'] != null
                      ? _formatDate(t['createdAt'].toString())
                      : '';
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _open = false);
                      widget.onTestSelected(t);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      color: isSel
                          ? Colors.teal.withOpacity(0.05)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? Colors.teal.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(3),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.quiz_outlined,
                              size: 15,
                              color: isSel ? Colors.teal : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['testModule']?.toString() ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSel
                                        ? Colors.teal
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                if (dateStr.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSel)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.teal,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => _open = false);
    });
  }

  // ── Compact tab toggle ─────────────────────────────

  Widget _buildTabToggle() {
    return AnimatedBuilder(
      animation: widget.tabController,
      builder: (_, __) {
        final idx = widget.tabController.index;
        return Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(3),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tabChip('Mine', 0, idx),
              const SizedBox(width: 3),
              _tabChip('Class', 1, idx),
            ],
          ),
        );
      },
    );
  }

  Widget _tabChip(String label, int index, int current) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => widget.tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? Colors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── My Result tab ──────────────────────────────────────

class MyResultTab extends StatelessWidget {
  final Map<String, dynamic> result;
  final int rank;

  const MyResultTab({super.key, required this.result, required this.rank});

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

  Color _sc(String s) =>
      s.toLowerCase() == 'pass' ? Colors.teal : Colors.red[600]!;
  Color _sb(String s) => s.toLowerCase() == 'pass'
      ? Colors.teal.withOpacity(0.08)
      : Colors.red.withOpacity(0.08);

  Widget _rankWidget(int r) {
    if (r == 1) return const Text('🥇', style: TextStyle(fontSize: 16));
    if (r == 2) return const Text('🥈', style: TextStyle(fontSize: 16));
    if (r == 3) return const Text('🥉', style: TextStyle(fontSize: 16));
    return Text(
      '#$r',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grade = result['grade']?.toString() ?? '-';
    final status = result['overallStatus']?.toString() ?? 'pass';
    final scored = result['totalScoredMarks'] ?? 0;
    final max = result['totalMaximumMarks'] ?? 0;
    final pct = (result['percentage'] as num?)?.toDouble() ?? 0.0;
    final subjects = (result['subjectResults'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary card ──
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
                    // Grade box
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _gradeColor(grade).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: _gradeColor(grade).withOpacity(0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        grade,
                        style: TextStyle(
                          color: _gradeColor(grade),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$scored / $max',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pct.toStringAsFixed(1)}% overall',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _sb(status),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(
                              color: _sc(status),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (rank > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _rankWidget(rank),
                              const SizedBox(width: 4),
                              Text(
                                'Rank #$rank',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: Colors.grey[100],
                    color: _sc(status),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'SUBJECT BREAKDOWN',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),

          // Subject list — shared borders
          ...subjects.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final ss = s['status']?.toString() ?? 'pass';
            final maxS = (s['maximumScore'] as num?)?.toDouble() ?? 0;
            final scored = (s['scoredMarks'] as num?)?.toDouble() ?? 0;
            final subPct = maxS > 0 ? (scored / maxS * 100) : 0.0;
            final isFirst = i == 0;
            final isLast = i == subjects.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isFirst ? 3 : 0),
                  topRight: Radius.circular(isFirst ? 3 : 0),
                  bottomLeft: Radius.circular(isLast ? 3 : 0),
                  bottomRight: Radius.circular(isLast ? 3 : 0),
                ),
                border: Border(
                  left: BorderSide(color: Colors.grey[200]!),
                  right: BorderSide(color: Colors.grey[200]!),
                  top: BorderSide(color: Colors.grey[200]!),
                  bottom: isLast
                      ? BorderSide(color: Colors.grey[200]!)
                      : BorderSide.none,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s['subjectName']?.toString() ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${s['scoredMarks']} / ${s['maximumScore']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _sb(ss),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          ss[0].toUpperCase() + ss.substring(1),
                          style: TextStyle(
                            color: _sc(ss),
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
                      color: _sc(ss),
                      minHeight: 4,
                    ),
                  ),
                  if (s['remarks'] != null &&
                      s['remarks'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        s['remarks'].toString(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Class Results tab ──────────────────────────────────

class ClassResultsTab extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final String studentId;

  const ClassResultsTab({
    super.key,
    required this.results,
    required this.studentId,
  });

  Widget _rankBadge(int rank) {
    if (rank == 1) {
      return const SizedBox(
        width: 24,
        child: Text(
          '🥇',
          style: TextStyle(fontSize: 15),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (rank == 2) {
      return const SizedBox(
        width: 24,
        child: Text(
          '🥈',
          style: TextStyle(fontSize: 15),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (rank == 3) {
      return const SizedBox(
        width: 24,
        child: Text(
          '🥉',
          style: TextStyle(fontSize: 15),
          textAlign: TextAlign.center,
        ),
      );
    }
    return SizedBox(
      width: 24,
      child: Text(
        '$rank',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final rank = i + 1;
        final r = results[i];
        final isMe = r['studentId']?.toString() == studentId;
        final isFirst = i == 0;
        final isLast = i == results.length - 1;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentResultDetailPage(result: r, rank: rank),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isMe ? Colors.teal.withOpacity(0.04) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isFirst ? 3 : 0),
                topRight: Radius.circular(isFirst ? 3 : 0),
                bottomLeft: Radius.circular(isLast ? 3 : 0),
                bottomRight: Radius.circular(isLast ? 3 : 0),
              ),
              border: Border(
                left: BorderSide(
                  color: isMe
                      ? Colors.teal.withOpacity(0.25)
                      : Colors.grey[200]!,
                ),
                right: BorderSide(
                  color: isMe
                      ? Colors.teal.withOpacity(0.25)
                      : Colors.grey[200]!,
                ),
                top: BorderSide(
                  color: isMe
                      ? Colors.teal.withOpacity(0.25)
                      : Colors.grey[200]!,
                ),
                bottom: isLast
                    ? BorderSide(
                        color: isMe
                            ? Colors.teal.withOpacity(0.25)
                            : Colors.grey[200]!,
                      )
                    : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                _rankBadge(rank),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          r['studentName']?.toString() ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${r['totalScoredMarks']} / ${r['totalMaximumMarks']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 15),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── State widgets ──────────────────────────────────────

class ResultsSkeleton extends StatelessWidget {
  const ResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: List.generate(5, (i) {
          final isFirst = i == 0;
          final isLast = i == 4;
          return Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
            height: 46,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isFirst ? 3 : 0),
                topRight: Radius.circular(isFirst ? 3 : 0),
                bottomLeft: Radius.circular(isLast ? 3 : 0),
                bottomRight: Radius.circular(isLast ? 3 : 0),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ResultsErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const ResultsErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.grey[400], size: 34),
            const SizedBox(height: 10),
            Text(
              'Failed to load',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultsNoTestsState extends StatelessWidget {
  const ResultsNoTestsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.quiz_outlined, color: Colors.teal[200], size: 34),
          const SizedBox(height: 10),
          Text(
            'No tests yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tests will appear here once published.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ResultsNoResultsState extends StatelessWidget {
  const ResultsNoResultsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, color: Colors.grey[300], size: 34),
          const SizedBox(height: 10),
          Text(
            'No results yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Results will appear here once published.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
