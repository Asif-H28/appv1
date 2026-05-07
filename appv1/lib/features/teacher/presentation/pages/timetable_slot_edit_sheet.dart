import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/constants/app_colors.dart';

const Color _editAccent = Colors.teal;

class TimetableSlotEditSheet extends StatefulWidget {
  final String day;
  final Map<String, dynamic> slot;
  final String timetableId;
  final String orgId;
  final List<String> classSubjects;
  final VoidCallback onSaved;

  const TimetableSlotEditSheet({
    required this.day,
    required this.slot,
    required this.timetableId,
    required this.orgId,
    required this.classSubjects,
    required this.onSaved,
  });

  @override
  _TimetableSlotEditSheetState createState() => _TimetableSlotEditSheetState();
}

class _TimetableSlotEditSheetState extends State<TimetableSlotEditSheet> {
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _subjectCtrl;
  late String _selectedType;

  String _selectedTeacherName = '';
  String _selectedTeacherId = '';

  bool _isSaving = false;
  bool _loadingTeachers = true;
  List<Map<String, dynamic>> _teachers = [];

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
    _startCtrl = TextEditingController(
      text: widget.slot['startTime']?.toString() ?? '',
    );
    _endCtrl = TextEditingController(
      text: widget.slot['endTime']?.toString() ?? '',
    );
    _subjectCtrl = TextEditingController(
      text: widget.slot['subjectName']?.toString() ?? '',
    );
    _selectedType = widget.slot['type']?.toString() ?? 'class';

    // Pre-fill teacher from existing slot
    _selectedTeacherName = widget.slot['teacherName']?.toString() ?? '';
    _selectedTeacherId = widget.slot['teacherId']?.toString() ?? '';

    _fetchTeachers();
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  // â”€â”€ Fetch teachers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _fetchTeachers() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/teacher/org/${widget.orgId}'),
        headers: {'Content-Type': 'application/json'},
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

  // â”€â”€ Time picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: _editAccent,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
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

  // â”€â”€ Subject picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Teacher picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Validate â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  String? _validate() {
    if (_startCtrl.text.trim().isEmpty) return 'Start time is required.';
    if (_endCtrl.text.trim().isEmpty) return 'End time is required.';
    final isClass = _selectedType == 'class' || _selectedType == 'lab';
    if (isClass && _subjectCtrl.text.trim().isEmpty)
      return 'Subject is required.';
    if (isClass && _selectedTeacherId.isEmpty) return 'Teacher is required.';
    return null;
  }

  // â”€â”€ Save â€” PUT /slot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      _snack(err, isError: true);
      return;
    }
    setState(() => _isSaving = true);

    final isClass = _selectedType == 'class' || _selectedType == 'lab';

    final payload = <String, dynamic>{
      'day': widget.day,
      'periodNumber': widget.slot['periodNumber'],
      'startTime': _startCtrl.text.trim(),
      'endTime': _endCtrl.text.trim(),
      'type': _selectedType,
      if (isClass) ...{
        'subjectName': _subjectCtrl.text.trim(),
        'teacherName': _selectedTeacherName,
        'teacherId': _selectedTeacherId,
      },
    };

    debugPrint('[SlotEdit] PUT: ${jsonEncode(payload)}');

    try {
      final res = await http.put(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/timetable/${widget.timetableId}/slot',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      debugPrint('[SlotEdit] ${res.statusCode} ${res.body}');
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        widget.onSaved();
        _snack('Period updated!');
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

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
          return GestureDetector(
            onTap: () => _pickTime(ctrl),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: has ? _editAccent.withOpacity(0.04) : Colors.grey[50],
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: has
                      ? _editAccent.withOpacity(0.35)
                      : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: has
                        ? _editAccent
                        : AppColors.textSecondary.withOpacity(0.4),
                  ),
                  SizedBox(width: 6),
                  Text(
                    has ? val.text : '--:--',
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

  // Shared picker tile â€” same style as Add sheet
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
          color: has ? _editAccent.withOpacity(0.04) : Colors.grey[50],
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: has ? _editAccent.withOpacity(0.35) : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: has
                  ? _editAccent
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
                  color: has ? _editAccent : AppColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final periodNum = widget.slot['periodNumber']?.toString() ?? '';
    final isClass = _selectedType == 'class' || _selectedType == 'lab';
    final color = _typeColor(_selectedType);

    return Container(
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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
                colors: [_editAccent, _editAccent.withOpacity(0.75)],
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
                    Icons.edit_rounded,
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
                        'Edit Period $periodNum'
                        ' ${widget.day}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Update time, type or subject',
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
          SingleChildScrollView(
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
                // ── Type chips ──
                _label('PERIOD TYPE', required: true),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _types.map((t) {
                      final isSel = _selectedType == t;
                      final c = _typeColor(t);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = t;
                            // Clear teacher/subject
                            // when switching away
                            // from class/lab
                            final nowClass = t == 'class' || t == 'lab';
                            if (!nowClass) {
                              _subjectCtrl.clear();
                              _selectedTeacherId = '';
                              _selectedTeacherName = '';
                            }
                          });
                        },
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

                // â”€â”€ Times â”€â”€
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('START TIME', required: true),
                          _timeTile(_startCtrl),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 16, 10, 0),
                      child: Text(
                        'To',
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
                        children: [
                          _label('END TIME', required: true),
                          _timeTile(_endCtrl),
                        ],
                      ),
                    ),
                  ],
                ),

                // â”€â”€ Subject + Teacher (class/lab only) â”€â”€
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
                              color: _editAccent,
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
                              Icon(Icons.save_rounded, size: 17),
                              SizedBox(width: 8),
                              Text(
                                'Save Changes',
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
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// SUBJECT PICKER  (identical to Add sheet)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                hintText: 'Search subjects...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _editAccent,
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
                    color: _editAccent.withOpacity(0.5),
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
                                color: sel ? _editAccent : Colors.grey[400],
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
                                        ? _editAccent
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (sel)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _editAccent,
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
// TEACHER PICKER  (identical to Add sheet)
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
                hintText: 'Search teachers...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _editAccent,
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
                    color: _editAccent.withOpacity(0.5),
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
                      color: _editAccent,
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
                                      ? _editAccent
                                      : _editAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      color: sel ? Colors.white : _editAccent,
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
                                        ? _editAccent
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (sel)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _editAccent,
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
