import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import 'pdf_viewer_page.dart'; // ← your existing PdfViewerPage

class NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _accent = Colors.teal;

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(dateStr).toLocal());
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  void _openImageViewer(BuildContext context, List images, int startIndex) {
    final controller = PageController(initialPage: startIndex);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageViewerPage(
          images: images,
          initialIndex: startIndex,
          controller: controller,
        ),
      ),
    );
  }

  // ── Now opens PdfViewerPage (full screen, Google Docs WebView) ──
  void _openPdfViewer(BuildContext context, Map pdf) {
    final url = pdf['url']?.toString() ?? '';
    final filename =
        pdf['filename']?.toString() ??
        pdf['publicId']?.toString().split('/').last ??
        'Document';

    if (url.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(url: url, fileName: filename),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = note['title']?.toString() ?? 'Note';
    final sharedBy = note['notesSharedBy']?.toString() ?? '';
    final createdAt = note['createdAt']?.toString();
    final attachments = note['attachments'] as List? ?? [];

    final images = attachments.where((a) {
      final type = (a as Map)['type']?.toString() ?? '';
      final url = a['url']?.toString() ?? '';
      return type == 'image' ||
          url.contains('.jpg') ||
          url.contains('.jpeg') ||
          url.contains('.png') ||
          url.contains('.webp');
    }).toList();

    final pdfs = attachments.where((a) {
      final type = (a as Map)['type']?.toString() ?? '';
      final url = a['url']?.toString() ?? '';
      return type == 'pdf' || url.contains('.pdf');
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsets.fromLTRB(10, 9, 4, 9),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.04),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: _accent,
                    size: 15,
                  ),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sharedBy.isNotEmpty)
                        Text(
                          'By $sharedBy  •  ${_timeAgo(createdAt)}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, color: _accent, size: 14),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_rounded,
                            color: Colors.red[600],
                            size: 14,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Image previews ──
          if (images.isNotEmpty) ...[
            SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 10),
                itemCount: images.length,
                separatorBuilder: (_, __) => SizedBox(width: 5),
                itemBuilder: (ctx, i) {
                  final url = (images[i] as Map)['url']?.toString() ?? '';
                  return GestureDetector(
                    onTap: () => _openImageViewer(ctx, images, i),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.network(
                            url,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[100],
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // ── PDF attachments ──
          if (pdfs.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                children: pdfs.map((pdf) {
                  final filename =
                      (pdf as Map)['filename']?.toString() ??
                      pdf['publicId']?.toString().split('/').last ??
                      'Document';
                  return GestureDetector(
                    onTap: () => _openPdfViewer(context, pdf),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 5),
                      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: _accent.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Icon(
                              Icons.picture_as_pdf_rounded,
                              color: _accent,
                              size: 12,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              filename,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // ── Tapped indicator ──
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_rounded,
                                  size: 10,
                                  color: _accent,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: _accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Footer ──
          Padding(
            padding: EdgeInsets.fromLTRB(10, 7, 10, 9),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  size: 10,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 3),
                Text(
                  '${attachments.length} attachment${attachments.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'Note',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Full-screen image gallery viewer
// ─────────────────────────────────────────────
class _ImageViewerPage extends StatefulWidget {
  final List images;
  final int initialIndex;
  final PageController controller;

  const _ImageViewerPage({
    required this.images,
    required this.initialIndex,
    required this.controller,
  });

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: widget.controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final url = (widget.images[i] as Map)['url']?.toString() ?? '';
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          color: Colors.grey[600],
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Top bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                8,
                MediaQuery.of(context).padding.top + 6,
                8,
                10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  Spacer(),
                  if (widget.images.length > 1)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${_current + 1} / ${widget.images.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Dot indicators ──
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
