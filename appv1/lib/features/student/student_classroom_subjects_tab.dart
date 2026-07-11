import 'package:flutter/material.dart';
import 'package:appv1/features/student/student_theme_manager.dart';

class StudentClassroomSubjectsTab extends StatefulWidget {
  final Map<String, dynamic> classroom;
  const StudentClassroomSubjectsTab({required this.classroom});

  @override
  _StudentClassroomSubjectsTabState createState() =>
      _StudentClassroomSubjectsTabState();
}

class _StudentClassroomSubjectsTabState
    extends State<StudentClassroomSubjectsTab> {
  StudentThemeConfig get theme => StudentThemeManager.themeNotifier.value;
  // Track which subjects are expanded
  final Set<int> _expanded = {};

  List<dynamic> get _subjects =>
      widget.classroom['subjects'] as List<dynamic>? ?? [];

  @override
  void initState() {
    super.initState();
    // Expand first subject by default
    if (_subjects.isNotEmpty) _expanded.add(0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        if (_subjects.isEmpty) return _buildEmpty();

        // ── Overall progress across all subjects ──
        int totalLessons = 0;
        int completedLessons = 0;
        for (final s in _subjects) {
          final lessons = s['lessons'] as List<dynamic>? ?? [];
          totalLessons += lessons.length;
          completedLessons += lessons
              .where((l) => l['completed'] == true)
              .length;
        }
        final overallProgress = totalLessons == 0
            ? 0.0
            : completedLessons / totalLessons;

        return ListView(
          padding: EdgeInsets.fromLTRB(14, 16, 14, 40),
          children: [
            // ── Overall progress card ──
            _buildOverallProgress(
              completedLessons,
              totalLessons,
              overallProgress,
            ),
            SizedBox(height: 20),

            Text(
              'Subjects',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.textPrimary,
              ),
            ),
            SizedBox(height: 10),

            // ── Subject cards ──
            ...List.generate(_subjects.length, (i) {
              final subject = _subjects[i] as Map<String, dynamic>;
              return Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: _buildSubjectCard(subject, i),
              );
            }),
          ],
        );
      },
    );
  }

  // ── Overall progress ──────────────────────────────────

  Widget _buildOverallProgress(int completed, int total, double progress) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$completed of $total lessons completed',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Subject card ──────────────────────────────────────

  Widget _buildSubjectCard(Map<String, dynamic> subject, int index) {
    final name = subject['name']?.toString() ?? 'Subject';
    final lessons = subject['lessons'] as List<dynamic>? ?? [];
    final total = lessons.length;
    final done = lessons.where((l) => l['completed'] == true).length;
    final progress = total == 0 ? 0.0 : done / total;
    final isExpanded = _expanded.contains(index);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isExpanded
              ? theme.primary.withOpacity(0.35)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // ── Header row ──
          InkWell(
            borderRadius: isExpanded
                ? BorderRadius.vertical(top: Radius.circular(3))
                : BorderRadius.circular(3),
            onTap: () => setState(() {
              if (isExpanded)
                _expanded.remove(index);
              else
                _expanded.add(index);
            }),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: TextStyle(
                          color: theme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: Colors.grey[100]!,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.primary,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '$done/$total',
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '$total lessons',
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Lessons list ──
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey[100]),
            if (lessons.isEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No lessons added yet.',
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                ),
              )
            else
              ...List.generate(lessons.length, (li) {
                final lesson = lessons[li] as Map<String, dynamic>;
                return _buildLessonRow(
                  lesson,
                  li,
                  isLast: li == lessons.length - 1,
                );
              }),
          ],
        ],
      ),
    );
  }

  // ── Lesson row ────────────────────────────────────────

  Widget _buildLessonRow(
    Map<String, dynamic> lesson,
    int index, {
    bool isLast = false,
  }) {
    final name = lesson['name']?.toString() ?? 'Lesson';
    final completed = lesson['completed'] == true;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? theme.primary.withOpacity(0.1)
                    : Colors.grey[100],
                border: Border.all(
                  color: completed ? theme.primary : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: completed
                  ? Icon(Icons.check_rounded, color: theme.primary, size: 12)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12.5,
                  color: completed ? theme.textSecondary : theme.textPrimary,
                  fontWeight: completed ? FontWeight.w400 : FontWeight.w500,
                  decoration: completed ? TextDecoration.lineThrough : null,
                  decorationColor: theme.textSecondary,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: completed
                    ? Colors.green.withOpacity(0.08)
                    : Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                completed ? 'Done' : 'Pending',
                style: TextStyle(
                  color: completed ? Colors.green[700] : Colors.orange[700],
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primary.withOpacity(0.08),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: theme.primary,
              size: 30,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'No Subjects Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: theme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your teacher has not added any subjects yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}
