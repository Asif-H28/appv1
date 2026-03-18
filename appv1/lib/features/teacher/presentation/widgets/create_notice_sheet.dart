import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';

class CreateNoticeSheet extends StatefulWidget {
  final String classId;
  final String createdBy;
  final VoidCallback onCreated;

  const CreateNoticeSheet({
    required this.classId,
    required this.createdBy,
    required this.onCreated,
  });

  @override
  _CreateNoticeSheetState createState() => _CreateNoticeSheetState();
}

class _CreateNoticeSheetState extends State<CreateNoticeSheet> {
  static const Color _accent = Colors.teal;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _expiresAt;
  bool _isSaving = false;

  final List<File> _pickedImages = [];
  final List<File> _pickedPdfs = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(
        () => _pickedImages.addAll(picked.map((x) => File(x.path)).toList()),
      );
    }
  }

  Future<void> _pickCamera() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) setState(() => _pickedImages.add(File(photo.path)));
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(
        () =>
            _pickedPdfs.addAll(result.files.map((f) => File(f.path!)).toList()),
      );
    }
  }

  void _removeImage(int index) => setState(() => _pickedImages.removeAt(index));
  void _removePdf(int index) => setState(() => _pickedPdfs.removeAt(index));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
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

  String _formatDate(DateTime dt) {
    const months = [
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _fileName(File f) => f.path.split('/').last;

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnackBar('Title is required.', Colors.red[600]!);
      return;
    }
    setState(() => _isSaving = true);

    try {
      final hasFiles = _pickedImages.isNotEmpty || _pickedPdfs.isNotEmpty;
      http.Response response;

      if (hasFiles) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://appv1backend.onrender.com/api/notice/create'),
        );
        request.fields['title'] = _titleCtrl.text.trim();
        request.fields['description'] = _descCtrl.text.trim();
        request.fields['createdBy'] = widget.createdBy;
        request.fields['classroomId'] = widget.classId;
        if (_expiresAt != null) {
          request.fields['expiresAt'] = _expiresAt!.toUtc().toIso8601String();
        }

        for (final img in _pickedImages) {
          final ext = _fileName(img).split('.').last.toLowerCase();
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              img.path,
              contentType: MediaType('image', ext),
            ),
          );
        }

        for (final pdf in _pickedPdfs) {
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
        // ── fix: dart:convert is imported at top, use jsonEncode directly ──
        final body = <String, dynamic>{
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'createdBy': widget.createdBy,
          'classroomId': widget.classId,
        };
        if (_expiresAt != null) {
          body['expiresAt'] = _expiresAt!.toUtc().toIso8601String();
        }
        response = await http.post(
          Uri.parse('https://appv1backend.onrender.com/api/notice/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body), // ← from dart:convert at top-level import
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        widget.onCreated();
        _showSnackBar('Notice created! 🎉', Colors.green[600]!);
      } else {
        _showSnackBar(
          'Failed to create notice. (${response.statusCode})',
          Colors.red[600]!,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar(
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Something went wrong.',
        Colors.red[600]!,
      );
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _handle(),
            SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.campaign_rounded, color: _accent, size: 22),
                ),
                SizedBox(width: 12),
                Text(
                  'Create Notice',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 22),

            _label('Notice Title *'),
            SizedBox(height: 6),
            _inputField(_titleCtrl, 'e.g. Holiday Notice', Icons.title_rounded),
            SizedBox(height: 16),

            _label('Description'),
            SizedBox(height: 6),
            _inputField(
              _descCtrl,
              'Write notice details here...',
              Icons.description_rounded,
              maxLines: 4,
            ),
            SizedBox(height: 16),

            _label('Expiry Date (optional)'),
            SizedBox(height: 6),
            _datePickerTile(),
            SizedBox(height: 20),

            _label('Attachments (optional)'),
            SizedBox(height: 10),
            _attachmentButtons(),
            SizedBox(height: 12),

            if (_pickedImages.isNotEmpty) ...[
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pickedImages.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8),
                  itemBuilder: (_, i) => _imagePreview(i),
                ),
              ),
              SizedBox(height: 12),
            ],

            if (_pickedPdfs.isNotEmpty) ...[
              ...List.generate(
                _pickedPdfs.length,
                (i) => _pdfPreview(_pickedPdfs[i], i),
              ),
              SizedBox(height: 12),
            ],

            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _accent.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Create Notice',
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
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: c.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 20),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview(int index) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          _pickedImages[index],
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      ),
      Positioned(
        top: 4,
        right: 4,
        child: GestureDetector(
          onTap: () => _removeImage(index),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
          ),
        ),
      ),
    ],
  );

  Widget _pdfPreview(File file, int index) => Container(
    margin: EdgeInsets.only(bottom: 8),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.04),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.picture_as_pdf_rounded, color: Colors.red[600], size: 22),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            _fileName(file),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () => _removePdf(index),
          child: Icon(Icons.close_rounded, size: 18, color: Colors.grey[500]),
        ),
      ],
    ),
  );

  Widget _datePickerTile() => GestureDetector(
    onTap: _pickDate,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Icon(Icons.event_rounded, color: _accent, size: 20),
          SizedBox(width: 12),
          Text(
            _expiresAt != null
                ? _formatDate(_expiresAt!)
                : 'Select expiry date',
            style: TextStyle(
              color: _expiresAt != null
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          Spacer(),
          if (_expiresAt != null)
            GestureDetector(
              onTap: () => setState(() => _expiresAt = null),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ),
        ],
      ),
    ),
  );

  Widget _handle() => Center(
    child: Container(
      width: 40,
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
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.4,
    ),
  );

  Widget _inputField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) => Container(
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
      maxLines: maxLines,
      style: TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.5),
          fontSize: 14,
        ),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: _accent, size: 20)
            : Padding(
                padding: EdgeInsets.fromLTRB(12, 14, 0, 0),
                child: Icon(icon, color: _accent, size: 20),
              ),
        prefixIconConstraints: maxLines > 1
            ? BoxConstraints(minWidth: 44, minHeight: 0)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _accent.withOpacity(0.4), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}
