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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 28),
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
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: _accent,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Add Subject',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                            onTap: () => setSheetState(
                              () => lessonsCtrl.removeAt(e.key),
                            ),
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
                SizedBox(
                  width: double.infinity,
                  height: 46,
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
                        borderRadius: BorderRadius.circular(3),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add Subject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    child: Icon(Icons.book_outlined, color: _accent, size: 16),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Lesson',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'to "$subjectName"',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              _sheetLabel('Lesson Name'),
              SizedBox(height: 6),
              _sheetInput(ctrl, 'e.g. Algebra', Icons.book_outlined),
              SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
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
                      borderRadius: BorderRadius.circular(3),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add Lesson',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

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

  // ── Main build ──

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) return _buildEmpty();

    return ListView(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // ── Add Subject button ──
        GestureDetector(
          onTap: _showAddSubjectSheet,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: _accent.withOpacity(0.35)),
              borderRadius: BorderRadius.circular(3),
              color: _accent.withOpacity(0.03),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: _accent, size: 15),
                SizedBox(width: 6),
                Text(
                  'Add New Subject',
                  style: TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10),

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
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
              border: Border.all(color: _accent.withOpacity(0.12)),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: si == 0,
                tilePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
                    // Mini progress bar
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
                children: [
                  Divider(
                    height: 1,
                    color: _accent.withOpacity(0.08),
                    indent: 12,
                    endIndent: 12,
                  ),

                  // ── Lessons ──
                  ...lessons.asMap().entries.map((le) {
                    final lesson = le.value as Map;
                    final lessonName = lesson['name']?.toString() ?? 'Lesson';
                    final isDone = lesson['completed'] == true;

                    return InkWell(
                      onTap: () => _toggleLesson(subName, lessonName, isDone),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            // Checkbox circle
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
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  // ── Add Lesson ──
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

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.08),
            ),
            child: Icon(Icons.menu_book_outlined, color: _accent, size: 28),
          ),
          SizedBox(height: 12),
          Text(
            'No Subjects Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Add subjects and lessons for this classroom.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddSubjectSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              elevation: 0,
            ),
            icon: Icon(Icons.add_rounded, size: 15),
            label: Text(
              'Add Subject',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}
