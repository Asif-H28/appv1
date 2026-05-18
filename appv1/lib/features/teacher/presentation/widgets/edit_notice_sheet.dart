import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';

class EditNoticeSheet extends StatefulWidget {
  final Map<String, dynamic> notice;
  final VoidCallback onUpdated;

  const EditNoticeSheet({required this.notice, required this.onUpdated});

  @override
  _EditNoticeSheetState createState() => _EditNoticeSheetState();
}

class _EditNoticeSheetState extends State<EditNoticeSheet> {
  static const Color _accent = Colors.teal;
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  DateTime? _expiresAt;
  bool _isSaving = false;

  final List<File> _newImages = [];
  final List<File> _newPdfs = [];

  // ── Existing attachments — user can mark for removal ──
  late List<Map<String, dynamic>> _existingAttachments;
  final Set<int> _removedIndexes = {};

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text: widget.notice['title']?.toString() ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.notice['description']?.toString() ?? '',
    );
    final exp = widget.notice['expiresAt']?.toString();
    if (exp != null) {
      try {
        _expiresAt = DateTime.parse(exp).toLocal();
      } catch (_) {}
    }
    final raw = widget.notice['attachments'] as List? ?? [];
    _existingAttachments = raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
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
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: _accent)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(
        () => _expiresAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(
        () => _newImages.addAll(picked.map((x) => File(x.path)).toList()),
      );
    }
  }

  Future<void> _pickCamera() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) setState(() => _newImages.add(File(photo.path)));
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(
        () => _newPdfs.addAll(result.files.map((f) => File(f.path!)).toList()),
      );
    }
  }

  String _fileName(File f) => f.path.split('/').last;

  bool _isPdf(Map<String, dynamic> a) {
    final url = a['url']?.toString().toLowerCase() ?? '';
    final type = a['resourceType']?.toString().toLowerCase() ?? '';
    final fmt = a['format']?.toString().toLowerCase() ?? '';
    final name =
        (a['publicId']?.toString().toLowerCase() ??
        a['originalFilename']?.toString().toLowerCase() ??
        '');
    return url.contains('.pdf') ||
        url.contains('/raw/upload/') ||
        type == 'raw' ||
        type == 'pdf' ||
        fmt == 'pdf' ||
        name.endsWith('.pdf');
  }

  bool _isImage(Map<String, dynamic> a) {
    if (_isPdf(a)) return false;
    final url = a['url']?.toString().toLowerCase() ?? '';
    final type = a['resourceType']?.toString().toLowerCase() ?? '';
    final fmt = a['format']?.toString().toLowerCase() ?? '';
    return type == 'image' ||
        fmt == 'jpg' ||
        fmt == 'jpeg' ||
        fmt == 'png' ||
        fmt == 'webp' ||
        fmt == 'gif' ||
        url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png') ||
        url.contains('.webp') ||
        url.contains('.gif');
  }

  String _attachmentLabel(Map<String, dynamic> a) {
    final rawId =
        a['publicId']?.toString() ?? a['originalFilename']?.toString() ?? '';
    if (rawId.isNotEmpty) return rawId.split('/').last;
    final url = a['url']?.toString() ?? '';
    return url.split('/').last.split('?').first;
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Title is required.', Colors.red[600]!);
      return;
    }
    setState(() => _isSaving = true);

    try {
      final noticeId =
          widget.notice['noticeId']?.toString() ??
          widget.notice['_id']?.toString() ??
          '';

      // ── Step 1: DELETE each marked attachment via dedicated endpoint ──
      for (final i in _removedIndexes) {
        final att = _existingAttachments[i];
        final publicId = att['publicId']?.toString() ?? '';
        if (publicId.isEmpty) continue;

        // Determine resourceType
        String resourceType = 'image';
        if (_isPdf(att)) {
          resourceType = att['resourceType']?.toString().toLowerCase() == 'raw'
              ? 'raw'
              : 'pdf';
        }

        try {
          await http.delete(
            Uri.parse(
              '${ApiConstants.apiBaseUrl}/notice/$noticeId/attachment',
            ),
            headers: await ApiService.getHeaders(),
            body: jsonEncode({
              'publicId': publicId,
              'resourceType': resourceType,
            }),
          );
        } catch (_) {
          // Don't block the whole update if one delete fails
        }
      }

      // ── Step 2: PUT to update text fields + upload any new files ──
      final hasNewFiles = _newImages.isNotEmpty || _newPdfs.isNotEmpty;
      http.Response response;

      if (hasNewFiles) {
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse('${ApiConstants.apiBaseUrl}/notice/$noticeId'),
        );
        request.fields['title'] = _titleCtrl.text.trim();
        request.fields['description'] = _descCtrl.text.trim();
        if (_expiresAt != null) {
          request.fields['expiresAt'] = _expiresAt!.toUtc().toIso8601String();
        }
        for (final img in _newImages) {
          final ext = _fileName(img).split('.').last.toLowerCase();
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              img.path,
              contentType: MediaType('image', ext),
            ),
          );
        }
        for (final pdf in _newPdfs) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              pdf.path,
              contentType: MediaType('application', 'pdf'),
            ),
          );
        }
        final streamed = await request.send();
        response = await http.Response.fromStream(streamed);
      } else {
        // ── Only text fields changed (or only deletions) ──
        final body = <String, dynamic>{
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
        };
        if (_expiresAt != null) {
          body['expiresAt'] = _expiresAt!.toUtc().toIso8601String();
        }
        response = await http.put(
          Uri.parse('${ApiConstants.apiBaseUrl}/notice/$noticeId'),
          headers: await ApiService.getHeaders(),
          body: jsonEncode(body),
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.statusCode == 200) {
        Navigator.pop(context);
        widget.onUpdated(); // ← triggers refresh on parent screen
        _snack('Notice updated!', Colors.green[600]!);
      } else {
        _snack('Failed to update. (${response.statusCode})', Colors.red[600]!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _snack(
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Something went wrong.',
        Colors.red[600]!,
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 16),

            // ── Sheet title ──
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(Icons.edit_rounded, color: _accent, size: 16),
                ),
                SizedBox(width: 10),
                Text(
                  'Edit Notice',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),

            // ── Title ──
            _label('Notice Title *'),
            SizedBox(height: 5),
            _inputField(
              ctrl: _titleCtrl,
              hint: 'Notice title',
              icon: Icons.title_rounded,
            ),
            SizedBox(height: 13),

            // ── Description ──
            _label('Description'),
            SizedBox(height: 5),
            _inputField(
              ctrl: _descCtrl,
              hint: 'Notice description...',
              icon: Icons.description_rounded,
              maxLines: 4,
            ),
            SizedBox(height: 13),

            // ── Expiry ──
            _label('Expiry Date'),
            SizedBox(height: 5),
            _datePickerTile(),
            SizedBox(height: 16),

            // ── Existing attachments with remove option ──
            if (_existingAttachments.isNotEmpty) ...[
              Row(
                children: [
                  _label('Existing Attachments'),
                  Spacer(),
                  if (_removedIndexes.isNotEmpty)
                    Text(
                      '${_removedIndexes.length} will be removed',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6),
              ..._existingAttachments.asMap().entries.map((entry) {
                final i = entry.key;
                final att = entry.value;
                final isRemoved = _removedIndexes.contains(i);
                final isPdf = _isPdf(att);
                final isImg = _isImage(att);
                final label = _attachmentLabel(att);

                return Container(
                  margin: EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isRemoved
                        ? Colors.red.withOpacity(0.04)
                        : _accent.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isRemoved
                          ? Colors.red.withOpacity(0.25)
                          : _accent.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // ── Image thumbnail or file icon ──
                      if (isImg)
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(3),
                            bottomLeft: Radius.circular(3),
                          ),
                          child: Stack(
                            children: [
                              Image.network(
                                att['url']?.toString() ?? '',
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52,
                                  height: 52,
                                  color: Colors.grey[100],
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    color: Colors.grey[400],
                                    size: 18,
                                  ),
                                ),
                              ),
                              if (isRemoved)
                                Container(
                                  width: 52,
                                  height: 52,
                                  color: Colors.red.withOpacity(0.35),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        Container(
                          margin: EdgeInsets.all(9),
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isRemoved
                                ? Colors.red.withOpacity(0.1)
                                : _accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Icon(
                            isPdf
                                ? Icons.picture_as_pdf_rounded
                                : Icons.insert_drive_file_rounded,
                            color: isRemoved ? Colors.red[400] : _accent,
                            size: 15,
                          ),
                        ),

                      SizedBox(width: 8),

                      // ── File name ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label.isNotEmpty ? label : 'Attachment ${i + 1}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isRemoved
                                    ? Colors.red[400]
                                    : AppColors.textPrimary,
                                decoration: isRemoved
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isRemoved
                                  ? 'Will be removed'
                                  : (isPdf ? 'PDF Document' : 'Image'),
                              style: TextStyle(
                                fontSize: 10,
                                color: isRemoved
                                    ? Colors.red[400]
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Toggle remove / restore ──
                      GestureDetector(
                        onTap: () => setState(() {
                          if (isRemoved) {
                            _removedIndexes.remove(i);
                          } else {
                            _removedIndexes.add(i);
                          }
                        }),
                        child: Container(
                          margin: EdgeInsets.only(right: 9),
                          padding: EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isRemoved
                                ? Colors.green.withOpacity(0.08)
                                : Colors.red.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: isRemoved
                                  ? Colors.green.withOpacity(0.25)
                                  : Colors.red.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isRemoved
                                    ? Icons.restore_rounded
                                    : Icons.delete_outline_rounded,
                                size: 11,
                                color: isRemoved
                                    ? Colors.green[600]
                                    : Colors.red[400],
                              ),
                              SizedBox(width: 3),
                              Text(
                                isRemoved ? 'Restore' : 'Remove',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isRemoved
                                      ? Colors.green[600]
                                      : Colors.red[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 8),
            ],

            // ── Append new files ──
            _label('Append New Files (optional)'),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _attachBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: _pickImages,
                  ),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: _attachBtn(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: _pickCamera,
                  ),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: _attachBtn(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'PDF',
                    onTap: _pickPdf,
                  ),
                ),
              ],
            ),

            // ── New image previews ──
            if (_newImages.isNotEmpty) ...[
              SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newImages.length,
                  separatorBuilder: (_, __) => SizedBox(width: 6),
                  itemBuilder: (_, i) => _imageThumb(i),
                ),
              ),
            ],

            // ── New PDF previews ──
            if (_newPdfs.isNotEmpty) ...[
              SizedBox(height: 10),
              ...List.generate(
                _newPdfs.length,
                (i) => _pdfTile(_newPdfs[i], i),
              ),
            ],

            SizedBox(height: 20),

            // ── Submit ──
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _accent.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  elevation: 0,
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
                    : Text(
                        'Update Notice',
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
    );
  }

  Widget _attachBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _accent, size: 18),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: _accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _imageThumb(int index) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.file(
          _newImages[index],
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
      Positioned(
        top: 3,
        right: 3,
        child: GestureDetector(
          onTap: () => setState(() => _newImages.removeAt(index)),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded, color: Colors.white, size: 11),
          ),
        ),
      ),
    ],
  );

  Widget _pdfTile(File file, int index) => Container(
    margin: EdgeInsets.only(bottom: 6),
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: _accent.withOpacity(0.04),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: _accent.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(Icons.picture_as_pdf_rounded, color: _accent, size: 13),
        ),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            _fileName(file),
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _newPdfs.removeAt(index)),
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(Icons.close_rounded, size: 12, color: Colors.grey[500]),
          ),
        ),
      ],
    ),
  );

  Widget _datePickerTile() => GestureDetector(
    onTap: _pickDate,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.event_rounded, color: _accent, size: 16),
          SizedBox(width: 10),
          Text(
            _expiresAt != null
                ? _formatDate(_expiresAt!)
                : 'Select expiry date',
            style: TextStyle(
              color: _expiresAt != null
                  ? AppColors.textPrimary
                  : Colors.grey[400],
              fontSize: 13,
            ),
          ),
          Spacer(),
          if (_expiresAt != null)
            GestureDetector(
              onTap: () => setState(() => _expiresAt = null),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.grey[400],
              ),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
        ],
      ),
    ),
  );

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.3,
    ),
  );

  Widget _inputField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: TextField(
      controller: ctrl,
      cursorColor: _accent,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: _accent, size: 16)
            : Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 0, 0),
                child: Icon(icon, color: _accent, size: 16),
              ),
        prefixIconConstraints: maxLines > 1
            ? BoxConstraints(minWidth: 40, minHeight: 0)
            : null,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      ),
    ),
  );
}

