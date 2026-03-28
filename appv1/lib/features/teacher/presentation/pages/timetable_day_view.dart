import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/constants/app_colors.dart';
import 'timetable_slot_edit_sheet.dart';

class TimetableDayView extends StatelessWidget {
  final String day;
  final List<Map<String, dynamic>> slots;
  final String timetableId;
  final String orgId; // ← new
  final List<String> classSubjects; // ← new
  final VoidCallback onRefresh;

  const TimetableDayView({
    required this.day,
    required this.slots,
    required this.timetableId,
    required this.orgId, // ← new
    required this.classSubjects, // ← new
    required this.onRefresh,
  });

  Color _typeColor(String t) {
    switch (t) {
      case 'class':
        return Colors.teal[600]!;
      case 'lunch':
        return Colors.orange[500]!;
      case 'break':
        return Colors.blue[400]!;
      case 'free':
        return Colors.grey[400]!;
      case 'pt':
        return Colors.green[500]!;
      case 'lab':
        return Colors.purple[500]!;
      default:
        return Colors.grey[400]!;
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'class':
        return Icons.menu_book_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'break':
        return Icons.coffee_rounded;
      case 'free':
        return Icons.free_cancellation_rounded;
      case 'pt':
        return Icons.directions_run_rounded;
      case 'lab':
        return Icons.science_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'class':
        return 'Class';
      case 'lunch':
        return 'Lunch';
      case 'break':
        return 'Break';
      case 'free':
        return 'Free';
      case 'pt':
        return 'PT';
      case 'lab':
        return 'Lab';
      default:
        return t.isNotEmpty ? t[0].toUpperCase() + t.substring(1) : t;
    }
  }

  bool _isCurrentPeriod(Map<String, dynamic> slot) {
    final now = TimeOfDay.now();
    final start = _parseTime(slot['startTime']?.toString() ?? '');
    final end = _parseTime(slot['endTime']?.toString() ?? '');
    if (start == null || end == null) return false;
    final nowMins = now.hour * 60 + now.minute;
    final startMins = start.hour * 60 + start.minute;
    final endMins = end.hour * 60 + end.minute;
    return nowMins >= startMins && nowMins < endMins;
  }

  TimeOfDay? _parseTime(String t) {
    try {
      final parts = t.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  String _duration(String start, String end) {
    final s = _parseTime(start);
    final e = _parseTime(end);
    if (s == null || e == null) return '';
    final mins = (e.hour * 60 + e.minute) - (s.hour * 60 + s.minute);
    if (mins <= 0) return '';
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  // ── Delete ────────────────────────────────────────────

  Future<void> _deleteSlot(
    BuildContext context,
    Map<String, dynamic> slot,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text(
          'Remove Period?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remove Period ${slot['periodNumber']}'
          ' from $day?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final body = jsonEncode({'day': day, 'periodNumber': slot['periodNumber']});

    debugPrint(
      '[SlotDelete] id=$timetableId day=$day p=${slot['periodNumber']}',
    );

    try {
      final request = http.Request(
        'DELETE',
        Uri.parse(
          'https://appv1backend.onrender.com/api/timetable/$timetableId/slot',
        ),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = body;

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      debugPrint('[SlotDelete] ${res.statusCode} ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 204) {
        onRefresh();
        _snack(context, 'Period removed');
      } else {
        String msg = 'Failed (${res.statusCode})';
        try {
          final b = jsonDecode(res.body);
          msg = b['message']?.toString() ?? b['error']?.toString() ?? msg;
        } catch (_) {}
        _snack(context, msg, isError: true);
      }
    } catch (e) {
      _snack(context, 'No internet connection', isError: true);
    }
  }

  // ── Edit ──────────────────────────────────────────────

  Future<void> _editSlot(
    BuildContext context,
    Map<String, dynamic> slot,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimetableSlotEditSheet(
        day: day,
        slot: slot,
        timetableId: timetableId,
        orgId: orgId, // ← add this field
        classSubjects: classSubjects, // ← add this field
        onSaved: onRefresh,
      ),
    );
  }

  void _snack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        margin: EdgeInsets.all(14),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 30,
                color: Colors.grey[350],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'No periods for $day',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Use "+ Add Period" to add one',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.55),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 40),
      itemCount: slots.length,
      separatorBuilder: (_, __) => Padding(
        padding: EdgeInsets.only(left: 22),
        child: Container(width: 2, height: 10, color: Colors.grey[200]),
      ),
      itemBuilder: (context, i) => _slotCard(context, i, slots[i]),
    );
  }

  // ── Slot card ─────────────────────────────────────────

  Widget _slotCard(BuildContext context, int i, Map<String, dynamic> slot) {
    final type = slot['type']?.toString() ?? 'class';
    final isCurr = _isCurrentPeriod(slot);
    final color = _typeColor(type);
    final isClass = type == 'class' || type == 'lab';

    final startTime = slot['startTime']?.toString() ?? '';
    final endTime = slot['endTime']?.toString() ?? '';
    final subject = slot['subjectName']?.toString() ?? '';
    final teacher = slot['teacherName']?.toString() ?? '';
    final dur = _duration(startTime, endTime);

    final periodNum = slot['periodNumber'] is int
        ? slot['periodNumber'] as int
        : int.tryParse(slot['periodNumber']?.toString() ?? '') ?? (i + 1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCurr ? color.withOpacity(0.55) : Colors.grey[200]!,
          width: isCurr ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurr
                ? color.withOpacity(0.1)
                : Colors.black.withOpacity(0.03),
            blurRadius: isCurr ? 10 : 4,
            offset: Offset(0, 2),
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
              width: 52,
              padding: EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.04),
                border: Border(right: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'P$periodNum',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      _typeLabel(type),
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
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
                        color: color,
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
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time + duration
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '$startTime – $endTime',
                          style: TextStyle(
                            color: AppColors.textSecondary,
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
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              dur,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 6),

                    // Subject / type
                    if (isClass && subject.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(_typeIcon(type), size: 13, color: color),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              subject,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else if (!isClass) ...[
                      Row(
                        children: [
                          Icon(_typeIcon(type), size: 13, color: color),
                          SizedBox(width: 5),
                          Text(
                            _typeLabel(type),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            _typeIcon(type),
                            size: 13,
                            color: Colors.grey[400],
                          ),
                          SizedBox(width: 5),
                          Text(
                            'No subject assigned',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Teacher
                    if (isClass && teacher.isNotEmpty) ...[
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
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
                                  fontSize: 8,
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
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
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

            // Edit + Delete column
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _editSlot(context, slot),
                  child: Container(
                    width: 36,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.06),
                      border: Border(
                        left: BorderSide(color: Colors.grey[100]!),
                      ),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 15,
                      color: Colors.teal[400],
                    ),
                  ),
                ),
                Container(height: 1, width: 36, color: Colors.grey[100]),
                GestureDetector(
                  onTap: () => _deleteSlot(context, slot),
                  child: Container(
                    width: 36,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.04),
                      border: Border(
                        left: BorderSide(color: Colors.grey[100]!),
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 15,
                      color: Colors.red[300],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
