import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/features/student/student_theme_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import '../teacher/presentation/widgets/pdf_viewer_page.dart';
import 'package:appv1/core/widgets/image_viewer_page.dart';

class StudentClassroomHomeworkTab extends StatefulWidget {
  final Map<String, dynamic> classroom;

  const StudentClassroomHomeworkTab({required this.classroom});

  @override
  _StudentClassroomHomeworkTabState createState() =>
      _StudentClassroomHomeworkTabState();
}

class _StudentClassroomHomeworkTabState
    extends State<StudentClassroomHomeworkTab> {
  StudentThemeConfig get theme => StudentThemeManager.themeNotifier.value;
  Map<String, dynamic>? _selectedSubject;
  bool _loadingHomeworks = false;
  bool _errorHomeworks = false;
  List<Map<String, dynamic>> _homeworks = [];

  List<dynamic> get _subjects =>
      widget.classroom['subjects'] as List<dynamic>? ?? [];

  String get _classId =>
      widget.classroom['classId']?.toString() ??
      widget.classroom['_id']?.toString() ??
      '';

  void _selectSubject(Map<String, dynamic> subject) {
    setState(() {
      _selectedSubject = subject;
      _homeworks = [];
    });
    _fetchHomeworksForSubject(subject);
  }

  void _goBackToSubjects() {
    setState(() {
      _selectedSubject = null;
      _homeworks = [];
      _errorHomeworks = false;
    });
  }

  Future<void> _fetchHomeworksForSubject(Map<String, dynamic> subject) async {
    final subjectId =
        subject['subjectId']?.toString() ?? subject['_id']?.toString() ?? '';
    if (_classId.isEmpty || subjectId.isEmpty) return;

    setState(() {
      _loadingHomeworks = true;
      _errorHomeworks = false;
    });

    try {
      final url =
          '/homework/class/$_classId/subject/$subjectId?page=1&limit=50';
      final res = await ApiService.get(url);

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['homeworks'] as List? ?? []);
        setState(() {
          _homeworks = list.map((e) => Map<String, dynamic>.from(e)).toList();
          _loadingHomeworks = false;
        });
      } else {
        setState(() {
          _loadingHomeworks = false;
          _errorHomeworks = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingHomeworks = false;
        _errorHomeworks = true;
      });
    }
  }

  String _formatDeadline(String deadlineStr) {
    try {
      final dt = DateTime.parse(deadlineStr).toLocal();
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final minute = dt.minute.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      return '${dt.day} ${m[dt.month - 1]} ${dt.year} · $hour:$minute';
    } catch (_) {
      return deadlineStr;
    }
  }

  bool _isDeadlinePast(String deadlineStr) {
    try {
      final dt = DateTime.parse(deadlineStr).toLocal();
      return DateTime.now().isAfter(dt);
    } catch (_) {
      return false;
    }
  }

  bool _isPdfFile(String filename, String type) {
    final f = filename.toLowerCase();
    final t = type.toLowerCase();
    return f.endsWith('.pdf') || t.contains('pdf') || t == 'pdf';
  }

  bool _isImageFile(String filename, String type) {
    final f = filename.toLowerCase();
    final t = type.toLowerCase();
    return f.endsWith('.jpg') ||
        f.endsWith('.jpeg') ||
        f.endsWith('.png') ||
        f.endsWith('.webp') ||
        f.endsWith('.gif') ||
        t.contains('image') ||
        t == 'png' ||
        t == 'jpg' ||
        t == 'jpeg';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        if (_selectedSubject == null) {
          return _buildSubjectList();
        }
        return _buildHomeworkList();
      },
    );
  }

  // ── Subject List View ────────────────────────────────
  Widget _buildSubjectList() {
    if (_subjects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_rounded,
        title: 'No Subjects Available',
        message: 'There are no subjects available in this classroom.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
      children: [
        Text(
          'Subjects',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: theme.textPrimary,
          ),
        ),
        SizedBox(height: 10),
        ..._subjects.map((subRaw) {
          final sub = subRaw as Map<String, dynamic>;
          final name = sub['name']?.toString() ?? 'Subject';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: InkWell(
              onTap: () => _selectSubject(sub),
              borderRadius: BorderRadius.circular(3),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.assignment_rounded,
                          color: theme.primary,
                          size: 18,
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
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: theme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to view homework assignments',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey[300],
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // ── Homework List View ────────────────────────────────
  Widget _buildHomeworkList() {
    final subName = _selectedSubject!['name']?.toString() ?? 'Homework';

    if (_loadingHomeworks) {
      return Column(
        children: [
          _buildHomeworkHeader(subName),
          Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: theme.primary,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      );
    }

    if (_errorHomeworks) {
      return Column(
        children: [
          _buildHomeworkHeader(subName),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Failed to load homework',
                    style: TextStyle(color: theme.textSecondary),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        _fetchHomeworksForSubject(_selectedSubject!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHomeworkHeader(subName),
        Expanded(
          child: _homeworks.isEmpty
              ? _buildEmptyState(
                  icon: Icons.assignment_turned_in_rounded,
                  title: 'No Homework Found',
                  message: 'No homework assignments found for this subject.',
                )
              : RefreshIndicator(
                  color: theme.primary,
                  onRefresh: () => _fetchHomeworksForSubject(_selectedSubject!),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                    itemCount: _homeworks.length,
                    itemBuilder: (ctx, i) {
                      final hw = _homeworks[i];
                      final title = hw['title']?.toString() ?? 'Homework';
                      final description = hw['description']?.toString() ?? '';
                      final createdByName =
                          hw['createdByName']?.toString() ?? 'Teacher';
                      final deadline = hw['deadline']?.toString() ?? '';
                      final isPast = _isDeadlinePast(deadline);
                      final attachments = (hw['attachments'] as List? ?? []);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: theme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPast
                                        ? Colors.grey.withOpacity(0.1)
                                        : theme.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    isPast ? 'Closed' : 'Active',
                                    style: TextStyle(
                                      color: isPast
                                          ? Colors.grey[600]
                                          : theme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (description.isNotEmpty) ...[
                              SizedBox(height: 6),
                              Text(
                                description,
                                style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  color: theme.textSecondary,
                                  size: 13,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Assigned by: $createdByName',
                                  style: TextStyle(
                                    color: theme.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.alarm_rounded,
                                  color: isPast
                                      ? Colors.grey
                                      : Colors.orange[600],
                                  size: 13,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Deadline: ${_formatDeadline(deadline)}',
                                  style: TextStyle(
                                    color: theme.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            if (attachments.isNotEmpty) ...[
                              SizedBox(height: 12),
                              Divider(
                                height: 1,
                                color: Color(0xFFF5F5F5),
                              ),
                              SizedBox(height: 8),
                              ...attachments.map((file) {
                                final name =
                                    file['filename']?.toString() ??
                                    file['originalName']?.toString() ??
                                    'Attachment';
                                final type =
                                    file['type']?.toString() ??
                                    file['resourceType']?.toString() ??
                                    file['mimeType']?.toString() ??
                                    '';
                                final url = file['url']?.toString() ?? '';
                                final isPdf = _isPdfFile(name, type);
                                final isImage = _isImageFile(name, type);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isPdf
                                            ? Icons.picture_as_pdf_rounded
                                            : isImage
                                            ? Icons.image_rounded
                                            : Icons.insert_drive_file_rounded,
                                        color: Colors.grey[600],
                                        size: 15,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            color: theme.textPrimary,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      OutlinedButton(
                                        onPressed: () async {
                                          if (url.isNotEmpty) {
                                            if (isPdf) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => PdfViewerPage(
                                                    url: url,
                                                    fileName: name,
                                                  ),
                                                ),
                                              );
                                            } else if (isImage) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ImageViewerPage(
                                                        url: url,
                                                        fileName: name,
                                                      ),
                                                ),
                                              );
                                            } else {
                                              final uri = Uri.parse(url);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(
                                                  uri,
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              }
                                            }
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: theme.primary,
                                          side: BorderSide(
                                            color: theme.primary,
                                            width: 1,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'View',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHomeworkHeader(String subjectName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goBackToSubjects,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black87,
                size: 14,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: theme.textPrimary,
                  ),
                ),
                Text(
                  'Homework List',
                  style: TextStyle(fontSize: 11, color: theme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State Widget ────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.primary, size: 28),
            ),
            SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: theme.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
