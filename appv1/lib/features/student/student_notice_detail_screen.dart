import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../teacher/presentation/widgets/pdf_viewer_page.dart';

const Color _accent = Colors.teal;

class StudentNoticeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notice;
  const StudentNoticeDetailScreen({required this.notice});

  String get _title => notice['title']?.toString() ?? 'Notice';

  String get _description => notice['description']?.toString() ?? '';

  String get _createdBy => notice['createdBy']?.toString() ?? '';

  List<dynamic> get _attachments =>
      (notice['attachments'] as List<dynamic>?) ?? [];

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
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
      const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[dt.weekday]}, ${dt.day} ${months[dt.month]} ${dt.year}  •  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  String get _createdAt => _formatDate(notice['createdAt']?.toString() ?? '');

  String get _expiresAt => _formatDate(notice['expiresAt']?.toString() ?? '');

  List<Map<String, dynamic>> get _images => _attachments
      .map((a) => a as Map<String, dynamic>)
      .where((a) => a['type']?.toString() != 'pdf')
      .toList();

  List<Map<String, dynamic>> get _pdfs => _attachments
      .map((a) => a as Map<String, dynamic>)
      .where((a) => a['type']?.toString() == 'pdf')
      .toList();

  @override
  Widget build(BuildContext context) {
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
                          Icons.campaign_rounded,
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
                              'Notice Detail',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Full announcement',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 11,
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
                    // ── Main notice card ──
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_accent, _accent.withOpacity(0.4)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Title ──
                                Text(
                                  _title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: 10),

                                // ── Meta row ──
                                _metaRow(
                                  Icons.person_rounded,
                                  _createdBy,
                                  _accent,
                                ),
                                if (_createdAt.isNotEmpty) ...[
                                  SizedBox(height: 6),
                                  _metaRow(
                                    Icons.calendar_today_rounded,
                                    _createdAt,
                                    AppColors.textSecondary,
                                  ),
                                ],
                                if (_expiresAt.isNotEmpty) ...[
                                  SizedBox(height: 6),
                                  _metaRow(
                                    Icons.access_time_rounded,
                                    'Expires: $_expiresAt',
                                    Colors.orange[700]!,
                                  ),
                                ],

                                SizedBox(height: 14),
                                Divider(height: 1, color: Colors.grey[100]),
                                SizedBox(height: 14),

                                // ── Description ──
                                Text(
                                  _description,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13.5,
                                    height: 1.65,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Images ──
                    if (_images.isNotEmpty) ...[
                      SizedBox(height: 16),
                      _sectionHeader('Images', Icons.image_rounded),
                      SizedBox(height: 10),
                      ..._images.map((img) => _imageCard(context, img)),
                    ],

                    // ── PDFs ──
                    if (_pdfs.isNotEmpty) ...[
                      SizedBox(height: 16),
                      _sectionHeader('Attachments', Icons.attach_file_rounded),
                      SizedBox(height: 10),
                      ..._pdfs.map((pdf) => _pdfCard(context, pdf)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image card ────────────────────────────────────────

  Widget _imageCard(BuildContext context, Map<String, dynamic> img) {
    final url = img['url']?.toString() ?? '';
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: GestureDetector(
          onTap: () => _openFullImage(context, url),
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: Colors.grey[100],
              child: Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  color: Colors.grey[400],
                  size: 32,
                ),
              ),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[100],
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accent,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openFullImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  // ── PDF card ──────────────────────────────────────────

  // CHANGE the method signature:
  Widget _pdfCard(BuildContext context, Map<String, dynamic> pdf) {
    final url = pdf['url']?.toString() ?? '';
    final publicId = pdf['publicId']?.toString() ?? '';
    final name = publicId.split('/').last;
    final fileName = name.isNotEmpty ? name : 'Document';

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Icon(
            Icons.picture_as_pdf_rounded,
            color: Colors.red[600],
            size: 22,
          ),
        ),
        title: Text(
          fileName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Tap to view PDF',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_rounded, size: 12, color: Colors.red[600]),
              SizedBox(width: 4),
              Text(
                'View',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerPage(url: url, fileName: fileName),
          ),
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text, Color color) => Row(
    children: [
      Icon(icon, size: 13, color: color),
      SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );

  Widget _sectionHeader(String title, IconData icon) => Row(
    children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      SizedBox(width: 8),
      Icon(icon, size: 15, color: _accent),
      SizedBox(width: 5),
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
      ),
    ],
  );
}
