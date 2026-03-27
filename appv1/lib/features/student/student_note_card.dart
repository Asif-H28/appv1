import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../teacher/presentation/widgets/pdf_viewer_page.dart';

const Color _accent = Colors.teal;

class NoteCard extends StatefulWidget {
  final Map<String, dynamic> note;
  const NoteCard({required this.note});

  @override
  _NoteCardState createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  final Map<int, bool> _downloading = {};

  // ── Data helpers ──────────────────────────────────────

  String get _title => widget.note['title']?.toString() ?? 'Untitled Note';

  String get _sharedBy => widget.note['notesSharedBy']?.toString() ?? '';

  String get _uploadedAt {
    final raw =
        widget.note['createdAt']?.toString() ??
        widget.note['uploadedAt']?.toString() ??
        '';
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
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  List<Map<String, dynamic>> get _attachments {
    final raw = widget.note['attachments'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e as Map<String, dynamic>).toList();
    }
    final url =
        widget.note['fileUrl']?.toString() ??
        widget.note['url']?.toString() ??
        '';
    if (url.isNotEmpty) {
      return [
        {
          'url': url,
          'name': _title,
          'type': widget.note['fileType']?.toString() ?? '',
        },
      ];
    }
    return [];
  }

  String _attUrl(Map<String, dynamic> att) =>
      att['url']?.toString() ??
      att['fileUrl']?.toString() ??
      att['path']?.toString() ??
      '';

  String _attName(Map<String, dynamic> att) =>
      att['name']?.toString() ??
      att['fileName']?.toString() ??
      att['originalName']?.toString() ??
      _title;

  String _attType(Map<String, dynamic> att) {
    final raw =
        (att['type']?.toString() ??
                att['fileType']?.toString() ??
                att['mimeType']?.toString() ??
                '')
            .toLowerCase();
    if (raw.contains('pdf')) return 'pdf';
    if (raw.contains('image') ||
        raw.contains('jpg') ||
        raw.contains('jpeg') ||
        raw.contains('png'))
      return 'image';
    final url = _attUrl(att).toLowerCase().split('?').first;
    if (url.endsWith('.pdf')) return 'pdf';
    if (url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.webp'))
      return 'image';
    return 'pdf';
  }

  Color _typeColor(String type) =>
      type == 'image' ? Colors.blue[600]! : Colors.red[600]!;

  IconData _typeIcon(String type) =>
      type == 'image' ? Icons.image_rounded : Icons.picture_as_pdf_rounded;

  String _typeLabel(String type) => type == 'image' ? 'Image' : 'PDF';

  // ── Actions ───────────────────────────────────────────

  void _openViewer(Map<String, dynamic> att) {
    final url = _attUrl(att);
    final name = _attName(att);
    final type = _attType(att);
    if (url.isEmpty) {
      _snack('No file available.', Colors.orange[700]!);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => type == 'image'
            ? _ImageViewerScreen(url: url, title: name)
            : PdfViewerPage(url: url, fileName: name),
      ),
    );
  }

