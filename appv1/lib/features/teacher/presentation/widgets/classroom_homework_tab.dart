import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import 'pdf_viewer_page.dart';
import 'package:appv1/core/widgets/image_viewer_page.dart';

class ClassroomHomeworkTab extends StatefulWidget {
  final String classId;
  final String className;
  final String orgId;
  final List<Map<String, dynamic>> subjects;

  const ClassroomHomeworkTab({
    required this.classId,
    required this.className,
    required this.orgId,
    required this.subjects,
  });

  @override
  _ClassroomHomeworkTabState createState() => _ClassroomHomeworkTabState();
}

class _ClassroomHomeworkTabState extends State<ClassroomHomeworkTab> {
  bool _loading = false;
  bool _error = false;
  List<Map<String, dynamic>> _homeworks = [];
  String _teacherId = '';
  String _teacherName = '';
  Map<String, dynamic>? _selectedSubject;

  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTeacherPrefs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadTeacherPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teacherId = prefs.getString('teacherId') ?? '';
      _teacherName = prefs.getString('teacherName') ?? 'Teacher';
    });
  }

  void _selectSubject(Map<String, dynamic> subject) {
    setState(() {
      _selectedSubject = subject;
      _homeworks = [];
    });
    _fetchHomeworks();
  }

  void _goBackToSubjects() {
    setState(() {
      _selectedSubject = null;
      _homeworks = [];
      _error = false;
    });
  }

  Future<void> _fetchHomeworks() async {
    if (_selectedSubject == null) return;
    final subjectId = _selectedSubject!['subjectId']?.toString() ??
        _selectedSubject!['_id']?.toString() ??
        '';
    if (subjectId.isEmpty) return;

    setState(() {
      _loading = true;
      _error = false;
      _page = 1;
    });
    try {
      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/homework/class/${widget.classId}/subject/$subjectId?page=1&limit=10',
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['homeworks'] as List? ?? []);
        final pagination = body['pagination'] as Map?;
        final totalPages = pagination?['pages'] as int? ?? 1;

        setState(() {
          _homeworks = list.map((e) => Map<String, dynamic>.from(e)).toList();
          _hasMore = _page < totalPages;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _selectedSubject == null) return;
    final subjectId = _selectedSubject!['subjectId']?.toString() ??
        _selectedSubject!['_id']?.toString() ??
        '';
    if (subjectId.isEmpty) return;

    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/homework/class/${widget.classId}/subject/$subjectId?page=$nextPage&limit=10',
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['homeworks'] as List? ?? []);
        final pagination = body['pagination'] as Map?;
        final totalPages = pagination?['pages'] as int? ?? 1;

        setState(() {
          _homeworks.addAll(list.map((e) => Map<String, dynamic>.from(e)).toList());
          _page = nextPage;
          _hasMore = _page < totalPages;
          _loadingMore = false;
        });
      } else {
        setState(() => _loadingMore = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateHomeworkSheet(
        classId: widget.classId,
        className: widget.className,
        orgId: widget.orgId,
        teacherId: _teacherId,
        teacherName: _teacherName,
        subjects: widget.subjects,
        initialSubject: _selectedSubject,
        onCreated: _fetchHomeworks,
      ),
    );
  }

  void _openEditSheet(Map<String, dynamic> homework) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditHomeworkSheet(
        homework: homework,
        onUpdated: _fetchHomeworks,
      ),
    );
  }

  Future<void> _deleteHomework(String homeworkId) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConstants.apiBaseUrl}/homework/$homeworkId'),
        headers: await ApiService.getHeaders(),
      );
      if (res.statusCode == 200) {
        _fetchHomeworks();
        _snack('Homework deleted successfully.', Colors.green[600]!);
      } else {
        _snack('Failed to delete homework.', Colors.red[600]!);
      }
    } catch (e) {
      _snack('Failed to delete: $e', Colors.red[600]!);
    }
  }

  void _confirmDelete(String homeworkId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        title: const Text('Delete Homework', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: const Text('Are you sure you want to permanently delete this homework?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteHomework(homeworkId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  String _formatDeadline(String deadlineStr) {
    try {
      final dt = DateTime.parse(deadlineStr).toLocal();
      const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final minute = dt.minute.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      return '${dt.day} ${m[dt.month - 1]} ${dt.year} · $hour:$minute';
    } catch (_) {
      return deadlineStr;
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
    return f.endsWith('.jpg') || f.endsWith('.jpeg') || f.endsWith('.png') || f.endsWith('.webp') || f.endsWith('.gif') ||
           t.contains('image') || t == 'png' || t == 'jpg' || t == 'jpeg';
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedSubject == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: _buildSubjectList(),
      );
    }

    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2));
    } else if (_error) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text('Failed to load homework', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchHomeworks,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
      content = RefreshIndicator(
        color: Colors.teal,
        onRefresh: _fetchHomeworks,
        child: _homeworks.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                itemCount: _homeworks.length + (_loadingMore ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == _homeworks.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2),
                      ),
                    );
                  }
                  final hw = _homeworks[i];
                  final hwId = hw['homeworkId']?.toString() ?? '';
                  final title = hw['title']?.toString() ?? 'Homework';
                  final description = hw['description']?.toString() ?? '';
                  final subject = hw['subject']?.toString() ?? 'General';
                  final deadline = hw['deadline']?.toString() ?? '';
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
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                subject,
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.teal, size: 18),
                              onPressed: () => _openEditSheet(hw),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 18),
                              onPressed: () => _confirmDelete(hwId),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.alarm_rounded, color: Colors.orange[600], size: 13),
                            const SizedBox(width: 6),
                            Text(
                              'Deadline: ${_formatDeadline(deadline)}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        if (attachments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF5F5F5)),
                          const SizedBox(height: 8),
                          ...attachments.map((file) {
                            final name = file['filename']?.toString() ?? file['originalName']?.toString() ?? 'Attachment';
                            final type = file['type']?.toString() ?? file['resourceType']?.toString() ?? file['mimeType']?.toString() ?? '';
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
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () async {
                                      if (url.isNotEmpty) {
                                        if (isPdf) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PdfViewerPage(url: url, fileName: name),
                                            ),
                                          );
                                        } else if (isImage) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ImageViewerPage(url: url, fileName: name),
                                            ),
                                          );
                                        } else {
                                          final uri = Uri.parse(url);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          }
                                        }
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.teal,
                                      side: const BorderSide(color: Colors.teal, width: 1),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                    ),
                                    child: const Text('View', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
            ),
          ),
          child: SafeArea(
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
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.black87,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedSubject!['name']?.toString() ?? 'Homework',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Homework List',
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
          ),
        ),
      ),
      body: content,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateSheet,
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildSubjectList() {
    if (widget.subjects.isEmpty) {
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
                  color: Colors.teal.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.teal, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                'No Subjects Available',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add subjects to this classroom first under the "Subjects" section.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
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
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...widget.subjects.map((sub) {
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.assignment_rounded,
                          color: Colors.teal,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to view and manage homework assignments',
                            style: TextStyle(
                              color: AppColors.textSecondary,
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

  Widget _buildEmptyState() {
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
                color: Colors.teal.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_rounded, color: Colors.teal, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'No Homework Created',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create homework assignments to assign to your class students.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
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

// ─── CREATE HOMEWORK SHEET ───────────────────────────────────────────────────

class _CreateHomeworkSheet extends StatefulWidget {
  final String classId;
  final String className;
  final String orgId;
  final String teacherId;
  final String teacherName;
  final List<Map<String, dynamic>> subjects;
  final Map<String, dynamic>? initialSubject;
  final VoidCallback onCreated;

  const _CreateHomeworkSheet({
    required this.classId,
    required this.className,
    required this.orgId,
    required this.teacherId,
    required this.teacherName,
    required this.subjects,
    this.initialSubject,
    required this.onCreated,
  });

  @override
  __CreateHomeworkSheetState createState() => __CreateHomeworkSheetState();
}

class __CreateHomeworkSheetState extends State<_CreateHomeworkSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Map<String, dynamic>? _selectedSubject;
  DateTime? _deadline;
  bool _saving = false;
  final List<File> _files = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialSubject != null) {
      final match = widget.subjects.firstWhere(
        (s) => (s['subjectId'] ?? s['_id']) == (widget.initialSubject!['subjectId'] ?? widget.initialSubject!['_id']),
        orElse: () => widget.initialSubject!,
      );
      _selectedSubject = match;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: true,
    );
    if (result != null) {
      final List<File> valid = [];
      for (final f in result.files) {
        if (f.path != null) {
          final file = File(f.path!);
          final length = await file.length();
          if (length <= 8 * 1024 * 1024) {
            valid.add(file);
          }
        }
      }
      setState(() => _files.addAll(valid));
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Colors.teal)),
        child: child!,
      ),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Colors.teal)),
          child: child!,
        ),
      );
      if (time != null) {
        setState(() {
          _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  String _formatDate(DateTime dt) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${m[dt.month - 1]} ${dt.year} · ${dt.hour.toString().padLeft(2, '0')}:$min';
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _selectedSubject == null || _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title, subject, and deadline.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final finalOrgId = widget.orgId.isNotEmpty ? widget.orgId : prefs.getString('orgId') ?? '';
      final finalClassId = widget.classId.isNotEmpty ? widget.classId : prefs.getString('classId') ?? '';
      final finalClassName = widget.className.isNotEmpty ? widget.className : 'Classroom';
      final finalTeacherId = widget.teacherId.isNotEmpty ? widget.teacherId : prefs.getString('teacherId') ?? '';
      final finalTeacherName = widget.teacherName.isNotEmpty ? widget.teacherName : prefs.getString('teacherName') ?? 'Teacher';
      
      final subjectName = _selectedSubject!['name']?.toString() ?? '';
      final subjectId = _selectedSubject!['subjectId']?.toString() ??
                        _selectedSubject!['_id']?.toString() ?? '';

      debugPrint('Creating Homework with fields:');
      debugPrint('title: $title');
      debugPrint('subject: $subjectName');
      debugPrint('subjectId: $subjectId');
      debugPrint('createdBy: $finalTeacherId');
      debugPrint('createdByName: $finalTeacherName');
      debugPrint('deadline: ${_deadline!.toUtc().toIso8601String()}');
      debugPrint('orgId: $finalOrgId');
      debugPrint('classId: $finalClassId');
      debugPrint('className: $finalClassName');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.apiBaseUrl}/homework/create'),
      );
      request.headers.addAll(await ApiService.getHeaders());
      request.fields['title'] = title;
      request.fields['description'] = _descCtrl.text.trim();
      request.fields['subject'] = subjectName;
      request.fields['subjectId'] = subjectId;
      request.fields['createdBy'] = finalTeacherId;
      request.fields['createdByName'] = finalTeacherName;
      request.fields['deadline'] = _deadline!.toUtc().toIso8601String();
      request.fields['orgId'] = finalOrgId;
      request.fields['classId'] = finalClassId;
      request.fields['className'] = finalClassName;

      for (final f in _files) {
        final ext = f.path.split('.').last.toLowerCase();
        final type = (ext == 'pdf') ? 'application' : 'image';
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            f.path,
            contentType: MediaType(type, ext),
          ),
        );
      }

      final stream = await request.send();
      final res = await http.Response.fromStream(stream);

      if (!mounted) return;
      setState(() => _saving = false);

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        widget.onCreated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create homework: ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 36, height: 3, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.assignment_add, color: Colors.teal, size: 18),
                SizedBox(width: 8),
                Text('Create Homework', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Homework Title *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Solve Algebra Sheet',
                prefixIcon: const Icon(Icons.title, color: Colors.teal, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey[200]!)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Select Subject *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedSubject,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.book, color: Colors.teal, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey[200]!)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: widget.subjects.map((s) {
                return DropdownMenuItem(value: s, child: Text(s['name']?.toString() ?? '', style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: (v) => setState(() => _selectedSubject = v),
              hint: const Text('Select subject', style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 12),
            const Text('Deadline *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Colors.teal, size: 16),
                    const SizedBox(width: 8),
                    Text(_deadline == null ? 'Select deadline date/time' : _formatDate(_deadline!), style: TextStyle(fontSize: 13, color: _deadline == null ? Colors.grey : Colors.black)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Optional Attachments', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.attach_file_rounded, size: 16),
              label: const Text('Pick Files (PDF/Images)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: const BorderSide(color: Colors.teal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              ),
            ),
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...List.generate(_files.length, (i) {
                final f = _files[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.file_present_rounded, color: Colors.teal, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f.path.split('/').last,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                        onPressed: () => setState(() => _files.removeAt(i)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Homework', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── EDIT HOMEWORK SHEET ─────────────────────────────────────────────────────

class _EditHomeworkSheet extends StatefulWidget {
  final Map<String, dynamic> homework;
  final VoidCallback onUpdated;

  const _EditHomeworkSheet({
    required this.homework,
    required this.onUpdated,
  });

  @override
  __EditHomeworkSheetState createState() => __EditHomeworkSheetState();
}

class __EditHomeworkSheetState extends State<_EditHomeworkSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _deadline;
  bool _saving = false;
  final List<File> _files = [];
  List<dynamic> _existingAttachments = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.homework['title']?.toString() ?? '';
    _descCtrl.text = widget.homework['description']?.toString() ?? '';
    _deadline = DateTime.tryParse(widget.homework['deadline']?.toString() ?? '')?.toLocal();
    _existingAttachments = List<dynamic>.from(widget.homework['attachments'] as List? ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: true,
    );
    if (result != null) {
      final List<File> valid = [];
      for (final f in result.files) {
        if (f.path != null) {
          final file = File(f.path!);
          final length = await file.length();
          if (length <= 8 * 1024 * 1024) {
            valid.add(file);
          }
        }
      }
      setState(() => _files.addAll(valid));
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Colors.teal)),
        child: child!,
      ),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline ?? DateTime.now()),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Colors.teal)),
          child: child!,
        ),
      );
      if (time != null) {
        setState(() {
          _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _deleteAttachment(String publicId) async {
    final homeworkId = widget.homework['homeworkId']?.toString() ?? '';
    try {
      final res = await http.delete(
        Uri.parse('${ApiConstants.apiBaseUrl}/homework/$homeworkId/attachment'),
        headers: {
          ...?await ApiService.getHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'publicId': publicId}),
      );
      if (res.statusCode == 200) {
        setState(() {
          _existingAttachments.removeWhere((file) => file['publicId'] == publicId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attachment deleted.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete attachment: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  String _formatDate(DateTime dt) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${m[dt.month - 1]} ${dt.year} · ${dt.hour.toString().padLeft(2, '0')}:$min';
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and deadline.')),
      );
      return;
    }
    setState(() => _saving = true);
    final homeworkId = widget.homework['homeworkId']?.toString() ?? '';
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiConstants.apiBaseUrl}/homework/$homeworkId'),
      );
      request.headers.addAll(await ApiService.getHeaders());
      request.fields['title'] = title;
      request.fields['description'] = _descCtrl.text.trim();
      request.fields['deadline'] = _deadline!.toUtc().toIso8601String();

      for (final f in _files) {
        final ext = f.path.split('.').last.toLowerCase();
        final type = (ext == 'pdf') ? 'application' : 'image';
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            f.path,
            contentType: MediaType(type, ext),
          ),
        );
      }

      final stream = await request.send();
      final res = await http.Response.fromStream(stream);

      if (!mounted) return;
      setState(() => _saving = false);

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        widget.onUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update homework: ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 36, height: 3, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.edit, color: Colors.teal, size: 18),
                SizedBox(width: 8),
                Text('Edit Homework', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Homework Title *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Solve Algebra Sheet',
                prefixIcon: const Icon(Icons.title, color: Colors.teal, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey[200]!)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Solve questions 1 to 5 from chapter 4...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 30),
                  child: Icon(Icons.description, color: Colors.teal, size: 18),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey[200]!)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Deadline *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Colors.teal, size: 16),
                    const SizedBox(width: 8),
                    Text(_deadline == null ? 'Select deadline date/time' : _formatDate(_deadline!), style: TextStyle(fontSize: 13, color: _deadline == null ? Colors.grey : Colors.black)),
                  ],
                ),
              ),
            ),
            if (_existingAttachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Existing Attachments', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              ..._existingAttachments.map((file) {
                final name = file['filename']?.toString() ?? 'Attachment';
                final publicId = file['publicId']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.file_present_rounded, color: Colors.grey, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                        onPressed: () => _deleteAttachment(publicId),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            const SizedBox(height: 16),
            const Text('Add Attachments', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.attach_file_rounded, size: 16),
              label: const Text('Pick Files (PDF/Images)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: const BorderSide(color: Colors.teal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              ),
            ),
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...List.generate(_files.length, (i) {
                final f = _files[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.file_present_rounded, color: Colors.teal, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f.path.split('/').last,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                        onPressed: () => setState(() => _files.removeAt(i)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
