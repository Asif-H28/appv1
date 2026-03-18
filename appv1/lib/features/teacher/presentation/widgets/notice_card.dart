import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class NoticeCard extends StatelessWidget {
  final Map<String, dynamic> notice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoticeCard({
    required this.notice,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _accent = Colors.teal;

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

  @override
  Widget build(BuildContext context) {
    final title = notice['title']?.toString() ?? 'Notice';
    final description = notice['description']?.toString() ?? '';
    final createdBy = notice['createdBy']?.toString() ?? '';
    final expiresAt = notice['expiresAt']?.toString();
    final createdAt = notice['createdAt']?.toString();
    final attachments = notice['attachments'] as List? ?? [];
    final expired = _isExpired(expiresAt);

    // Separate images and PDFs
    final images = attachments.where((a) {
      final url = (a as Map)['url']?.toString() ?? '';
      return url.contains('.jpg') ||
          url.contains('.jpeg') ||
          url.contains('.png') ||
          url.contains('.webp') ||
          (a)['resourceType']?.toString() == 'image';
    }).toList();
    final pdfs = attachments.where((a) {
      final url = (a as Map)['url']?.toString() ?? '';
      return url.contains('.pdf') ||
          (a)['resourceType']?.toString() == 'pdf' ||
          (a)['resourceType']?.toString() == 'raw';
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: expired
              ? Colors.orange.withOpacity(0.3)
              : _accent.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──
          Container(
            padding: EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              color: expired
                  ? Colors.orange.withOpacity(0.06)
                  : _accent.withOpacity(0.05),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: expired
                        ? Colors.orange.withOpacity(0.15)
                        : _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    expired ? Icons.timer_off_rounded : Icons.campaign_rounded,
                    color: expired ? Colors.orange : _accent,
                    size: 20,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (createdBy.isNotEmpty)
                        Text(
                          'By $createdBy  •  ${_timeAgo(createdAt)}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (expired)
                  Container(
                    margin: EdgeInsets.only(right: 4),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Expired',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, color: _accent, size: 16),
                          SizedBox(width: 8),
                          Text('Edit Notice'),
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
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Description ──
          if (description.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Text(
                description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),

          // ── Image previews ──
          if (images.isNotEmpty) ...[
            SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 14),
                itemCount: images.length,
                separatorBuilder: (_, __) => SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final url = (images[i] as Map)['url']?.toString() ?? '';
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // ── PDF attachments ──
          if (pdfs.isNotEmpty) ...[
            SizedBox(height: 10),
            ...pdfs.map((pdf) {
              final fileName =
                  (pdf as Map)['publicId']?.toString().split('/').last ??
                  'Document';
              return Padding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, 6),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],

          // ── Footer: expiry + attachment count ──
          Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                if (expiresAt != null) ...[
                  Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Expires ${_formatDate(expiresAt)}',
                    style: TextStyle(
                      color: expired ? Colors.orange : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                Spacer(),
                if (attachments.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          size: 12,
                          color: _accent,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${attachments.length} file(s)',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
