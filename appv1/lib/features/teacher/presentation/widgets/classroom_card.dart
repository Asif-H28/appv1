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
    final progressPercent = (progress * 100).toStringAsFixed(0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: _accent.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                // ── Avatar ──
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accent, _accent.withOpacity(0.65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Text(
                      className.isNotEmpty ? className[0].toUpperCase() : 'C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 11),

                // ── Name + subtitle ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        className,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 10,
                            color: _accent.withOpacity(0.7),
                          ),
                          SizedBox(width: 3),
                          Text(
                            '${subjects.length} subjects',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.touch_app_rounded,
                            size: 10,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Tap to view',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),

                // ── Circular progress (same size as delete btn) ──
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.8,
                          backgroundColor: _accent.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(_accent),
                        ),
                      ),
                      Text(
                        '$progressPercent%',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: _accent,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 7),

                // ── Delete icon (28×28 to match progress) ──
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red[400],
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
