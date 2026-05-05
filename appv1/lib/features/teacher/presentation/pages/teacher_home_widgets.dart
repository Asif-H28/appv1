import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

const Color _wAccent = Colors.teal;

// ─────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────

int periodNum(Map<String, dynamic> s) => s['periodNumber'] is int
    ? s['periodNumber'] as int
    : int.tryParse(s['periodNumber']?.toString() ?? '') ?? 0;

bool isCurrentPeriod(Map<String, dynamic> slot) {
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

Color subjectColor(String? subject) => Colors.teal[600]!;

// ─────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HomeSectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 1),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _wAccent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _wAccent.withOpacity(0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: TextStyle(
                      color: _wAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, size: 12, color: _wAccent),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// VIEW MORE BUTTON
// ─────────────────────────────────────────────────────

class HomeViewMoreBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const HomeViewMoreBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _wAccent.withOpacity(0.2)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _wAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 15, color: _wAccent),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// SCHEDULE CARD
// ─────────────────────────────────────────────────────

class HomeScheduleCard extends StatelessWidget {
  final Map<String, dynamic> slot;
  const HomeScheduleCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final subject = slot['subjectName']?.toString() ?? '';
    final className = slot['className']?.toString() ?? '';
    final start = slot['startTime']?.toString() ?? '';
    final end = slot['endTime']?.toString() ?? '';
    final pNum = periodNum(slot);
    final isCurr = isCurrentPeriod(slot);
    final color = isCurr ? Colors.teal[700]! : Colors.teal[600]!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCurr ? Colors.teal[400]! : Colors.grey[200]!,
          width: isCurr ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurr
                ? Colors.teal.withOpacity(0.08)
                : Colors.black.withOpacity(0.025),
            blurRadius: isCurr ? 10 : 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 3,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 10),

          // Period bubble
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Text(
                'P$pNum',
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),

          // Subject + class name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subject.isNotEmpty ? subject : 'Period $pNum',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurr) ...[
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal[600],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'NOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.class_rounded,
                      size: 10,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        className,
                        style: TextStyle(
                          color: AppColors.textSecondary,
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
            ),
          ),

          // Time badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.07),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Column(
              children: [
                Text(
                  start,
                  style: TextStyle(
                    color: Colors.teal[700],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  height: 1,
                  width: 20,
                  margin: EdgeInsets.symmetric(vertical: 2),
                  color: Colors.teal.withOpacity(0.25),
                ),
                Text(
                  end,
                  style: TextStyle(color: Colors.teal[400], fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// SCHEDULE SKELETON
// ─────────────────────────────────────────────────────

class HomeScheduleSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: EdgeInsets.only(bottom: 10),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 38,
                margin: EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 11, width: 100, color: Colors.grey[200]),
                    SizedBox(height: 7),
                    Container(height: 9, width: 64, color: Colors.grey[200]),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 12),
                width: 42,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// SCHEDULE ERROR
// ─────────────────────────────────────────────────────

class HomeScheduleError extends StatelessWidget {
  final VoidCallback onRetry;
  const HomeScheduleError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.red[400], size: 17),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Failed to load',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// NO CLASSES CARD
// ─────────────────────────────────────────────────────

class HomeNoClassesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: Colors.teal[600],
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No classes today',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Colors.teal[700],
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Enjoy your free day',
                  style: TextStyle(color: Colors.teal[400], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// CLASSROOM CARD
// ─────────────────────────────────────────────────────

class HomeClassroomCard extends StatelessWidget {
  final Map<String, dynamic> classroom;
  final VoidCallback onView;
  const HomeClassroomCard({required this.classroom, required this.onView});

  @override
  Widget build(BuildContext context) {
    final name = classroom['className']?.toString() ?? 'Class';
    final section = classroom['section']?.toString() ?? '';
    final students =
        classroom['studentCount'] ??
        (classroom['students'] as List?)?.length ??
        0;
    final subject = classroom['subject']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left teal strip
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: Colors.teal[600],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
              ),
            ),

            // Avatar
            Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 0, 12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.teal[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.isNotEmpty ? '$name – $section' : name,
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
                          Icons.people_rounded,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          '$students students',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (subject.isNotEmpty) ...[
                          SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withOpacity(0.35),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subject,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // View button
            Padding(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: GestureDetector(
                onTap: onView,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.teal.withOpacity(0.25)),
                  ),
                  child: Text(
                    'View',
                    style: TextStyle(
                      color: Colors.teal[700],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
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

// ─────────────────────────────────────────────────────
// CLASSROOM SKELETON
// ─────────────────────────────────────────────────────

class HomeClassroomSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          margin: EdgeInsets.only(bottom: 8),
          height: 62,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 11, width: 100, color: Colors.grey[200]),
                    SizedBox(height: 7),
                    Container(height: 9, width: 70, color: Colors.grey[200]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// NO CLASSROOMS CARD
// ─────────────────────────────────────────────────────

class HomeNoClassroomsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              Icons.class_outlined,
              color: Colors.teal[600],
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'No classrooms found',
            style: TextStyle(
              color: Colors.teal[700],
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// NOTICE CARD
// ─────────────────────────────────────────────────────

class HomeNoNoticesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              Icons.campaign_outlined,
              color: Colors.teal[600],
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'No announcements found',
            style: TextStyle(
              color: Colors.teal[700],
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeNoticeCard extends StatelessWidget {
  final Map<String, dynamic> notice;
  final VoidCallback onTap;
  const HomeNoticeCard({required this.notice, required this.onTap});

  String _formatDate(String iso) {
    if (iso.isEmpty) return 'Today';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return '${diff}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = notice['title']?.toString() ?? 'Notice';
    final preview = notice['description']?.toString() ?? '';
    final time = _formatDate(notice['createdAt']?.toString() ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.022),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.campaign_rounded,
                color: Colors.orange[600],
                size: 18,
              ),
            ),
            SizedBox(width: 12),

            // Title + preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Time + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.teal[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
