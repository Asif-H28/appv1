import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/constants/app_colors.dart';
import 'timetable_create_sheet.dart';
import 'timetable_day_view.dart';
import 'timetable_add_slot_sheet.dart';

const Color _accent = Colors.teal;

class ClassroomTimetableTab extends StatefulWidget {
  final String classId;
  final String orgId;
  final String teacherId;
  final String teacherName;
  final String className;
  final List<Map<String, dynamic>> classSubjects;

  const ClassroomTimetableTab({
    required this.classId,
    required this.orgId,
    required this.teacherId,
    required this.teacherName,
    required this.className,
    required this.classSubjects,
  });

  @override
  _ClassroomTimetableTabState createState() => _ClassroomTimetableTabState();
}

class _ClassroomTimetableTabState extends State<ClassroomTimetableTab>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  bool _isEmpty = false;

  Map<String, dynamic> _timetable = {};
  List<dynamic> _allSlots = [];
  String _timetableId = '';
  String _resolvedTeacherName = '';

  late TabController _dayTabCtrl;

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _resolvedTeacherName = widget.teacherName;
    _dayTabCtrl = TabController(length: _days.length, vsync: this);
    _fetchTimetable();
    if (_resolvedTeacherName.isEmpty) {
      _resolveTeacherName();
    }
  }

  @override
  void dispose() {
    _dayTabCtrl.dispose();
    super.dispose();
  }

  // ── Resolve teacher name ──────────────────────────────

  Future<void> _resolveTeacherName() async {
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/teacher/org/${widget.orgId}',
        ),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['teachers'] ?? body['data'] ?? []) as List<dynamic>;
        final teachers = list.map((t) => t as Map<String, dynamic>).toList();
        final match = teachers.firstWhere(
          (t) => t['teacherId']?.toString() == widget.teacherId,
          orElse: () => {},
        );
        if (match.isNotEmpty && mounted) {
          setState(
            () => _resolvedTeacherName = match['name']?.toString() ?? '',
          );
          debugPrint(
            '[TimetableTab] Resolved teacherName: $_resolvedTeacherName',
          );
        }
      }
    } catch (e) {
      debugPrint('[TimetableTab] resolve error: $e');
    }
  }

  List<String> get _subjectNames => widget.classSubjects
      .map((s) => s['name']?.toString() ?? '')
      .where((s) => s.isNotEmpty)
      .toList();

  // ── Fetch timetable ───────────────────────────────────

  Future<void> _fetchTimetable() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _isEmpty = false;
    });
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/timetable/class/${widget.classId}',
        ),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;

      debugPrint('[Timetable] fetch status=${res.statusCode}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;

        final timetableId = body['timetableId']?.toString() ?? '';
        final academicYear = body['academicYear']?.toString() ?? '';
        final createdByName = body['createdByName']?.toString() ?? '';
        final className = body['className']?.toString() ?? '';

        final dayMap = body['timetable'] as Map<String, dynamic>?;

        if (timetableId.isEmpty || dayMap == null) {
          setState(() {
            _isEmpty = true;
            _isLoading = false;
          });
          return;
        }

        // Flatten day map → flat slot list
        final List<dynamic> flatSlots = [];
        dayMap.forEach((day, list) {
          if (list is List) {
            for (final slot in list) {
              if (slot is Map<String, dynamic>) {
                slot['day'] = day;
                flatSlots.add(slot);
              }
            }
          }
        });

        debugPrint('[Timetable] id=$timetableId slots=${flatSlots.length}');

        setState(() {
          _timetableId = timetableId;
          _timetable = {
            'timetableId': timetableId,
            'academicYear': academicYear,
            'createdByName': createdByName,
            'className': className,
          };
          _allSlots = flatSlots;
          _isEmpty = flatSlots.isEmpty;
          _isLoading = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _isEmpty = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Timetable] fetch error: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // ── Slots for day ─────────────────────────────────────

  List<Map<String, dynamic>> _slotsForDay(String day) {
    return _allSlots
        .where((s) {
          final slotDay =
              (s as Map<String, dynamic>)['day']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';
          return slotDay == day.toLowerCase();
        })
        .map((s) => s as Map<String, dynamic>)
        .toList()
      ..sort((a, b) {
        final aN = a['periodNumber'] is int
            ? a['periodNumber'] as int
            : int.tryParse(a['periodNumber']?.toString() ?? '') ?? 0;
        final bN = b['periodNumber'] is int
            ? b['periodNumber'] as int
            : int.tryParse(b['periodNumber']?.toString() ?? '') ?? 0;
        return aN.compareTo(bN);
      });
  }

  // ── Open create sheet ─────────────────────────────────

  void _openCreateSheet() {
    final nameToUse = _resolvedTeacherName.isNotEmpty
        ? _resolvedTeacherName
        : widget.teacherName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimetableCreateSheet(
        classId: widget.classId,
        orgId: widget.orgId,
        teacherId: widget.teacherId,
        teacherName: nameToUse,
        classSubjects: _subjectNames,
        onCreated: _fetchTimetable,
      ),
    );
  }

  // ── Open add slot sheet ───────────────────────────────

  void _openAddSlotSheet() {
    if (_timetableId.isEmpty) return;
    final currentDay = _days[_dayTabCtrl.index];
    final count = _slotsForDay(currentDay).length;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimetableAddSlotSheet(
        timetableId: _timetableId,
        initialDay: currentDay,
        nextPeriodNumber: count + 1,
        classSubjects: _subjectNames,
        orgId: widget.orgId,
        onSaved: _fetchTimetable,
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
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

  // ── Delete whole timetable ────────────────────────────

  Future<void> _deleteTimetable() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text(
          'Delete Timetable?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete the timetable'
          ' for ${widget.className}.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      debugPrint('[Timetable] Deleting id=$_timetableId');
      final res = await http.delete(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/timetable/$_timetableId',
        ),
        headers: await ApiService.getHeaders(),
      );
      debugPrint('[Timetable] Delete ${res.statusCode} ${res.body}');
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 204) {
        _snack('Timetable deleted');
        _fetchTimetable();
      } else {
        _snack('Failed to delete (${res.statusCode})', isError: true);
      }
    } catch (e) {
      _snack('No internet connection', isError: true);
    }
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoader();
    if (_hasError) return _buildError();
    if (_isEmpty) return _buildEmpty();
    return _buildTimetable();
  }

  Widget _buildTimetable() {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.className,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${_timetable['academicYear'] ?? ''}'
                      ' • ${_allSlots.length} total periods',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Add Period
              GestureDetector(
                onTap: _openAddSlotSheet,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _accent.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: _accent),
                      SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),

              _actionBtn(icon: Icons.refresh_rounded, onTap: _fetchTimetable),
              SizedBox(width: 8),
              _actionBtn(
                icon: Icons.delete_outline_rounded,
                onTap: _deleteTimetable,
                color: Colors.red[400]!,
              ),
            ],
          ),
        ),
        SizedBox(height: 12),

        // Day tab bar
        Container(
          margin: EdgeInsets.symmetric(horizontal: 14),
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TabBar(
            controller: _dayTabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(3),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            padding: EdgeInsets.all(3),
            dividerColor: Colors.transparent,
            tabs: _days.map((d) {
              final count = _slotsForDay(d).length;
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(d.substring(0, 3)),
                    if (count > 0) ...[
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 10),

        Expanded(
          child: TabBarView(
            controller: _dayTabCtrl,
            children: _days
                .map(
                  (day) => TimetableDayView(
                    day: day,
                    slots: _slotsForDay(day),
                    timetableId: _timetableId,
                    orgId: widget.orgId, // ← new
                    classSubjects: _subjectNames, // ← new
                    onRefresh: _fetchTimetable,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: (color ?? _accent).withOpacity(0.08),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: (color ?? _accent).withOpacity(0.2)),
        ),
        child: Icon(icon, size: 15, color: color ?? _accent),
      ),
    );
  }

  Widget _buildLoader() => Center(
    child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_rounded, size: 44, color: Colors.grey[400]),
        SizedBox(height: 12),
        Text(
          'Failed to load timetable',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: _fetchTimetable,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.08),
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: Icon(Icons.calendar_month_rounded, size: 32, color: _accent),
          ),
          SizedBox(height: 16),
          Text(
            'No Timetable Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create a weekly timetable\nfor ${widget.className}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          SizedBox(height: 22),
          if (_resolvedTeacherName.isEmpty) ...[
            Container(
              margin: EdgeInsets.only(bottom: 14),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Colors.orange[600],
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Resolving teacher info...',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          GestureDetector(
            onTap: _openCreateSheet,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Create Timetable',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ),
  );
}

