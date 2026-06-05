import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import '../../../../../core/constants/app_colors.dart';

const Color _accent = Colors.teal;

class TimetableCreateSheet extends StatefulWidget {
  final String classId;
  final String orgId;
  final String teacherId;
  final String teacherName;
  final List<String> classSubjects;
  final VoidCallback onCreated;

  const TimetableCreateSheet({
    required this.classId,
    required this.orgId,
    required this.teacherId,
    required this.teacherName,
    required this.classSubjects,
    required this.onCreated,
  });

  @override
  _TimetableCreateSheetState createState() => _TimetableCreateSheetState();
}

class _TimetableCreateSheetState extends State<TimetableCreateSheet> {
  final _yearCtrl = TextEditingController(text: '2025-26');

  // Resolved teacher name (filled from API if widget.teacherName is empty)
  late String _resolvedCreatedByName;

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> _types = [
    'class',
    'break',
    'lunch',
    'free',
    'pt',
    'lab',
  ];

  final Map<String, List<Map<String, dynamic>>> _daySlots = {
    for (final d in [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ])
      d: [],
  };

  String _activeDay = 'Monday';
  bool _isSaving = false;

  bool _loadingTeachers = true;
  List<Map<String, dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _resolvedCreatedByName = widget.teacherName;
    _fetchTeachers();
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    for (final slots in _daySlots.values)
      for (final slot in slots) _disposeSlot(slot);
    super.dispose();
  }

  void _disposeSlot(Map<String, dynamic> slot) {
    (slot['startTime'] as TextEditingController).dispose();
    (slot['endTime'] as TextEditingController).dispose();
  }

  // â”€â”€ Fetch teachers + resolve name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _fetchTeachers() async {
    setState(() => _loadingTeachers = true);
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/teacher/org/${widget.orgId}',
        ),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      debugPrint('[Teachers] status=${res.statusCode}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['teachers'] ?? body['data'] ?? []) as List<dynamic>;

        final teachers = list.map((t) => t as Map<String, dynamic>).toList();

        // Resolve createdByName from teacher list
        // if widget.teacherName came in as empty
        String resolved = _resolvedCreatedByName;
        if (resolved.isEmpty) {
          final match = teachers.firstWhere(
            (t) => t['teacherId']?.toString() == widget.teacherId,
            orElse: () => {},
          );
          if (match.isNotEmpty) {
            resolved = match['name']?.toString() ?? '';
            debugPrint('[Teachers] Resolved name: $resolved');
          }
        }

        setState(() {
          _teachers = teachers;
          _resolvedCreatedByName = resolved;
          _loadingTeachers = false;
        });
      } else {
        setState(() => _loadingTeachers = false);
      }
    } catch (e) {
      debugPrint('[Teachers] error: $e');
      if (!mounted) return;
      setState(() => _loadingTeachers = false);
    }
  }

  // â”€â”€ Add / Remove slot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _addSlot() {
    setState(() {
      _daySlots[_activeDay]!.add({
        'startTime': TextEditingController(),
        'endTime': TextEditingController(),
        'subjectName': '',
        'teacherName': _resolvedCreatedByName,
        'teacherId': widget.teacherId,
        'type': 'class',
      });
    });
  }

  void _removeSlot(int index) {
    final slot = _daySlots[_activeDay]![index];
    _disposeSlot(slot);
    setState(() => _daySlots[_activeDay]!.removeAt(index));
  }

  // â”€â”€ Time picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _pickTime(
    BuildContext context,
    TextEditingController ctrl,
  ) async {
    TimeOfDay initial = TimeOfDay(hour: 9, minute: 0);
    if (ctrl.text.isNotEmpty) {
      try {
        final p = ctrl.text.split(':');
        initial = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      } catch (_) {}
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
              primary: _accent,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() => ctrl.text = '$h:$m');
    }
  }

  // â”€â”€ Subject picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _pickSubject(BuildContext context, int index) async {
    final slot = _daySlots[_activeDay]![index];
    final current = slot['subjectName'] as String;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _SubjectPickerSheet(current: current, subjects: widget.classSubjects),
    );
    if (picked != null) {
      setState(() => _daySlots[_activeDay]![index]['subjectName'] = picked);
    }
  }

  // â”€â”€ Teacher picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _pickTeacher(BuildContext context, int index) async {
    final slot = _daySlots[_activeDay]![index];
    final current = slot['teacherId'] as String;
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TeacherPickerSheet(
        teachers: _teachers,
        currentId: current,
        isLoading: _loadingTeachers,
      ),
    );
    if (picked != null) {
      setState(() {
        _daySlots[_activeDay]![index]['teacherName'] =
            picked['name']?.toString() ?? '';
        _daySlots[_activeDay]![index]['teacherId'] =
            picked['teacherId']?.toString() ?? '';
      });
    }
  }

  // â”€â”€ Validation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  String? _validate() {
    bool hasAtLeastOne = false;
    for (final day in _days) {
      for (int i = 0; i < _daySlots[day]!.length; i++) {
        final slot = _daySlots[day]![i];
        final start = (slot['startTime'] as TextEditingController).text.trim();
        final end = (slot['endTime'] as TextEditingController).text.trim();
        final type = slot['type'] as String;
        final isClass = type == 'class' || type == 'lab';

        if (start.isEmpty)
          return '$day Period ${i + 1}: Start time is required.';
        if (end.isEmpty) return '$day Period ${i + 1}: End time is required.';
        if (isClass && (slot['subjectName'] as String).isEmpty)
          return '$day Period ${i + 1}: Please select a subject.';
        if (isClass && (slot['teacherId'] as String).isEmpty)
          return '$day Period ${i + 1}: Please select a teacher.';

        hasAtLeastOne = true;
      }
    }
    if (!hasAtLeastOne) return 'Add at least one period before creating.';
    return null;
  }

  // â”€â”€ Build payload â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<Map<String, dynamic>> _buildSlotsPayload() {
    final List<Map<String, dynamic>> result = [];
    for (final day in _days) {
      int pNum = 1;
      for (final slot in _daySlots[day]!) {
        final type = slot['type'] as String;
        final isClass = type == 'class' || type == 'lab';
        final entry = <String, dynamic>{
          'day': day,
          'periodNumber': pNum,
          'startTime': (slot['startTime'] as TextEditingController).text.trim(),
          'endTime': (slot['endTime'] as TextEditingController).text.trim(),
          'type': type,
        };
        if (isClass) {
          entry['subjectName'] = slot['subjectName']?.toString() ?? '';
          entry['teacherName'] = slot['teacherName']?.toString() ?? '';
          entry['teacherId'] = slot['teacherId']?.toString() ?? '';
        }
        result.add(entry);
        pNum++;
      }
    }
    return result;
  }

  // â”€â”€ Submit â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      _snack(error, isError: true);
      return;
    }

    // Guard: name must be resolved
    if (_resolvedCreatedByName.isEmpty) {
      _snack(
        'Teacher name not resolved yet. Please wait a moment.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'classId': widget.classId,
      'orgId': widget.orgId,
      'createdBy': widget.teacherId,
      'createdByName': _resolvedCreatedByName,
      'academicYear': _yearCtrl.text.trim(),
      'slots': _buildSlotsPayload(),
    };

    debugPrint(
      '[Timetable] POST payload:\n'
      '${const JsonEncoder.withIndent('  ').convert(payload)}',
    );

    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/timetable/create'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      debugPrint('[Timetable] Response status: ${res.statusCode}');
      debugPrint('[Timetable] Response body: ${res.body}');

      setState(() => _isSaving = false);

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        widget.onCreated();
        _snack('Timetable created successfully!');
      } else {
        String errMsg = 'Server error (${res.statusCode})';
        try {
          final b = jsonDecode(res.body);
          errMsg = b['message']?.toString() ?? b['error']?.toString() ?? errMsg;
        } catch (_) {
          errMsg = res.body.isNotEmpty
              ? res.body.substring(
                  0,
                  res.body.length > 120 ? 120 : res.body.length,
                )
              : errMsg;
        }
        _snack(errMsg, isError: true);
      }
    } catch (e) {
      debugPrint('[Timetable] Exception: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      _snack('Network error: $e', isError: true);
    }
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
        duration: Duration(seconds: 4),
      ),
    );
  }

  // â”€â”€ Type helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _sheetHandle(),
          _sheetHeader(context),

          // â”€â”€ Resolved name indicator â”€â”€
          if (_resolvedCreatedByName.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.orange[50],
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.orange[600],
                    ),
                  ),
                  SizedBox(width: 8),
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
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              color: Colors.teal[50],
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 13, color: _accent),
                  SizedBox(width: 6),
                  Text(
                    'Creating as: $_resolvedCreatedByName',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Academic year
          Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('ACADEMIC YEAR', required: true),
                SizedBox(height: 5),
                TextField(
                  controller: _yearCtrl,
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: _fieldDeco(
                    hint: '2025-26',
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
              ],
            ),
          ),

          _daySelector(),
          SizedBox(height: 4),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text(
                  '$_activeDay - '
                  '${_daySlots[_activeDay]!.length} periods',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: _addSlot,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Add Period',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPad),
              child: _daySlots[_activeDay]!.isEmpty
                  ? _emptyDay()
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(14, 0, 14, 100),
                      itemCount: _daySlots[_activeDay]!.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _slotCard(ctx, i),
                    ),
            ),
          ),

          _submitBar(),
        ],
      ),
    );
  }

  // ——— Slot card ——————————————————————————————————————————

  Widget _slotCard(BuildContext context, int index) {
    final slot = _daySlots[_activeDay]![index];
    final type = slot['type'] as String;
    final color = _typeColor(type);
    final isClass = type == 'class' || type == 'lab';
    final startCtrl = slot['startTime'] as TextEditingController;
    final endCtrl = slot['endTime'] as TextEditingController;
    final subject = slot['subjectName'] as String;
    final tName = slot['teacherName'] as String;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              border: Border(
                bottom: BorderSide(color: color.withOpacity(0.15)),
              ),
            ),
            child: Row(
              children: [
                Icon(_typeIcon(type), size: 13, color: color),
                SizedBox(width: 6),
                Text(
                  'Period ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: color,
                  ),
                ),
                Spacer(),
                _typeDropdown(slot, color),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeSlot(index),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Card body
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _timeField(
                        context: context,
                        ctrl: startCtrl,
                        label: 'START',
                        hint: '09:00',
                        required: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 18,
                      ),
                      child: Text(
                        '-',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _timeField(
                        context: context,
                        ctrl: endCtrl,
                        label: 'END',
                        hint: '10:00',
                        required: true,
                      ),
                    ),
                  ],
                ),

                if (isClass) ...[
                  SizedBox(height: 10),
                  _label('SUBJECT', required: true),
                  SizedBox(height: 5),
                  _pickerTile(
                    icon: Icons.menu_book_rounded,
                    value: subject.isEmpty ? null : subject,
                    placeholder: widget.classSubjects.isEmpty
                        ? 'No subjects in classroom'
                        : 'Select subject',
                    onTap: widget.classSubjects.isEmpty
                        ? null
                        : () => _pickSubject(context, index),
                  ),
                  SizedBox(height: 10),
                  _label('TEACHER', required: true),
                  SizedBox(height: 5),
                  _pickerTile(
                    icon: Icons.person_rounded,
                    value: tName.isEmpty ? null : tName,
                    placeholder: _loadingTeachers
                        ? 'Loading teachers...'
                        : 'Select teacher',
                    onTap: _loadingTeachers
                        ? null
                        : () => _pickTeacher(context, index),
                    trailing: _loadingTeachers
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: _accent,
                            ),
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ——— Picker tile ————————————————————————————————————————

  Widget _pickerTile({
    required IconData icon,
    required String placeholder,
    String? value,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: hasValue ? _accent.withOpacity(0.04) : Colors.grey[50],
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: hasValue ? _accent.withOpacity(0.35) : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: hasValue
                  ? _accent
                  : AppColors.textSecondary.withOpacity(0.5),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? placeholder,
                style: TextStyle(
                  fontSize: 13,
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withOpacity(0.5),
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: hasValue ? _accent : AppColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }

  // ——— Time field —————————————————————————————————————————

  Widget _timeField({
    required BuildContext context,
    required TextEditingController ctrl,
    required String label,
    required String hint,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: required),
        SizedBox(height: 5),
        GestureDetector(
          onTap: () => _pickTime(context, ctrl),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: ctrl,
            builder: (_, val, __) {
              final hasVal = val.text.isNotEmpty;
              String displayTime = hint;
              if (hasVal) {
                try {
                  final p = val.text.split(':');
                  displayTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])).format(context);
                } catch (_) {
                  displayTime = val.text;
                }
              }
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: hasVal ? _accent.withOpacity(0.04) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: hasVal
                        ? _accent.withOpacity(0.35)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: hasVal
                          ? _accent
                          : AppColors.textSecondary.withOpacity(0.5),
                    ),
                    SizedBox(width: 6),
                    Text(
                      displayTime,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasVal
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withOpacity(0.5),
                        fontWeight: hasVal
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ——— Type dropdown —————————————————————————————————————

  Widget _typeDropdown(Map<String, dynamic> slot, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: slot['type'] as String,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: color),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(3),
          items: _types
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcon(t), size: 12, color: _typeColor(t)),
                      SizedBox(width: 5),
                      Text(
                        t.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _typeColor(t),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => slot['type'] = val);
          },
        ),
      ),
    );
  }

  // ——— Shared helpers —————————————————————————————————————

  Widget _label(String text, {bool required = false}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
      if (required)
        Text(
          ' *',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.red[600],
          ),
        ),
    ],
  );

  InputDecoration _fieldDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.5),
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, size: 14, color: _accent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide(color: _accent.withOpacity(0.5), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    );
  }

  Widget _sheetHandle() => Center(
    child: Container(
      margin: EdgeInsets.only(top: 10, bottom: 6),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _sheetHeader(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_accent, _accent.withOpacity(0.75)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(
            Icons.calendar_month_rounded,
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
                'Create Timetable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Fill periods for each day',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
          ),
        ),
      ],
    ),
  );

  Widget _daySelector() {
    return Container(
      height: 38,
      margin: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        children: _days.map((day) {
          final isActive = _activeDay == day;
          final count = _daySlots[day]!.length;
          return GestureDetector(
            onTap: () => setState(() => _activeDay = day),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? _accent : Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isActive ? _accent : Colors.grey[200]!,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _accent.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.substring(0, 3),
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  if (count > 0) ...[
                    SizedBox(width: 5),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withOpacity(0.3)
                            : _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isActive ? Colors.white : _accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyDay() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.add_circle_outline_rounded,
          size: 40,
          color: Colors.grey[300],
        ),
        SizedBox(height: 10),
        Text(
          'No periods for $_activeDay',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _addSlot,
          child: Text(
            '+ Add period',
            style: TextStyle(
              color: _accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _submitBar() {
    final total = _daySlots.values.fold(0, (s, l) => s + l.length);
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 24 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$total total periods',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'across all days',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: (_isSaving || _resolvedCreatedByName.isEmpty)
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _accent.withOpacity(0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : _resolvedCreatedByName.isEmpty
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 1.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Resolving...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Create Timetable',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// SUBJECT PICKER SHEET
// ---------------------------------------------------------

class _SubjectPickerSheet extends StatefulWidget {
  final String current;
  final List<String> subjects;

  const _SubjectPickerSheet({required this.current, required this.subjects});

  @override
  __SubjectPickerSheetState createState() => __SubjectPickerSheetState();
}

class __SubjectPickerSheetState extends State<_SubjectPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.subjects;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.subjects
            : widget.subjects
                  .where((s) => s.toLowerCase().contains(q))
                  .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: _accent,
                    size: 16,
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Subject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.subjects.length} subjects',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search subject...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _accent,
                  size: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(
                    color: _accent.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey[100]),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 36,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No subjects found',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(0, 6, 0, 16 + MediaQuery.of(context).padding.bottom),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final subj = _filtered[i];
                      final isSel = subj == widget.current;
                      return InkWell(
                        onTap: () => Navigator.pop(context, subj),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 3,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? _accent.withOpacity(0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(3),
                            border: isSel
                                ? Border.all(color: _accent.withOpacity(0.3))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? _accent.withOpacity(0.15)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 15,
                                  color: isSel ? _accent : Colors.grey[400],
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  subj,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSel
                                        ? _accent
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSel)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _accent,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// TEACHER PICKER SHEET
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TeacherPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> teachers;
  final String currentId;
  final bool isLoading;

  const _TeacherPickerSheet({
    required this.teachers,
    required this.currentId,
    required this.isLoading,
  });

  @override
  __TeacherPickerSheetState createState() => __TeacherPickerSheetState();
}

class __TeacherPickerSheetState extends State<_TeacherPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.teachers;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.teachers
            : widget.teachers
                  .where(
                    (t) =>
                        (t['name']?.toString() ?? '').toLowerCase().contains(
                          q,
                        ) ||
                        (t['email']?.toString() ?? '').toLowerCase().contains(
                          q,
                        ),
                  )
                  .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(Icons.person_rounded, color: _accent, size: 16),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Teacher',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.teachers.length} teachers available',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _accent,
                  size: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(
                    color: _accent.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey[100]),
          Expanded(
            child: widget.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                      strokeWidth: 2.5,
                    ),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off_rounded,
                          size: 36,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No teachers found',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(0, 6, 0, 16 + MediaQuery.of(context).padding.bottom),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final t = _filtered[i];
                      final id = t['teacherId']?.toString() ?? '';
                      final name = t['name']?.toString() ?? '';
                      final email = t['email']?.toString() ?? '';
                      final isSel = id == widget.currentId;
                      final initials = name.isNotEmpty
                          ? name
                                .trim()
                                .split(' ')
                                .take(2)
                                .map((w) => w[0].toUpperCase())
                                .join()
                          : '?';

                      return InkWell(
                        onTap: () => Navigator.pop(context, t),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 3,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? _accent.withOpacity(0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(3),
                            border: isSel
                                ? Border.all(color: _accent.withOpacity(0.3))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? _accent
                                      : _accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      color: isSel ? Colors.white : _accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
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
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSel
                                            ? _accent
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (email.isNotEmpty) ...[
                                      SizedBox(height: 2),
                                      Text(
                                        email,
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
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _accent,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