  Future<void> _download(Map<String, dynamic> att, int index) async {
    if (_downloading[index] == true) return;
    final url = _attUrl(att);
    final name = _attName(att);
    final type = _attType(att);
    if (url.isEmpty) {
      _snack('No file available.', Colors.orange[700]!);
      return;
    }
    if (Platform.isAndroid) {
      final granted = await _requestStoragePermission();
      if (!granted) return;
    }
    setState(() => _downloading[index] = true);
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        _snack('Download failed.', Colors.red[600]!);
        setState(() => _downloading[index] = false);
        return;
      }
      final ext = type == 'image' ? '.jpg' : '.pdf';
      final sanitized = name.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final fileName = '${sanitized.isNotEmpty ? sanitized : 'note'}$ext';
      final savePath = '/storage/emulated/0/Download/$fileName';
      await File(savePath).writeAsBytes(res.bodyBytes);
      setState(() => _downloading[index] = false);
      _snack('Saved to Downloads: $fileName', Colors.green[600]!);
      await OpenFile.open(savePath);
    } catch (_) {
      if (!mounted) return;
      setState(() => _downloading[index] = false);
      _snack('Download failed.', Colors.red[600]!);
    }
  }

  Future<bool> _requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) return true;
    if (status.isDenied) {
      bool granted = false;
      await _showPermissionDialog(
        title: 'Storage Permission',
        message:
            'SchoolSync needs storage access to save files to your Downloads folder.',
        buttonLabel: 'Allow',
        onAllow: () async {
          granted = await Permission.storage.request().isGranted;
        },
      );
      return granted;
    }
    if (status.isPermanentlyDenied) {
      await _showPermissionDialog(
        title: 'Permission Required',
        message:
            'Storage permission was denied. Please enable it in app settings.',
        buttonLabel: 'Open Settings',
        onAllow: () async => await openAppSettings(),
      );
    }
    return false;
  }

  Future<void> _showPermissionDialog({
    required String title,
    required String message,
    required String buttonLabel,
    required Future<void> Function() onAllow,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Icon(Icons.folder_rounded, color: _accent, size: 22),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await onAllow();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Center(
                          child: Text(
                            buttonLabel,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final attachments = _attachments;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Colored top accent bar ──
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.5)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row: icon + title + date ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Note icon box ──
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: _accent.withOpacity(0.15)),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        color: _accent,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 5),
                          // ── Teacher + date inline ──
                          Row(
                            children: [
                              if (_sharedBy.isNotEmpty) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accent.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: _accent.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_rounded,
                                        size: 10,
                                        color: _accent,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        _sharedBy,
                                        style: TextStyle(
                                          color: _accent,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 6),
                              ],
                              if (_uploadedAt.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      _uploadedAt,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Attachments ──
                if (attachments.isNotEmpty) ...[
                  SizedBox(height: 12),
                  // ── Attachments header ──
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Attachments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 6),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Center(
                          child: Text(
                            '${attachments.length}',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // ── Attachment rows ──
                  ...List.generate(attachments.length, (i) {
                    final att = attachments[i];
                    final type = _attType(att);
                    final name = _attName(att);
                    final tColor = _typeColor(type);
                    final isDown = _downloading[i] == true;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i < attachments.length - 1 ? 7 : 0,
                      ),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            // ── File type icon ──
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: tColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: tColor.withOpacity(0.2),
                                ),
                              ),
                              child: Icon(
                                _typeIcon(type),
                                color: tColor,
                                size: 17,
                              ),
                            ),
                            SizedBox(width: 10),

                            // ── Name + type tag ──
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 3),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      _typeLabel(type),
                                      style: TextStyle(
                                        color: tColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),

                            // ── View button ──
                            _actionBtn(
                              label: 'View',
                              icon: Icons.visibility_rounded,
                              color: _accent,
                              filled: false,
                              onTap: () => _openViewer(att),
                            ),
                            SizedBox(width: 6),

                            // ── Download button ──
                            isDown
                                ? Container(
                                    width: 68,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _accent.withOpacity(0.45),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 11,
                                          height: 11,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'Saving',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _actionBtn(
                                    label: 'Save',
                                    icon: Icons.download_rounded,
                                    color: _accent,
                                    filled: true,
                                    onTap: () => _download(att, i),
                                  ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable action button ────────────────────────────

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: filled ? color : color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: filled ? Colors.white : color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// IMAGE VIEWER
// ─────────────────────────────────────────────────────────

class _ImageViewerScreen extends StatelessWidget {
  final String url;
  final String title;
  const _ImageViewerScreen({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(8),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Image',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.teal,
                  strokeWidth: 2.5,
                ),
              );
            },
            errorBuilder: (_, __, ___) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey[600],
                  size: 48,
                ),
                SizedBox(height: 10),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
