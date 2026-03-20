import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'pdf_viewer_page.dart';

class NoticeCard extends StatefulWidget {
  final Map<String, dynamic> notice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoticeCard({
    required this.notice,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<NoticeCard> {
  static const Color _accent = Colors.teal;
  bool _expanded = false;

  bool _isExpired(String? expiresAt) {
    if (expiresAt == null) return false;
    try {
      return DateTime.parse(expiresAt).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
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
    } catch (_) {
      return dateStr;
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(dateStr).toLocal());
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  void _openPdf(String url, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(url: url, fileName: fileName),
      ),
    );
  }

  void _showImageViewer(BuildContext context, List images, int startIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) =>
          _ImageViewerDialog(images: images, startIndex: startIndex),
    );
  }

  bool _isPdf(dynamic a) {
    final url = (a as Map)['url']?.toString().toLowerCase() ?? '';
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

  bool _isImage(dynamic a) {
    if (_isPdf(a)) return false;
    final url = (a as Map)['url']?.toString().toLowerCase() ?? '';
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

  @override
  Widget build(BuildContext context) {
    final title = widget.notice['title']?.toString() ?? 'Notice';
    final description = widget.notice['description']?.toString() ?? '';
    final createdBy = widget.notice['createdBy']?.toString() ?? '';
    final expiresAt = widget.notice['expiresAt']?.toString();
    final createdAt = widget.notice['createdAt']?.toString();
    final attachments = widget.notice['attachments'] as List? ?? [];
    final expired = _isExpired(expiresAt);

    final images = attachments.where(_isImage).toList();
    final pdfs = attachments.where(_isPdf).toList();

    final hasAttachments = images.isNotEmpty || pdfs.isNotEmpty;
    final descIsLong = description.length > 120;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: expired
              ? Colors.orange.withOpacity(0.35)
              : _accent.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: expired
                        ? Colors.orange.withOpacity(0.1)
                        : _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    expired ? Icons.timer_off_rounded : Icons.campaign_rounded,
                    color: expired ? Colors.orange[700] : _accent,
                    size: 16,
                  ),
                ),
                SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (expired)
                            Container(
                              margin: EdgeInsets.only(left: 6),
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Expired',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          if (createdBy.isNotEmpty) ...[
                            Icon(
                              Icons.person_outline_rounded,
                              size: 10,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                createdBy,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _dot(),
                          ],
                          Text(
                            _timeAgo(createdAt),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                          if (expiresAt != null) ...[
                            _dot(),
                            Icon(
                              Icons.schedule_rounded,
                              size: 10,
                              color: expired
                                  ? Colors.orange[600]
                                  : AppColors.textSecondary,
                            ),
                            SizedBox(width: 2),
                            Text(
                              _formatDate(expiresAt),
                              style: TextStyle(
                                color: expired
                                    ? Colors.orange[600]
                                    : AppColors.textSecondary,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 6),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionBtn(
                      Icons.edit_outlined,
                      _accent,
                      () => widget.onEdit(),
                    ),
                    SizedBox(width: 4),
                    _actionBtn(
                      Icons.delete_outline_rounded,
                      Colors.red[400]!,
                      () => widget.onDelete(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Divider ──
          if (description.isNotEmpty || hasAttachments)
            Divider(height: 1, color: Colors.grey[100]),

          // ── Description ──
          if (description.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.55,
                    ),
                    maxLines: _expanded ? null : (descIsLong ? 3 : null),
                    overflow: _expanded
                        ? TextOverflow.visible
                        : (descIsLong ? TextOverflow.ellipsis : null),
                  ),
                  if (descIsLong)
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          _expanded ? 'Show less' : 'Read more',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ── Image grid ──
          if (images.isNotEmpty) ...[
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: images.length == 1
                  ? _singleImage(context, images, 0)
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: images.length == 2 ? 2 : 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                        childAspectRatio: 1,
                      ),
                      itemCount: images.length > 6 ? 6 : images.length,
                      itemBuilder: (ctx, i) {
                        final isLast = i == 5 && images.length > 6;
                        final url = (images[i] as Map)['url']?.toString() ?? '';
                        return GestureDetector(
                          onTap: () => _showImageViewer(context, images, i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                  ),
                                ),
                                if (isLast)
                                  Container(
                                    color: Colors.black.withOpacity(0.55),
                                    child: Center(
                                      child: Text(
                                        '+${images.length - 5}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],

          // ── PDF attachments (teal theme) ──
          if (pdfs.isNotEmpty) ...[
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: pdfs.map((pdf) {
                  final pdfMap = pdf as Map;
                  final rawId =
                      pdfMap['publicId']?.toString() ??
                      pdfMap['originalFilename']?.toString() ??
                      '';
                  final fileName = rawId.isNotEmpty
                      ? rawId.split('/').last
                      : 'Document.pdf';
                  final url = pdfMap['url']?.toString() ?? '';

                  return GestureDetector(
                    onTap: () => _openPdf(url, fileName),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 5),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.04), // ← teal bg
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: _accent.withOpacity(0.2),
                        ), // ← teal border
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.1), // ← teal icon bg
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Icon(
                              Icons.picture_as_pdf_rounded,
                              color: _accent,
                              size: 14,
                            ), // ← teal icon
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName.isNotEmpty
                                      ? fileName
                                      : 'Document.pdf',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Tap to view PDF',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(
                                0.08,
                              ), // ← teal view btn
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: _accent.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 11,
                                  color: _accent,
                                ), // ← teal
                                SizedBox(width: 3),
                                Text(
                                  'View',
                                  style: TextStyle(
                                    color: _accent, // ← teal
                                    fontSize: 10,
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
                }).toList(),
              ),
            ),
          ],

          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _singleImage(BuildContext context, List images, int index) {
    final url = (images[index] as Map)['url']?.toString() ?? '';
    return GestureDetector(
      onTap: () => _showImageViewer(context, images, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.network(
          url,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 100,
            color: Colors.grey[100],
            child: Icon(
              Icons.broken_image_rounded,
              color: Colors.grey[400],
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot() => Container(
    margin: EdgeInsets.symmetric(horizontal: 5),
    width: 3,
    height: 3,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[400]),
  );

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 13),
        ),
      );
}

// ─────────────────────────────────────────────
// Full-screen image viewer
// ─────────────────────────────────────────────
class _ImageViewerDialog extends StatefulWidget {
  final List images;
  final int startIndex;

  const _ImageViewerDialog({required this.images, required this.startIndex});

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.startIndex;
    _pageCtrl = PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final url = (widget.images[i] as Map)['url']?.toString() ?? '';
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white38,
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    Spacer(),
                    if (widget.images.length > 1)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
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
          ),

          // Dot indicators
          if (widget.images.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    width: _current == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _current == i ? Colors.white : Colors.white38,
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
