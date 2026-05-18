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

class EditNoteSheet extends StatefulWidget {
  final Map<String, dynamic> note;
  final VoidCallback onUpdated;

  const EditNoteSheet({required this.note, required this.onUpdated});

  @override
  _EditNoteSheetState createState() => _EditNoteSheetState();
}

class _EditNoteSheetState extends State<EditNoteSheet> {
  static const Color _accent = Colors.teal;
  late TextEditingController _titleCtrl;
  final List<File> _newImages = [];
  final List<File> _newPdfs = [];
  bool _isSaving = false;

  late List<Map<String, dynamic>> _existingAttachments;
  final Set<int> _removedIndexes = {};
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text: widget.note['title']?.toString() ?? '',
    );
    final raw = widget.note['attachments'] as List? ?? [];
    _existingAttachments = raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String _fileName(File f) => f.path.split('/').last;

  bool _isPdf(Map<String, dynamic> a) {
    final url = a['url']?.toString().toLowerCase() ?? '';
    final type = a['type']?.toString().toLowerCase() ?? '';
    return type == 'pdf' || url.contains('.pdf');
  }

  bool _isImage(Map<String, dynamic> a) {
    if (_isPdf(a)) return false;
    final url = a['url']?.toString().toLowerCase() ?? '';
    final type = a['type']?.toString().toLowerCase() ?? '';
    return type == 'image' ||
        url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png') ||
        url.contains('.webp');
  }

  String _attachmentLabel(Map<String, dynamic> a) {
    final fn = a['filename']?.toString() ?? '';
    if (fn.isNotEmpty) return fn;
    final rawId = a['publicId']?.toString() ?? '';
    if (rawId.isNotEmpty) return rawId.split('/').last;
    final url = a['url']?.toString() ?? '';
    return url.split('/').last.split('?').first;
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(
        () => _newImages.addAll(picked.map((x) => File(x.path)).toList()),
      );
    }
  }

  Future<void> _pickCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
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

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() {
        _titleError = 'Title is required';
      });
      _snack('Title is required.', Colors.red[600]!);
      return;
    }
    setState(() {
      _titleError = null;
      _isSaving = true;
    });

    try {
      final notesId =
          widget.note['notesId']?.toString() ??
          widget.note['_id']?.toString() ??
          '';

      // ── Step 1: DELETE removed attachments ──
      for (final i in _removedIndexes) {
        final att = _existingAttachments[i];
        final publicId = att['publicId']?.toString() ?? '';
        if (publicId.isEmpty) continue;
        final resourceType = _isPdf(att) ? 'pdf' : 'image';
        try {
          await http.delete(
            Uri.parse(
              '${ApiConstants.apiBaseUrl}/notes/$notesId/attachment',
            ),
            headers: await ApiService.getHeaders(),
            body: jsonEncode({
              'publicId': publicId,
              'resourceType': resourceType,
            }),
          );
        } catch (_) {}
      }

      // ── Step 2: PUT title + new files ──
      final hasNewFiles = _newImages.isNotEmpty || _newPdfs.isNotEmpty;
      http.Response response;

      if (hasNewFiles) {
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse('${ApiConstants.apiBaseUrl}/notes/$notesId'),
        );
        request.headers.addAll(await ApiService.getHeaders());
        request.fields['title'] = _titleCtrl.text.trim();
        request.fields['notesSharedBy'] =
            widget.note['notesSharedBy']?.toString() ?? '';
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
        response = await http.put(
          Uri.parse('${ApiConstants.apiBaseUrl}/notes/$notesId'),
          headers: await ApiService.getHeaders(),
          body: jsonEncode({
            'title': _titleCtrl.text.trim(),
            'notesSharedBy': widget.note['notesSharedBy']?.toString() ?? '',
          }),
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.statusCode == 200) {
        Navigator.pop(context);
        widget.onUpdated();
        _snack('Note updated!', Colors.green[600]!);
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
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  color == Colors.green[600]
                      ? Icons.check_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
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

            // ── Header ──
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
                  'Edit Note',
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
            _label('Note Title *'),
            SizedBox(height: 5),
            _inputField(
              _titleCtrl,
              'Note title',
              Icons.title_rounded,
              errorText: _titleError,
            ),
            SizedBox(height: 16),

            // ── Existing attachments with remove/restore ──
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
                      // ── Thumbnail or icon ──
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
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[100],
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    color: Colors.grey[400],
                                    size: 16,
                                  ),
                                ),
                              ),
                              if (isRemoved)
                                Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.red.withOpacity(0.35),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        Container(
                          margin: EdgeInsets.all(8),
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
                            size: 14,
                          ),
                        ),

                      SizedBox(width: 8),

                      // ── Label ──
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

                      // ── Remove / Restore toggle ──
                      GestureDetector(
                        onTap: () => setState(
                          () => isRemoved
                              ? _removedIndexes.remove(i)
                              : _removedIndexes.add(i),
                        ),
                        child: Container(
                          margin: EdgeInsets.only(right: 8),
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
              SizedBox(height: 10),
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
              SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newImages.length,
                  separatorBuilder: (_, __) => SizedBox(width: 5),
                  itemBuilder: (_, i) => _imageThumb(
                    _newImages[i],
                    () => setState(() => _newImages.removeAt(i)),
                  ),
                ),
              ),
            ],

            // ── New PDF previews ──
            if (_newPdfs.isNotEmpty) ...[
              SizedBox(height: 8),
              ...List.generate(
                _newPdfs.length,
                (i) => _pdfTile(
                  _newPdfs[i],
                  () => setState(() => _newPdfs.removeAt(i)),
                ),
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
                        'Update Note',
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

  Widget _imageThumb(File file, VoidCallback onRemove) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
      ),
      Positioned(
        top: 3,
        right: 3,
        child: GestureDetector(
          onTap: onRemove,
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

  Widget _pdfTile(File file, VoidCallback onRemove) => Container(
    margin: EdgeInsets.only(bottom: 5),
    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: _accent.withOpacity(0.04),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: _accent.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(Icons.picture_as_pdf_rounded, color: _accent, size: 12),
        ),
        SizedBox(width: 8),
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
          onTap: onRemove,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(Icons.close_rounded, size: 11, color: Colors.grey[500]),
          ),
        ),
      ],
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

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon, {String? errorText}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: errorText != null ? Colors.red[600]! : Colors.grey[200]!,
                width: errorText != null ? 1.2 : 1.0,
              ),
            ),
            child: TextField(
              controller: ctrl,
              cursorColor: _accent,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              onChanged: (_) {
                if (_titleError != null) {
                  setState(() => _titleError = null);
                }
              },
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: Icon(icon, color: errorText != null ? Colors.red[600]! : _accent, size: 16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              ),
            ),
          ),
          if (errorText != null) ...[
            SizedBox(height: 4),
            Text(
              errorText,
              style: TextStyle(color: Colors.red[600], fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      );
}

