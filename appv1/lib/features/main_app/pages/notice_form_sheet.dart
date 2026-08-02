import 'dart:typed_data';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/document_picker_service.dart';
import 'package:path/path.dart' as path;

import '../../teacher/presentation/widgets/pdf_viewer_page.dart';
import 'admin_image_viewer.dart';

class NoticeFormSheet extends StatefulWidget {
  final String orgId;
  final List<Map<String, dynamic>> classrooms;
  final Map<String, dynamic>? notice;

  const NoticeFormSheet({
    super.key,
    required this.orgId,
    required this.classrooms,
    this.notice,
  });

  @override
  State<NoticeFormSheet> createState() => _NoticeFormSheetState();
}

class _NoticeFormSheetState extends State<NoticeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // 'both' = teachers_and_students, 'teachers' = teachers_only
  String _audienceUI = 'both';
  String _targetScope = 'all_classes';
  bool _allClasses = true;
  bool _loading = false;

  DateTime? _expiresAt;
  List<String> _selectedClassIds = [];
  List<Map<String, dynamic>> _existingAttachments = [];
  final List<PlatformFile> _newPickedFiles = [];
  OverlayEntry? _currentToast;

  bool get _isEdit => widget.notice != null;

  static const _teal = Color(0xFF00796B);
  static const _tealLight = Color(0xFFE0F2F1);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textGrey = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _bg = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final n = widget.notice!;
      _titleCtrl.text = n['title']?.toString() ?? '';
      _descCtrl.text = n['description']?.toString() ?? '';
      final aud = n['audience']?.toString() ?? 'teachers_only';
      _audienceUI = aud == 'teachers_and_students' ? 'both' : 'teachers';
      _targetScope = n['targetScope']?.toString() ?? 'all_classes';
      _allClasses = _targetScope != 'selected_classes';
      final ids = (n['targetClassIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
      _selectedClassIds = ids;
      _existingAttachments = (n['attachments'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (n['expiresAt'] != null) {
        try {
          _expiresAt = DateTime.parse(n['expiresAt'].toString()).toLocal();
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _currentToast?.remove();
    _currentToast = null;
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String get _apiAudience =>
      _audienceUI == 'both' ? 'teachers_and_students' : 'teachers_only';

  void _showTopToast(String message) {
    _currentToast?.remove();
    _currentToast = null;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) {
        return _TopToastWidget(
          message: message,
          onDismiss: () {
            _currentToast?.remove();
            _currentToast = null;
          },
        );
      },
    );

    _currentToast = entry;
    overlay.insert(entry);
  }

  Future<void> _pickFiles() async {
    final currentTotal = _existingAttachments.length + _newPickedFiles.length;
    if (currentTotal >= 5) {
      _showTopToast('Attachment limit reached (max 5 files)');
      return;
    }

    // Durable native picker on Android; file_picker elsewhere. Both are
    // normalised to PlatformFile so the logic below is untouched.
    final List<PlatformFile> picked;
    if (DocumentPickerService.isSupported) {
      final native = await DocumentPickerService.pick(
        mimeTypes: DocumentPickerService.imagesAndPdf,
        multiple: true,
      );
      if (native.isEmpty) return;
      picked = native
          .map((f) => PlatformFile(
                name: f.name,
                size: f.bytes?.length ?? 0,
                path: f.path,
                bytes: f.bytes == null ? null : Uint8List.fromList(f.bytes!),
              ))
          .toList();
    } else {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result == null) return;
      picked = result.files;
    }

    final tooLargeNames = <String>[];
    final validPicked = <PlatformFile>[];

    for (final f in picked) {
      if (f.size > 5 * 1024 * 1024) {
        tooLargeNames.add(f.name);
      } else {
        validPicked.add(f);
      }
    }

    if (tooLargeNames.isNotEmpty) {
      _showTopToast('File(s) too large (limit 5MB): ${tooLargeNames.join(", ")}');
    }

    if (validPicked.isEmpty) return;

    final remainingSlots = 5 - currentTotal;
    if (validPicked.length > remainingSlots) {
      _showTopToast('Only $remainingSlots more attachment(s) could be added (max 5 files)');
      final accepted = validPicked.take(remainingSlots).toList();
      if (mounted) {
        setState(() {
          _newPickedFiles.addAll(accepted);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _newPickedFiles.addAll(validPicked);
        });
      }
    }
  }

  List<AdminImageItem> _getAllImages() {
    final list = <AdminImageItem>[];
    for (final att in _existingAttachments) {
      final name = att['originalName']?.toString() ?? '';
      final type = att['resourceType']?.toString() ?? 'image';
      final isPdf = type == 'raw' || name.toLowerCase().endsWith('.pdf');
      if (!isPdf) {
        list.add(AdminImageItem(
          url: att['url']?.toString(),
          title: name,
        ));
      }
    }
    for (final f in _newPickedFiles) {
      final ext = path.extension(f.name).toLowerCase();
      if (ext != '.pdf') {
        list.add(AdminImageItem(
          filePath: f.path,
          title: f.name,
        ));
      }
    }
    return list;
  }

  void _openImageViewer(String? url, String? filePath) {
    final images = _getAllImages();
    final idx = images.indexWhere((item) =>
        (url != null && item.url == url) ||
        (filePath != null && item.filePath == filePath));
    if (idx != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminImageViewer(
            images: images,
            initialIndex: idx,
          ),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _teal)),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _expiresAt ?? now.add(const Duration(hours: 18)),
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _teal)),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(
      () => _expiresAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _deleteExistingAttachment(
    int i,
    Map<String, dynamic> att,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        title: const Text(
          'Remove Attachment',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: const Text(
          'Remove this attachment?',
          style: TextStyle(color: _textGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final noticeId = widget.notice!['noticeId']?.toString() ?? '';
      await ApiService.delete(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/admin-notices/$noticeId/attachment',
        ),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'publicId': att['publicId']?.toString() ?? '',
          'resourceType': att['resourceType']?.toString() ?? 'image',
        }),
      );
      if (mounted) {
        setState(() => _existingAttachments.removeAt(i));
        _snack('Removed', _teal);
      }
    } catch (_) {
      if (mounted) _snack('Failed to remove', Colors.red);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiresAt == null) {
      _showTopToast('Please set an expiry date');
      return;
    }
    if (!_allClasses && _selectedClassIds.isEmpty) {
      _showTopToast('Please select at least one class');
      return;
    }
    final navigator = Navigator.of(context);
    setState(() => _loading = true);
    try {
      _isEdit ? await _updateNotice() : await _createNotice();
      if (mounted) navigator.pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _showTopToast('Something went wrong');
      }
    }
  }

  Map<String, dynamic> _buildBody() {
    final scope = _audienceUI == 'both'
        ? (_allClasses ? 'all_classes' : 'selected_classes')
        : '';
    return {
      if (!_isEdit) 'orgId': widget.orgId,
      if (!_isEdit) 'createdBy': widget.orgId,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'audience': _apiAudience,
      'targetScope': scope,
      'targetClassIds': (scope == 'selected_classes')
          ? _selectedClassIds
          : <String>[],
      'expiresAt': _expiresAt!.toUtc().toIso8601String(),
    };
  }

  void _fillFields(Map<String, String> fields) {
    final b = _buildBody();
    b.forEach((k, v) {
      if (v is String) fields[k] = v;
    });
    if (!_allClasses && _audienceUI == 'both') {
      for (int i = 0; i < _selectedClassIds.length; i++) {
        fields['targetClassIds[$i]'] = _selectedClassIds[i];
      }
    }
  }

  Future<void> _createNotice() async {
    final uri = Uri.parse(
      '${ApiConstants.apiBaseUrl}/admin-notices/create',
    );
    if (_newPickedFiles.isNotEmpty) {
      final req = http.MultipartRequest('POST', uri);
      req.headers.addAll(await ApiService.getHeaders());
      _fillFields(req.fields);
      for (final f in _newPickedFiles) {
        final ext = path.extension(f.path!).toLowerCase().replaceAll('.', '');
        req.files.add(
          await http.MultipartFile.fromPath(
            'files',
            f.path!,
            contentType: ext == 'pdf'
                ? MediaType('application', 'pdf')
                : MediaType('image', ext == 'jpg' ? 'jpeg' : ext),
          ),
        );
      }
      await req.send();
    } else {
      await ApiService.post(
        uri,
        headers: await ApiService.getHeaders(),
        body: jsonEncode(_buildBody()),
      );
    }
  }

  Future<void> _updateNotice() async {
    final id = widget.notice!['noticeId']?.toString() ?? '';
    final uri = Uri.parse(
      '${ApiConstants.apiBaseUrl}/admin-notices/$id',
    );
    if (_newPickedFiles.isNotEmpty) {
      final req = http.MultipartRequest('PUT', uri);
      req.headers.addAll(await ApiService.getHeaders());
      _fillFields(req.fields);
      for (final f in _newPickedFiles) {
        final ext = path.extension(f.path!).toLowerCase().replaceAll('.', '');
        req.files.add(
          await http.MultipartFile.fromPath(
            'files',
            f.path!,
            contentType: ext == 'pdf'
                ? MediaType('application', 'pdf')
                : MediaType('image', ext == 'jpg' ? 'jpeg' : ext),
          ),
        );
      }
      await req.send();
    } else {
      await ApiService.put(
        uri,
        headers: await ApiService.getHeaders(),
        body: jsonEncode(_buildBody()),
      );
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12.5)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navBottom = MediaQuery.of(context).padding.bottom;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: _textDark,
            ),
          ),
        ),
        title: Text(
          _isEdit ? 'Edit Notice' : 'Create Notice',
          style: const TextStyle(
            color: _textDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, color: _textDark),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + keyboard + navBottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title & Description Card ─────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('NOTICE TITLE'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: _inputDeco('Enter a concise headline...'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                      style: const TextStyle(fontSize: 14, color: _textDark),
                    ),
                    const SizedBox(height: 20),
                    _fieldLabel('NOTICE DESCRIPTION'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 7,
                      decoration: _inputDeco(
                        'Provide detailed information about this announcement...',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Description is required'
                          : null,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _textDark,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Upload Attachments Card ──────────────────
              _card(
                child: Column(
                  children: [
                    // Existing attachments (edit mode)
                    if (_isEdit && _existingAttachments.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _fieldLabel('CURRENT ATTACHMENTS'),
                      ),
                      const SizedBox(height: 8),
                      ..._existingAttachments.asMap().entries.map(
                        (e) => _existingAttTile(e.key, e.value),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: _border),
                      const SizedBox(height: 16),
                    ],

                    // Upload area
                    GestureDetector(
                      onTap: _pickFiles,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _teal.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_rounded,
                              color: _teal,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isEdit
                                ? 'Add New Attachments'
                                : 'Upload Attachments',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'PDF, DOCX, JPG, or PNG up to 5MB',
                            style: TextStyle(fontSize: 12, color: _textGrey),
                          ),
                        ],
                      ),
                    ),

                    // New picked files
                    if (_newPickedFiles.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ..._newPickedFiles.asMap().entries.map(
                        (e) => _newFileTile(e.key, e.value),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Target Audience Card ─────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('TARGET AUDIENCE'),
                    const SizedBox(height: 12),
                    _audienceRow(
                      value: 'both',
                      label: 'Both (Teachers & Students)',
                      selected: _audienceUI == 'both',
                      onTap: () => setState(() => _audienceUI = 'both'),
                      isFirst: true,
                    ),
                    _audienceRow(
                      value: 'teachers',
                      label: 'Teachers',
                      selected: _audienceUI == 'teachers',
                      onTap: () => setState(() {
                        _audienceUI = 'teachers';
                        _allClasses = true;
                        _selectedClassIds = [];
                      }),
                      isFirst: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Distribution Card (only for both) ────────
              if (_audienceUI == 'both')
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _fieldLabel('DISTRIBUTION'),
                          if (!_allClasses)
                            GestureDetector(
                              onTap: _openClassPicker,
                              child: const Text(
                                'SELECT CLASSES',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _teal,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // All Classes checkbox row
                      GestureDetector(
                        onTap: () => setState(() {
                          _allClasses = !_allClasses;
                          if (_allClasses) _selectedClassIds = [];
                        }),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _allClasses ? _teal : Colors.white,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: _allClasses
                                      ? _teal
                                      : const Color(0xFFD1D5DB),
                                  width: 1.5,
                                ),
                              ),
                              child: _allClasses
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'All Classes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Selected class chips
                      if (!_allClasses && _selectedClassIds.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _classChips(),
                      ],

                      if (!_allClasses && _selectedClassIds.isEmpty) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _openClassPicker,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _tealLight,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: _teal.withValues(alpha: 0.3)),
                            ),
                            child: const Center(
                              child: Text(
                                'Tap to select classes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _teal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (_audienceUI == 'both') const SizedBox(height: 16),

              // ── Expiry Date Card ─────────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('EXPIRY DATE & TIME'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: _teal,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _expiresAt == null
                                  ? 'Set expiry date & time'
                                  : '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}  '
                                        '${_expiresAt!.hour.toString().padLeft(2, '0')}:'
                                        '${_expiresAt!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: _expiresAt == null
                                    ? const Color(0xFFADB5BD)
                                    : _textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Editor's Tip Card ────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      color: const Color(0xFFCFD8DC),
                      child: CustomPaint(
                        painter: _TipBgPainter(),
                        size: const Size(double.infinity, 120),
                      ),
                    ),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              "EDITOR'S TIP",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Keep notices brief and use clear headings for better engagement.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Publish Button ───────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Update Notice' : 'Publish Notice',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Audience row ───────────────────────────────────────

  Widget _audienceRow({
    required String value,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isFirst,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _teal : Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: selected ? _teal : _border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : _textDark,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: selected ? Colors.white : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _teal,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Class chips ────────────────────────────────────────

  Widget _classChips() {
    final names = _selectedClassIds.map((id) {
      final cls = widget.classrooms.firstWhere(
        (c) => c['classId'] == id,
        orElse: () => {'className': id},
      );
      return cls['className']?.toString() ?? id;
    }).toList();

    const maxShow = 2;
    final shown = names.take(maxShow).toList();
    final extra = names.length - maxShow;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...shown.asMap().entries.map(
          (e) => _classChip(
            e.value,
            onRemove: () => setState(() => _selectedClassIds.removeAt(e.key)),
          ),
        ),
        if (extra > 0)
          GestureDetector(
            onTap: _openClassPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _tealLight,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _teal.withValues(alpha: 0.3)),
              ),
              child: Text(
                '+$extra MORE',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _teal,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _classChip(String label, {required VoidCallback onRemove}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _tealLight,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _teal.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _teal,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded, size: 13, color: _teal),
            ),
          ],
        ),
      );

  // ── Class picker bottom sheet ──────────────────────────

  void _openClassPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(3),
          topRight: Radius.circular(3),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Classes',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _textDark,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: _border),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: widget.classrooms.map((cls) {
                      final id = cls['classId']?.toString() ?? '';
                      final name = cls['className']?.toString() ?? '';
                      final active = _selectedClassIds.contains(id);
                      return ListTile(
                        onTap: () {
                          setInner(() {});
                          setState(() {
                            if (active) {
                              _selectedClassIds.remove(id);
                            } else {
                              _selectedClassIds.add(id);
                            }
                          });
                        },
                        leading: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: active ? _teal : Colors.white,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: active ? _teal : const Color(0xFFD1D5DB),
                              width: 1.5,
                            ),
                          ),
                          child: active
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 13,
                                )
                              : null,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: _textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12 + MediaQuery.of(ctx).padding.bottom,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Existing attachment tile ───────────────────────────

  Widget _existingAttTile(int index, Map<String, dynamic> att) {
    final name = att['originalName']?.toString() ?? 'Attachment';
    final url = att['url']?.toString() ?? '';
    final type = att['resourceType']?.toString() ?? 'image';
    final isPdf = type == 'raw' || name.toLowerCase().endsWith('.pdf');

    return GestureDetector(
      onTap: () {
        if (isPdf) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfViewerPage(url: url, fileName: name),
            ),
          );
        } else {
          _openImageViewer(url, null);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(
              isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
              size: 16,
              color: isPdf ? Colors.red[400] : _teal,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _deleteExistingAttachment(index, att),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  size: 14,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── New file tile ──────────────────────────────────────

  Widget _newFileTile(int index, PlatformFile f) {
    final ext = path.extension(f.name).toLowerCase();
    final isPdf = ext == '.pdf';
    return GestureDetector(
      onTap: () {
        if (!isPdf) {
          _openImageViewer(null, f.path);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _tealLight,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _teal.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
              size: 16,
              color: isPdf ? Colors.red[400] : _teal,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(f.size / 1024).toStringAsFixed(0)} KB',
                    style: const TextStyle(fontSize: 10, color: _textGrey),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _newPickedFiles.removeAt(index)),
              child: const Icon(Icons.close_rounded, size: 16, color: _textGrey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: _textGrey,
      letterSpacing: 0.8,
    ),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
    filled: true,
    fillColor: _bg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: const BorderSide(color: _teal, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
  );
}

// ── Editor's Tip background painter ───────────────────────

class _TipBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Abstract pen/paper background
    final p = Paint()
      ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    // Horizontal ruled lines
    for (double y = h * 0.20; y < h; y += h * 0.12) {
      canvas.drawLine(Offset(0, y), Offset(w, y), p);
    }
    // Pen illustration
    final penP = Paint()
      ..color = const Color(0xFF78909C).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final pen = Path()
      ..moveTo(w * 0.70, h * 0.15)
      ..lineTo(w * 0.52, h * 0.72)
      ..lineTo(w * 0.50, h * 0.80)
      ..lineTo(w * 0.56, h * 0.65)
      ..close();
    canvas.drawPath(
      pen,
      penP
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF90A4AE).withValues(alpha: 0.3),
    );
    canvas.drawPath(
      pen,
      penP
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF78909C).withValues(alpha: 0.6),
    );
    // Pen body
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.63, h * 0.38),
        width: 10,
        height: 38,
      ),
      const Radius.circular(3),
    );
    canvas.save();
    canvas.translate(w * 0.63, h * 0.38);
    canvas.rotate(-0.65);
    canvas.translate(-w * 0.63, -h * 0.38);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFF78909C).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _TopToastWidget({required this.message, required this.onDismiss});

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto dismiss after 4 seconds to give the user enough time to read
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return SlideTransition(
              position: _offsetAnimation,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Slate-dark background
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _controller.reverse().then((_) {
                      widget.onDismiss();
                    });
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white60,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

