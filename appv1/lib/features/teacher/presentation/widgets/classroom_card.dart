import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ClassroomCard extends StatelessWidget {
  final Map<String, dynamic> classroom;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ClassroomCard({
    required this.classroom,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  static const Color _accent = Colors.teal;

  @override
  Widget build(BuildContext context) {
    final className = classroom['className']?.toString() ?? 'Class';
    final subjects = classroom['subjects'] as List? ?? [];
    final students = classroom['students'] as List? ?? [];
    final classId = classroom['classId']?.toString() ?? '';

    int totalLessons = 0;
    int completedLessons = 0;
    for (final sub in subjects) {
      final lessons = (sub as Map)['lessons'] as List? ?? [];
      totalLessons += lessons.length;
      completedLessons += lessons
          .where((l) => (l as Map)['completed'] == true)
          .length;
    }

    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.10),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: _accent.withOpacity(0.12)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // ── Icon ──
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_accent, _accent.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          className.isNotEmpty
                              ? className[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            className,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.tag_rounded,
                                size: 11,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 2),
                              Text(
                                classId,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Delete menu ──
                    PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                      onSelected: (val) {
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                color: Colors.red[600],
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete Classroom',
                                style: TextStyle(color: Colors.red[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 14),

                // ── Divider ──
                Divider(height: 1, color: _accent.withOpacity(0.08)),
                SizedBox(height: 14),

                // ── Stats row ──
                Row(
                  children: [
                    _statBadge(
                      Icons.menu_book_rounded,
                      '${subjects.length}',
                      'Subjects',
                    ),
                    SizedBox(width: 8),
                    _statBadge(
                      Icons.people_rounded,
                      '${students.length}',
                      'Students',
                    ),
                    SizedBox(width: 8),
                    _statBadge(Icons.task_rounded, '$totalLessons', 'Lessons'),
                  ],
                ),
                SizedBox(height: 14),

                // ── Progress ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lesson Progress',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '$completedLessons/$totalLessons completed',
                              style: TextStyle(
                                fontSize: 11,
                                color: _accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              totalLessons > 0
                                  ? '(${(progress * 100).toStringAsFixed(0)}%)'
                                  : '(0%)',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: _accent.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(_accent),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // ── Bottom row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accent.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: _accent,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBadge(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _accent, size: 18),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}
