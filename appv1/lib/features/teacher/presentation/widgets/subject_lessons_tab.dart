import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

class SubjectLessonsTab extends StatefulWidget {
  final String classId;
  final List<Map<String, dynamic>> subjects;
  final VoidCallback onRefresh;

  const SubjectLessonsTab({
    required this.classId,
    required this.subjects,
    required this.onRefresh,
  });

  @override
  _SubjectLessonsTabState createState() => _SubjectLessonsTabState();
}

class _SubjectLessonsTabState extends State<SubjectLessonsTab> {
  static const Color _accent = Colors.teal;
  final Map<String, bool> _deletingSubject = {};
  final Map<String, bool> _deletingLesson = {};

  // â”€â”€ Track which subjects are expanded â”€â”€
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    // Only first subject open by default on first load
    for (var i = 0; i < widget.subjects.length; i++) {
      final name = widget.subjects[i]['name']?.toString() ?? '$i';
      _expanded[name] = i == 0;
    }
  }

  @override
  void didUpdateWidget(SubjectLessonsTab old) {
    super.didUpdateWidget(old);
    // When subjects list refreshes, preserve existing expanded state.
    // Only initialize state for newly added subjects (not in _expanded yet).
    for (var i = 0; i < widget.subjects.length; i++) {
      final name = widget.subjects[i]['name']?.toString() ?? '$i';
      if (!_expanded.containsKey(name)) {
        _expanded[name] = false; // new subjects start collapsed
      }
    }
    // Clean up removed subjects
    final currentNames = widget.subjects
        .map((s) => s['name']?.toString() ?? '')
        .toSet();
    _expanded.removeWhere((key, _) => !currentNames.contains(key));
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // API CALLS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _toggleLesson(
    String subjectName,
    String lessonName,
    bool current,
  ) async {
    try {
      await http.put(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/classroom/${widget.classId}/lessons/status',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subjectName': subjectName,
          'lessonName': lessonName,
          'completed': !current,
        }),
      );
      widget.onRefresh();
    } catch (_) {}
  }

  Future<void> _deleteSubject(String subjectName) async {
    setState(() => _deletingSubject[subjectName] = true);
    try {
      final encoded = Uri.encodeComponent(subjectName);
      final response = await http.delete(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/classroom/${widget.classId}/subjects/$encoded',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      setState(() => _deletingSubject.remove(subjectName));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _expanded.remove(subjectName);
        widget.onRefresh();
        _snack('Subject deleted.', Colors.green[600]!);
      } else {
        _snack('Failed to delete subject.', Colors.red[600]!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingSubject.remove(subjectName));
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  Future<void> _deleteLesson(String subjectName, String lessonName) async {
    final key = '$subjectName|$lessonName';
    setState(() => _deletingLesson[key] = true);
    try {
      final encodedSub = Uri.encodeComponent(subjectName);
      final encodedLes = Uri.encodeComponent(lessonName);
      final response = await http.delete(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/classroom/${widget.classId}/lessons/$encodedSub/$encodedLes',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      setState(() => _deletingLesson.remove(key));
      if (response.statusCode == 200 || response.statusCode == 204) {
        widget.onRefresh();
        _snack('Lesson deleted.', Colors.green[600]!);
      } else {
        _snack('Failed to delete lesson.', Colors.red[600]!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingLesson.remove(key));
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  Future<void> _renameSubject(String oldName, String newName) async {
    if (newName.trim().isEmpty || newName.trim() == oldName) return;
    // Preserve expanded state under new name
    final wasExpanded = _expanded[oldName] ?? false;
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/classroom/${widget.classId}/subjects',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'oldName': oldName, 'newName': newName.trim()}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        _expanded.remove(oldName);
        _expanded[newName.trim()] = wasExpanded;
        widget.onRefresh();
        _snack('Subject renamed.', Colors.green[600]!);
      } else {
        _snack('Failed to rename subject.', Colors.red[600]!);
      }
    } catch (_) {
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  Future<void> _renameLesson(
    String subjectName,
    String oldLesson,
    String newLesson,
  ) async {
    if (newLesson.trim().isEmpty || newLesson.trim() == oldLesson) return;
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/classroom/${widget.classId}/lessons',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subjectName': subjectName,
          'oldLessonName': oldLesson,
          'newLessonName': newLesson.trim(),
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        widget.onRefresh();
        _snack('Lesson renamed.', Colors.green[600]!);
      } else {
        _snack('Failed to rename lesson.', Colors.red[600]!);
      }
    } catch (_) {
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // DIALOGS & SHEETS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _confirmDeleteSubject(String subjectName) {
    _showConfirmDialog(
      icon: Icons.delete_rounded,
      title: 'Delete Subject',
      message:
          'Delete "$subjectName" and all its lessons? This cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () => _deleteSubject(subjectName),
    );
  }

  void _confirmDeleteLesson(String subjectName, String lessonName) {
    _showConfirmDialog(
      icon: Icons.delete_rounded,
      title: 'Delete Lesson',
      message: 'Delete "$lessonName"? This cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () => _deleteLesson(subjectName, lessonName),
    );
  }

  void _showConfirmDialog({
    required IconData icon,
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        titlePadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        contentPadding: EdgeInsets.fromLTRB(16, 10, 16, 0),
        actionsPadding: EdgeInsets.fromLTRB(16, 8, 16, 14),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(icon, color: Colors.red[600], size: 15),
            ),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: Theme(
                    data: ThemeData(
                      colorScheme: ColorScheme.light(
                        primary: Colors.red[600]!,
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRenameSubjectSheet(String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheet(
        ctx: ctx,
        icon: Icons.drive_file_rename_outline_rounded,
        title: 'Rename Subject',
        subtitle: '"$currentName"',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetLabel('New Name'),
            SizedBox(height: 6),
            _sheetInput(ctrl, 'Subject name', Icons.menu_book_rounded),
            SizedBox(height: 18),
            _sheetSaveBtn('Rename', () async {
              Navigator.pop(ctx);
              await _renameSubject(currentName, ctrl.text);
            }),
          ],
        ),
      ),
    );
  }

  void _showRenameLessonSheet(String subjectName, String currentLesson) {
    final ctrl = TextEditingController(text: currentLesson);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheet(
        ctx: ctx,
        icon: Icons.drive_file_rename_outline_rounded,
        title: 'Rename Lesson',
        subtitle: 'in "$subjectName"',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetLabel('New Name'),
            SizedBox(height: 6),
            _sheetInput(ctrl, 'Lesson name', Icons.book_outlined),
            SizedBox(height: 18),
            _sheetSaveBtn('Rename', () async {
              Navigator.pop(ctx);
              await _renameLesson(subjectName, currentLesson, ctrl.text);
            }),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectSheet() {
    final nameCtrl = TextEditingController();
    final lessonsCtrl = [TextEditingController()];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _buildSheet(
          ctx: ctx,
          icon: Icons.menu_book_rounded,
          title: 'Add Subject',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetLabel('Subject Name'),
              SizedBox(height: 6),
              _sheetInput(
                nameCtrl,
                'e.g. Mathematics',
                Icons.menu_book_rounded,
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  _sheetLabel('Lessons'),
                  Spacer(),
                  GestureDetector(
                    onTap: () => setSheetState(
                      () => lessonsCtrl.add(TextEditingController()),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: _accent.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: _accent, size: 12),
                          SizedBox(width: 3),
                          Text(
                            'Add Lesson',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              ...lessonsCtrl.asMap().entries.map(
                (e) => Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accent.withOpacity(0.5),
                        ),
                      ),
                      Expanded(
                        child: _sheetInput(
                          e.value,
                          'Lesson ${e.key + 1}',
                          Icons.book_outlined,
                        ),
                      ),
                      if (lessonsCtrl.length > 1)
                        GestureDetector(
                          onTap: () =>
                              setSheetState(() => lessonsCtrl.removeAt(e.key)),
                          child: Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 18),
              _sheetSaveBtn('Add Subject', () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await http.post(
                  Uri.parse(
                    '${ApiConstants.apiBaseUrl}/classroom/${widget.classId}/subjects',
                  ),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'name': nameCtrl.text.trim(),
                    'lessons': lessonsCtrl
                        .map((c) => {'name': c.text.trim(), 'completed': false})
                        .where((l) => (l['name'] as String).isNotEmpty)
                        .toList(),
                  }),
                );
                widget.onRefresh();
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLessonSheet(String subjectName) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheet(
        ctx: ctx,
        icon: Icons.book_outlined,
        title: 'Add Lesson',
        subtitle: 'to "$subjectName"',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetLabel('Lesson Name'),
            SizedBox(height: 6),
            _sheetInput(ctrl, 'e.g. Algebra', Icons.book_outlined),
            SizedBox(height: 18),
            _sheetSaveBtn('Add Lesson', () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await http.post(
                Uri.parse(
                  '${ApiConstants.apiBaseUrl}/classroom/${widget.classId}/lessons',
                ),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'subjectName': subjectName,
                  'lessonName': ctrl.text.trim(),
                }),
              );
              widget.onRefresh();
            }),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // SHEET HELPERS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSheet({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(ctx).padding.bottom + 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(icon, color: _accent, size: 16),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _sheetHandle() => Center(
    child: Container(
      width: 36,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _sheetLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.3,
    ),
  );

  Widget _sheetInput(TextEditingController ctrl, String hint, IconData icon) =>
      TextField(
        controller: ctrl,
        cursorColor: _accent,
        style: TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.5),
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: _accent, size: 16),
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
          fillColor: Colors.white,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );

  Widget _sheetSaveBtn(String label, VoidCallback onTap) => Theme(
    data: ThemeData(
      colorScheme: ColorScheme.light(primary: _accent, onPrimary: Colors.white),
    ),
    child: SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BUILD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) return _buildEmpty();

    return ListView(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // â”€â”€ Action bar â”€â”€
        Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, color: _accent, size: 12),
                    SizedBox(width: 5),
                    Text(
                      '${widget.subjects.length} Subject${widget.subjects.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: _showAddSubjectSheet,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 5),
                      Text(
                        'Add Subject',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // â”€â”€ Subject cards â”€â”€
        ...widget.subjects.map((sub) {
          final subName = sub['name']?.toString() ?? 'Subject';
          final lessons = sub['lessons'] as List? ?? [];
          final total = lessons.length;
          final completed = lessons
              .where((l) => (l as Map)['completed'] == true)
              .length;
          final progress = total > 0 ? completed / total : 0.0;
          final isDeletingSub = _deletingSubject[subName] == true;
          final isExpanded = _expanded[subName] ?? false;

          return Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _accent.withOpacity(0.12)),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                // â”€â”€ key fix: named key so Flutter matches widget
                //    to state across rebuilds â”€â”€
                key: PageStorageKey(subName),
                initiallyExpanded: isExpanded,
                onExpansionChanged: (val) =>
                    setState(() => _expanded[subName] = val),
                tilePadding: EdgeInsets.fromLTRB(12, 0, 8, 0),
                minTileHeight: 52,
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accent, _accent.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Text(
                      subName.isNotEmpty ? subName[0].toUpperCase() : 'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  subName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: _accent.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(_accent),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '$completed/$total',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: isDeletingSub
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.red[400],
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _iconBtn(
                            Icons.drive_file_rename_outline_rounded,
                            _accent,
                            () => _showRenameSubjectSheet(subName),
                          ),
                          SizedBox(width: 4),
                          _iconBtn(
                            Icons.delete_outline_rounded,
                            Colors.red[400]!,
                            () => _confirmDeleteSubject(subName),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.expand_more_rounded,
                            color: Colors.grey[400],
                            size: 18,
                          ),
                        ],
                      ),
                children: [
                  Divider(
                    height: 1,
                    color: _accent.withOpacity(0.08),
                    indent: 12,
                    endIndent: 12,
                  ),

                  ...lessons.asMap().entries.map((le) {
                    final lesson = le.value as Map;
                    final lessonName = lesson['name']?.toString() ?? 'Lesson';
                    final isDone = lesson['completed'] == true;
                    final lessonKey = '$subName|$lessonName';
                    final isDeletingLes = _deletingLesson[lessonKey] == true;

                    return InkWell(
                      onTap: () => _toggleLesson(subName, lessonName, isDone),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(12, 8, 8, 8),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone ? _accent : Colors.transparent,
                                border: Border.all(
                                  color: isDone ? _accent : Colors.grey[350]!,
                                  width: 1.5,
                                ),
                              ),
                              child: isDone
                                  ? Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 11,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                lessonName,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDone
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontWeight: isDone
                                      ? FontWeight.w400
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isDone)
                              Container(
                                margin: EdgeInsets.only(right: 6),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'Done',
                                  style: TextStyle(
                                    color: _accent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            isDeletingLes
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.red[400],
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _iconBtn(
                                        Icons.drive_file_rename_outline_rounded,
                                        _accent,
                                        () => _showRenameLessonSheet(
                                          subName,
                                          lessonName,
                                        ),
                                        size: 13,
                                      ),
                                      SizedBox(width: 3),
                                      _iconBtn(
                                        Icons.delete_outline_rounded,
                                        Colors.red[400]!,
                                        () => _confirmDeleteLesson(
                                          subName,
                                          lessonName,
                                        ),
                                        size: 13,
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 6, 12, 10),
                    child: GestureDetector(
                      onTap: () => _showAddLessonSheet(subName),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          border: Border.all(color: _accent.withOpacity(0.25)),
                          borderRadius: BorderRadius.circular(3),
                          color: _accent.withOpacity(0.03),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, color: _accent, size: 13),
                            SizedBox(width: 5),
                            Text(
                              'Add Lesson',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _iconBtn(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    double size = 14,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Icon(icon, color: color, size: size),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: _accent.withOpacity(0.08),
            ),
            child: Icon(Icons.menu_book_outlined, color: _accent, size: 28),
          ),
          SizedBox(height: 14),
          Text(
            'No Subjects Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Add subjects and lessons\nfor this classroom.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          SizedBox(height: 18),
          Theme(
            data: ThemeData(
              colorScheme: ColorScheme.light(
                primary: _accent,
                onPrimary: Colors.white,
              ),
            ),
            child: SizedBox(
              height: 38,
              child: ElevatedButton.icon(
                onPressed: _showAddSubjectSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                icon: Icon(Icons.add_rounded, size: 15, color: Colors.white),
                label: Text(
                  'Add Subject',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
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

