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

  Future<void> _toggleLesson(
    String subjectName,
    String lessonName,
    bool current,
  ) async {
    try {
      await http.put(
        Uri.parse(
          'https://appv1backend.onrender.com/api/classroom/${widget.classId}/lessons/status',
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

  void _showAddSubjectSheet() {
    final nameCtrl = TextEditingController();
    final lessonsCtrl = [TextEditingController()];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                SizedBox(height: 20),

                // ── Header ──
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: _accent,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Add Subject',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                _sheetLabel('Subject Name'),
                SizedBox(height: 8),
                _sheetInput(
                  nameCtrl,
                  'e.g. Mathematics',
                  Icons.menu_book_rounded,
                ),
                SizedBox(height: 20),

                Row(
                  children: [
                    _sheetLabel('Lessons'),
                    Spacer(),
                    GestureDetector(
                      onTap: () => setSheetState(
                        () => lessonsCtrl.add(TextEditingController()),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _accent.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: _accent, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Add Lesson',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                ...lessonsCtrl.asMap().entries.map(
                  (e) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: EdgeInsets.only(right: 10),
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
                            onTap: () => setSheetState(
                              () => lessonsCtrl.removeAt(e.key),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      await http.post(
                        Uri.parse(
                          'https://appv1backend.onrender.com/api/classroom/${widget.classId}/subjects',
                        ),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'name': nameCtrl.text.trim(),
                          'lessons': lessonsCtrl
                              .map(
                                (c) => {
                                  'name': c.text.trim(),
                                  'completed': false,
                                },
                              )
                              .where((l) => (l['name'] as String).isNotEmpty)
                              .toList(),
                        }),
                      );
                      widget.onRefresh();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add Subject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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

  void _showAddLessonSheet(String subjectName) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.book_outlined, color: _accent, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Lesson',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'to "$subjectName"',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              _sheetLabel('Lesson Name'),
              SizedBox(height: 8),
              _sheetInput(ctrl, 'e.g. Algebra', Icons.book_outlined),
              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (ctrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    await http.post(
                      Uri.parse(
                        'https://appv1backend.onrender.com/api/classroom/${widget.classId}/lessons',
                      ),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'subjectName': subjectName,
                        'lessonName': ctrl.text.trim(),
                      }),
                    );
                    widget.onRefresh();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add Lesson',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ──

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _sheetLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.4,
    ),
  );

  Widget _sheetInput(TextEditingController ctrl, String hint, IconData icon) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: ctrl,
          cursorColor: _accent,
          style: TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: _accent, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _accent.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) {
      return _buildEmpty();
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Add Subject button ──
        GestureDetector(
          onTap: _showAddSubjectSheet,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: _accent.withOpacity(0.4), width: 1.5),
              borderRadius: BorderRadius.circular(14),
              color: _accent.withOpacity(0.04),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: _accent, size: 18),
                SizedBox(width: 8),
                Text(
                  'Add New Subject',
                  style: TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // ── Subject cards ──
        ...widget.subjects.asMap().entries.map((entry) {
          final si = entry.key;
          final sub = entry.value;
          final subName = sub['name']?.toString() ?? 'Subject';
          final lessons = sub['lessons'] as List? ?? [];
          final total = lessons.length;
          final completed = lessons
              .where((l) => (l as Map)['completed'] == true)
              .length;
          final progress = total > 0 ? completed / total : 0.0;

          return Container(
            margin: EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.08),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(color: _accent.withOpacity(0.15)),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: si == 0,
                tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accent, _accent.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      subName.isNotEmpty ? subName[0].toUpperCase() : 'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  subName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$completed/$total lessons done',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '(${(progress * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: _accent.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(_accent),
                      ),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
                children: [
                  Divider(
                    height: 1,
                    color: _accent.withOpacity(0.08),
                    indent: 16,
                    endIndent: 16,
                  ),

                  // ── Lessons list ──
                  ...lessons.asMap().entries.map((le) {
                    final lesson = le.value as Map;
                    final lessonName = lesson['name']?.toString() ?? 'Lesson';
                    final isDone = lesson['completed'] == true;

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      leading: GestureDetector(
                        onTap: () => _toggleLesson(subName, lessonName, isDone),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? _accent : Colors.transparent,
                            border: Border.all(
                              color: isDone ? _accent : Colors.grey[350]!,
                              width: 2,
                            ),
                          ),
                          child: isDone
                              ? Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                      ),
                      title: Text(
                        lessonName,
                        style: TextStyle(
                          fontSize: 13.5,
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
                      trailing: isDone
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _accent.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                '✓ Done',
                                style: TextStyle(
                                  color: _accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    );
                  }).toList(),

                  // ── Add lesson ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: GestureDetector(
                      onTap: () => _showAddLessonSheet(subName),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _accent.withOpacity(0.3),
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: _accent.withOpacity(0.04),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, color: _accent, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Add Lesson',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 12,
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

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.1),
            ),
            child: Icon(Icons.menu_book_outlined, color: _accent, size: 36),
          ),
          SizedBox(height: 16),
          Text(
            'No Subjects Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Add subjects and lessons for this classroom.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddSubjectSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.add_rounded),
            label: Text(
              'Add Subject',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}
