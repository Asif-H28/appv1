import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';

class CreateNoteSheet extends StatefulWidget {
  final String classId;
  final String orgId;
  final String sharedBy;
  final VoidCallback onCreated;

  const CreateNoteSheet({
    required this.classId,
    required this.orgId,
    required this.sharedBy,
    required this.onCreated,
  });

  @override
  _CreateNoteSheetState createState() => _CreateNoteSheetState();
}

class _CreateNoteSheetState extends State<CreateNoteSheet> {
  static const Color _accent = Colors.teal;
  final _titleCtrl = TextEditingController();
  final List<File> _images = [];
  final List<File> _pdfs = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String _fileName(File f) => f.path.split('/').last;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked.map((x) => File(x.path)).toList()));
    }
  }

  Future<void> _pickCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) setState(() => _images.add(File(photo.path)));
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(
        () => _pdfs.addAll(result.files.map((f) => File(f.path!)).toList()),
      );
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Title is required.', Colors.red[600]!);
      return;
    }
    setState(() => _isSaving = true);

    try {
      final hasFiles = _images.isNotEmpty || _pdfs.isNotEmpty;
      http.Response response;

      if (hasFiles) {
        // ── Multipart ──
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://appv1backend.onrender.com/api/notes/create'),
        );
        request.fields['title'] = _titleCtrl.text.trim();
        request.fields['notesSharedBy'] = widget.sharedBy;
        request.fields['classId'] = widget.classId;
        request.fields['orgId'] = widget.orgId;

        for (final img in _images) {
          final ext = _fileName(img).split('.').last.toLowerCase();
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              img.path,
              contentType: MediaType('image', ext),
            ),
          );
        }
        for (final pdf in _pdfs) {
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
        // ── JSON ──
        response = await http.post(
          Uri.parse('https://appv1backend.onrender.com/api/notes/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': _titleCtrl.text.trim(),
            'notesSharedBy': widget.sharedBy,
            'classId': widget.classId,
            'orgId': widget.orgId,
          }),
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        widget.onCreated();
        _snack('Note created! 🎉', Colors.green[600]!);
      } else {
        _snack(
          'Failed to create note. (${response.statusCode})',
          Colors.red[600]!,
        );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──
            _handle(),
            SizedBox(height: 16),

            // ── Header ──
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: _accent,
                    size: 18,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Add Note',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),

            // ── Title ──
            _label('Note Title *'),
            SizedBox(height: 6),
            _inputField(
              _titleCtrl,
              'e.g. Chapter 1 - Algebra',
              Icons.title_rounded,
            ),
            SizedBox(height: 18),

            // ── Attachments ──
            _label('Attachments (optional)'),
            SizedBox(height: 8),
            _attachmentButtons(),
            SizedBox(height: 10),

            // ── Image previews ──
            if (_images.isNotEmpty) ...[
              SizedBox(
                height: 86,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => SizedBox(width: 6),
                  itemBuilder: (_, i) => _imageThumb(_images[i], () {
                    setState(() => _images.removeAt(i));
                  }),
                ),
              ),
              SizedBox(height: 10),
            ],

            // ── PDF previews ──
            if (_pdfs.isNotEmpty) ...[
              ...List.generate(
                _pdfs.length,
                (i) => _pdfTile(_pdfs[i], () {
                  setState(() => _pdfs.removeAt(i));
                }),
              ),
              SizedBox(height: 10),
            ],

            SizedBox(height: 6),

            // ── Submit ──
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _accent.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
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
                    : Text(
                        'Create Note',
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

  Widget _attachmentButtons() => Row(
    children: [
      Expanded(
        child: _attachBtn(
          icon: Icons.photo_library_rounded,
          label: 'Gallery',
          onTap: _pickImages,
        ),
      ),
      SizedBox(width: 8),
      Expanded(
        child: _attachBtn(
          icon: Icons.camera_alt_rounded,
          label: 'Camera',
          onTap: _pickCamera,
        ),
      ),
      SizedBox(width: 8),
      Expanded(
        child: _attachBtn(
          icon: Icons.picture_as_pdf_rounded,
          label: 'PDF',
          onTap: _pickPdf,
          color: Colors.red[600]!,
        ),
      ),
    ],
  );

  Widget _attachBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? _accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: c.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 18),
            SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageThumb(File file, VoidCallback onRemove) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(file, width: 86, height: 86, fit: BoxFit.cover),
      ),
      Positioned(
        top: 3,
        right: 3,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded, color: Colors.white, size: 13),
          ),
        ),
      ),
    ],
  );

  Widget _pdfTile(File file, VoidCallback onRemove) => Container(
    margin: EdgeInsets.only(bottom: 6),
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.04),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.withOpacity(0.18)),
    ),
    child: Row(
      children: [
        Icon(Icons.picture_as_pdf_rounded, color: Colors.red[600], size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            _fileName(file),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: onRemove,
          child: Icon(Icons.close_rounded, size: 16, color: Colors.grey[500]),
        ),
      ],
    ),
  );

  Widget _handle() => Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
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

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: ctrl,
          cursorColor: _accent,
          style: TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: _accent, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _accent.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      );
}
