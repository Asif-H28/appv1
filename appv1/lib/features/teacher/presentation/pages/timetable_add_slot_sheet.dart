import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import '../../../../../core/constants/app_colors.dart';

const Color _addAccent = Colors.teal;

class TimetableAddSlotSheet extends StatefulWidget {
  final String timetableId;
  final String initialDay;
  final int nextPeriodNumber;
  final List<String> classSubjects;
  final String orgId;
  final VoidCallback onSaved;

  const TimetableAddSlotSheet({
    required this.timetableId,
    required this.initialDay,
    required this.nextPeriodNumber,
    required this.classSubjects,
    required this.orgId,
    required this.onSaved,
  });

  @override
  _TimetableAddSlotSheetState createState() => _TimetableAddSlotSheetState();
}

class _TimetableAddSlotSheetState extends State<TimetableAddSlotSheet> {
  late String _selectedDay;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _subjectCtrl;
  String _selectedType = 'class';
  String _selectedTeacherName = '';
  String _selectedTeacherId = '';
  bool _isSaving = false;
  bool _loadingTeachers = true;
  List<Map<String, dynamic>> _teachers = [];

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

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay;
    _startCtrl = TextEditingController();
    _endCtrl = TextEditingController();
    _subjectCtrl = TextEditingController();
    _fetchTeachers();
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTeachers() async {
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
        setState(() {
          _teachers = list.map((t) => t as Map<String, dynamic>).toList();
          _loadingTeachers = false;
        });
      } else {
        setState(() => _loadingTeachers = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTeachers = false);
    }
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
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
              primary: _addAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        ctrl.text =
            '${picked.hour.toString().padLeft(2, '0')}'
            ':${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickTeacher() async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TeacherPickerSheet(
        teachers: _teachers,
        currentId: _selectedTeacherId,
        isLoading: _loadingTeachers,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedTeacherName = picked['name']?.toString() ?? '';
        _selectedTeacherId = picked['teacherId']?.toString() ?? '';
      });
    }
  }

  Future<void> _pickSubject() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SubjectPickerSheet(
        subjects: widget.classSubjects,
        current: _subjectCtrl.text,
      ),
    );
    if (picked != null) {
      setState(() => _subjectCtrl.text = picked);
    }
  }

  String? _validate() {
    if (_startCtrl.text.trim().isEmpty) return 'Start time is required.';
    if (_endCtrl.text.trim().isEmpty) return 'End time is required.';
    final isClass = _selectedType == 'class' || _selectedType == 'lab';
    if (isClass && _subjectCtrl.text.trim().isEmpty)
      return 'Subject is required.';
    if (isClass && _selectedTeacherId.isEmpty) return 'Teacher is required.';
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      _snack(err, isError: true);
      return;
    }
    setState(() => _isSaving = true);

    final isClass = _selectedType == 'class' || _selectedType == 'lab';
    final payload = <String, dynamic>{
      'day': _selectedDay,
      'periodNumber': widget.nextPeriodNumber,
      'startTime': _startCtrl.text.trim(),
      'endTime': _endCtrl.text.trim(),
      'type': _selectedType,
      if (isClass) ...{
        'subjectName': _subjectCtrl.text.trim(),
        'teacherName': _selectedTeacherName,
        'teacherId': _selectedTeacherId,
      },
    };

    debugPrint('[AddSlot] POST: ${jsonEncode(payload)}');

    try {
      final res = await http.post(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/timetable/${widget.timetableId}/slot',
        ),
        headers: await ApiService.getHeaders(),
        body: jsonEncode(payload),
      );
      debugPrint('[AddSlot] ${res.statusCode} ${res.body}');
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        widget.onSaved();
        _snack('Period added!');
      } else {
        String msg = 'Failed (${res.statusCode})';
        try {
          final b = jsonDecode(res.body);
          msg = b['message']?.toString() ?? b['error']?.toString() ?? msg;
        } catch (_) {}
        _snack(msg, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _snack('Network error: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) =>
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

  Widget _label(String t, {bool required = false}) => Padding(
    padding: EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t,
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
    ),
  );

  Widget _timeTile(TextEditingController ctrl) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: ctrl,
        builder: (_, val, __) {
          final has = val.text.isNotEmpty;
          String displayTime = '--:--';
          if (has) {
            try {
              final p = val.text.split(':');
              displayTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])).format(context);
            } catch (_) {
              displayTime = val.text;
            }
          }
          return GestureDetector(
            onTap: () => _pickTime(ctrl),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: has ? _addAccent.withOpacity(0.04) : Colors.grey[50],
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: has ? _addAccent.withOpacity(0.35) : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: has
                        ? _addAccent
                        : AppColors.textSecondary.withOpacity(0.4),
                  ),
                  SizedBox(width: 6),
                  Text(
                    displayTime,
                    style: TextStyle(
                      fontSize: 13,
                      color: has
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withOpacity(0.4),
                      fontWeight: has ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _pickerTile({
    required IconData icon,
    required String placeholder,
    String? value,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final has = value != null && value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: has ? _addAccent.withOpacity(0.04) : Colors.grey[50],
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: has ? _addAccent.withOpacity(0.35) : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: has
                  ? _addAccent
                  : AppColors.textSecondary.withOpacity(0.5),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? placeholder,
                style: TextStyle(
                  fontSize: 13,
                  color: has
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withOpacity(0.5),
                  fontWeight: has ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: has ? _addAccent : AppColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final isClass = _selectedType == 'class' || _selectedType == 'lab';
    final color = _typeColor(_selectedType);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_addAccent, _addAccent.withOpacity(0.75)],
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
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 16),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Period',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'P${widget.nextPeriodNumber}'
                        ' • $_selectedDay',
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
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Flexible(
            child: SingleChildScrollView(
              // After
              padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day selector
                _label('DAY', required: true),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _days.map((d) {
                      final isSel = _selectedDay == d;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDay = d),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 150),
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSel ? _addAccent : Colors.white,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: isSel ? _addAccent : Colors.grey[200]!,
                            ),
                          ),
                          child: Text(
                            d.substring(0, 3),
                            style: TextStyle(
                              color: isSel
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16),

                // Type selector
                _label('PERIOD TYPE', required: true),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _types.map((t) {
                      final isSel = _selectedType == t;
                      final c = _typeColor(t);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = t),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 160),
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSel ? c : c.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: isSel ? c : c.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _typeIcon(t),
                                size: 13,
                                color: isSel ? Colors.white : c,
                              ),
                              SizedBox(width: 5),
                              Text(
                                t.toUpperCase(),
                                style: TextStyle(
                                  color: isSel ? Colors.white : c,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16),

                // Times
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_label('START TIME', required: true), _timeTile(_startCtrl)],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 16, 10, 0),
                      child: Text(
                        '-',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_label('END TIME', required: true), _timeTile(_endCtrl)],
                      ),
                    ),
                  ],
                ),

                if (isClass) ...[
                  SizedBox(height: 16),
                  _label('SUBJECT', required: true),
                  _pickerTile(
                    icon: Icons.menu_book_rounded,
                    placeholder: widget.classSubjects.isEmpty
                        ? 'No subjects available'
                        : 'Select subject',
                    value: _subjectCtrl.text.isEmpty ? null : _subjectCtrl.text,
                    onTap: widget.classSubjects.isEmpty ? null : _pickSubject,
                  ),
                  SizedBox(height: 14),
                  _label('TEACHER', required: true),
                  _pickerTile(
                    icon: Icons.person_rounded,
                    placeholder: _loadingTeachers
                        ? 'Loading teachers...'
                        : 'Select teacher',
                    value: _selectedTeacherName.isEmpty
                        ? null
                        : _selectedTeacherName,
                    onTap: _loadingTeachers ? null : _pickTeacher,
                    trailing: _loadingTeachers
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: _addAccent,
                            ),
                          )
                        : null,
                  ),
                ],

                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: color.withOpacity(0.4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, size: 17),
                              SizedBox(width: 8),
                              Text(
                                'Add Period',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// SUBJECT PICKER
// ---------------------------------------------------------

class _SubjectPickerSheet extends StatefulWidget {
  final List<String> subjects;
  final String current;
  const _SubjectPickerSheet({required this.subjects, required this.current});

  @override
  __SubjectPickerSheetState createState() => __SubjectPickerSheetState();
}

class __SubjectPickerSheetState extends State<_SubjectPickerSheet> {
  final _search = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.subjects;
    _search.addListener(() {
      final q = _search.text.toLowerCase();
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
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
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
            padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Text(
                  'Select Subject',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _addAccent,
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
                    color: _addAccent.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey[100]),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No subjects found',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final s = _filtered[i];
                      final sel = s == widget.current;
                      return InkWell(
                        onTap: () => Navigator.pop(context, s),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 14,
                                color: sel ? _addAccent : Colors.grey[400],
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: sel
                                        ? _addAccent
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (sel)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _addAccent,
                                  size: 17,
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
// TEACHER PICKER
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
  final _search = TextEditingController();
  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.teachers;
    _search.addListener(() {
      final q = _search.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.teachers
            : widget.teachers
                  .where(
                    (t) =>
                        (t['name']?.toString() ?? '').toLowerCase().contains(q),
                  )
                  .toList();
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
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
            padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Text(
                  'Select Teacher',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _addAccent,
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
                    color: _addAccent.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey[100]),
          Expanded(
            child: widget.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: _addAccent,
                      strokeWidth: 2.5,
                    ),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No teachers found',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final t = _filtered[i];
                      final id = t['teacherId']?.toString() ?? '';
                      final name = t['name']?.toString() ?? '';
                      final sel = id == widget.currentId;
                      final initials = name.isNotEmpty
                          ? name
                                .trim()
                                .split(' ')
                                .take(2)
                                .map(
                                  (w) => w.isNotEmpty ? w[0].toUpperCase() : '',
                                )
                                .join()
                          : '?';
                      return InkWell(
                        onTap: () => Navigator.pop(context, t),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? _addAccent
                                      : _addAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      color: sel ? Colors.white : _addAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: sel
                                        ? _addAccent
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (sel)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _addAccent,
                                  size: 17,
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

