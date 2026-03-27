import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/constants/app_colors.dart';
import '../teacher/presentation/widgets/pdf_viewer_page.dart';

const Color _accent = Colors.teal;

class StudentNoteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  final String fileType;
  final String fileUrl;
  final String title;

  const StudentNoteDetailScreen({
    required this.note,
    required this.fileType,
    required this.fileUrl,
    required this.title,
  });

  @override
  _StudentNoteDetailScreenState createState() =>
      _StudentNoteDetailScreenState();
}

class _StudentNoteDetailScreenState extends State<StudentNoteDetailScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _downloadStatus = '';

  // ── Download file ─────────────────────────────────────

  Future<void> _downloadFile() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadStatus = 'Starting download...';
    });

    try {
      setState(() => _downloadStatus = 'Downloading...');

      final res = await http.get(Uri.parse(widget.fileUrl));

      if (res.statusCode != 200) {
        setState(() {
          _isDownloading = false;
          _downloadStatus = '';
        });
        _snack('Download failed. Try again.', Colors.red[600]!);
        return;
      }

      setState(() {
        _downloadProgress = 0.7;
        _downloadStatus = 'Saving file...';
      });

      final dir = await getApplicationDocumentsDirectory();
      final ext = widget.fileType == 'pdf' ? '.pdf' : '.jpg';
      final sanitized = widget.title.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final fileName = '${sanitized.isNotEmpty ? sanitized : 'note'}$ext';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(res.bodyBytes);

      setState(() {
        _downloadProgress = 1.0;
        _downloadStatus = 'Download complete';
        _isDownloading = false;
      });

      _snack('Saved: $fileName', Colors.green[600]!);

      // Open the file after download
      await OpenFile.open(file.path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadStatus = '';
      });
      _snack('Download failed. Check your connection.', Colors.red[600]!);
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
    final description = widget.note['description']?.toString() ?? '';
    final uploadedAt =
        widget.note['createdAt']?.toString() ??
        widget.note['uploadedAt']?.toString() ??
        '';

    String formattedDate = '';
    if (uploadedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(uploadedAt).toLocal();
        const months = [
          '',
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
        formattedDate = '${dt.day} ${months[dt.month]} ${dt.year}';
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            // ── Header ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, _accent.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 16, 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          widget.fileType == 'pdf'
                              ? Icons.picture_as_pdf_rounded
                              : Icons.image_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.fileType == 'pdf'
                                  ? 'PDF Document'
                                  : 'Image',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 10,
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

            // ── Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(14, 16, 14, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Info card ──
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text(
                              description,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                          ],
                          if (formattedDate.isNotEmpty) ...[
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Uploaded $formattedDate',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 12),

                    // ── Preview card ──
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: widget.fileType == 'image'
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Image.network(
                                widget.fileUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: _accent,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) =>
                                    _filePreviewFallback(),
                              ),
                            )
                          : _pdfPreviewTile(),
                    ),
                    SizedBox(height: 16),

                    // ── Download button ──
                    _buildDownloadButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PDF preview tile (tap to open full viewer) ─────────

  Widget _pdfPreviewTile() {
    return InkWell(
      borderRadius: BorderRadius.circular(3),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PdfViewerPage(url: widget.fileUrl, fileName: widget.title),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.red[600],
                size: 26,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Tap to view PDF',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _accent.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_rounded, size: 12, color: _accent),
                  SizedBox(width: 4),
                  Text(
                    'View',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filePreviewFallback() => Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      children: [
        Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40),
        SizedBox(height: 8),
        Text(
          'Preview not available',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );

  // ── Download button ────────────────────────────────────

  Widget _buildDownloadButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isDownloading ? null : _downloadFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _accent.withOpacity(0.45),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: _isDownloading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        _downloadStatus.isNotEmpty
                            ? _downloadStatus
                            : 'Downloading...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Download ${widget.fileType == 'pdf' ? 'PDF' : 'Image'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // ── Progress bar ──
        if (_isDownloading) ...[
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              minHeight: 5,
              backgroundColor: _accent.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          SizedBox(height: 6),
          Text(
            _downloadStatus,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ],
    );
  }
}
