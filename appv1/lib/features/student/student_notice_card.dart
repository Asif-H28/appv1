import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_theme_manager.dart';


class StudentNoticeCard extends StatelessWidget {
  final Map<String, dynamic> notice;
  final VoidCallback onTap;

  const StudentNoticeCard({required this.notice, required this.onTap});

  String get _title => notice['title']?.toString() ?? 'Notice';

  String get _description => notice['description']?.toString() ?? '';

  String get _createdBy => notice['createdBy']?.toString() ?? '';

  List<dynamic> get _attachments =>
      (notice['attachments'] as List<dynamic>?) ?? [];

  bool get _hasImages => _attachments.any(
    (a) => (a as Map<String, dynamic>)['type']?.toString() != 'pdf',
  );

  bool get _hasPdfs => _attachments.any(
    (a) => (a as Map<String, dynamic>)['type']?.toString() == 'pdf',
  );

  String get _timeAgo {
    final raw = notice['createdAt']?.toString() ?? '';
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      const m = [
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
      return '${dt.day} ${m[dt.month]}';
    } catch (_) {
      return '';
    }
  }

  String get _expiryLabel {
    final raw = notice['expiresAt']?.toString() ?? '';
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = dt.difference(DateTime.now());
      if (diff.isNegative) return 'Expired';
      if (diff.inDays == 0) return 'Expires today';
      if (diff.inDays == 1) return 'Expires tomorrow';
      return 'Expires in ${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }

  bool get _isExpiringSoon {
    final raw = notice['expiresAt']?.toString() ?? '';
    if (raw.isEmpty) return false;
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = dt.difference(DateTime.now());
      return diff.inDays <= 2 && !diff.isNegative;
    } catch (_) {
      return false;
    }
  }

  String? get _thumbnailUrl {
    for (final a in _attachments) {
      final att = a as Map<String, dynamic>;
      final type = att['type']?.toString() ?? '';
      if (type != 'pdf') return att['url']?.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        final expiry = _expiryLabel;
        final thumbnail = _thumbnailUrl;

        return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: theme.dividerColor),
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
            // ── Top accent bar ──
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.primary.withOpacity(0.4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),

            // ── Thumbnail if image ──
            if (thumbnail != null)
              ClipRRect(
                child: Image.network(
                  thumbnail,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => SizedBox(),
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 140,
                      color: Colors.grey[100],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title row ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.primary, theme.primary.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(
                          Icons.campaign_rounded,
                          color: theme.cardBackground,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: theme.textPrimary,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                if (_createdBy.isNotEmpty) ...[
                                  Icon(
                                    Icons.person_rounded,
                                    size: 10,
                                    color: theme.primary,
                                  ),
                                  SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      _createdBy,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.primary,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                ],
                                if (_timeAgo.isNotEmpty)
                                  Text(
                                    _timeAgo,
                                    style: TextStyle(
                                      color: theme.textSecondary,
                                      fontSize: 10.5,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Description ──
                  if (_description.isNotEmpty) ...[
                    SizedBox(height: 10),
                    Text(
                      _description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ],

                  SizedBox(height: 10),
                  Divider(height: 1, color: Colors.grey[100]),
                  SizedBox(height: 10),

                  // ── Footer ──
                  Row(
                    children: [
                      // attachment pills
                      if (_hasPdfs)
                        _attachPill(
                          Icons.picture_as_pdf_rounded,
                          'PDF',
                          Colors.red[600]!,
                        ),
                      if (_hasPdfs && _hasImages) SizedBox(width: 6),
                      if (_hasImages)
                        _attachPill(
                          Icons.image_rounded,
                          'Image',
                          Colors.blue[600]!,
                        ),

                      Spacer(),

                      // expiry badge
                      if (expiry.isNotEmpty) ...[
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _isExpiringSoon
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: _isExpiringSoon
                                    ? Colors.orange.withOpacity(0.3)
                                    : theme.dividerColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 10,
                                  color: _isExpiringSoon
                                      ? Colors.orange[700]
                                      : theme.textSecondary,
                                ),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    expiry,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _isExpiringSoon
                                          ? Colors.orange[700]
                                          : theme.textSecondary,
                                      fontSize: 10.5,
                                      fontWeight: _isExpiringSoon
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                      ],

                      // read more
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Read More',
                              style: TextStyle(
                                color: theme.cardBackground,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: theme.cardBackground,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        );
      },
    );
  }

  Widget _attachPill(IconData icon, String label, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
