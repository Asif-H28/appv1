import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isRead;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.data,
    this.isRead = false,
    this.onTap,
  });

  IconData _icon(String type) {
    switch (type) {
      case 'result':
        return Icons.bar_chart_rounded;
      case 'attendance':
        return Icons.how_to_reg_rounded;
      case 'notice':
        return Icons.campaign_rounded;
      case 'join_request':
        return Icons.person_add_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _timeAgo(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = data['type']?.toString() ?? '';
    final title = data['title']?.toString() ?? 'No Title';
    final body = data['body']?.toString() ?? '';
    final sentByName = data['sentByName']?.toString() ?? '';
    final timeStr = _timeAgo(data['createdAt']?.toString());
    final source = data['_source']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isRead ? const Color(0xFFF7F7F7) : Colors.white,
          borderRadius: BorderRadius.circular(3), // ✅ your 3px radius
          // ✅ uniform border color — fixes borderRadius crash
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : Colors.teal.withOpacity(0.3),
          ),
          boxShadow: isRead
              ? []
              : [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3), // ✅ match
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ Left teal accent bar as separate widget (not border)
                Container(
                  width: 4,
                  color: isRead ? Colors.grey.shade300 : Colors.teal,
                ),

                // ── Card content ──────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Icon ──────────────────────────
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isRead
                                ? Colors.grey.shade100
                                : Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Icon(
                            _icon(type),
                            color: isRead ? Colors.grey.shade400 : Colors.teal,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 11),

                        // ── Text ──────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: isRead
                                            ? FontWeight.w500
                                            : FontWeight.bold,
                                        fontSize: 13,
                                        color: isRead
                                            ? const Color(0xFF555555)
                                            : const Color(0xFF1A1A1A),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                          color: Color(0xFF888888),
                                          fontSize: 10,
                                        ),
                                      ),
                                      if (!isRead) ...[
                                        const SizedBox(height: 4),
                                        // Unread dot
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: Colors.teal,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Body
                              if (body.isNotEmpty)
                                Text(
                                  body,
                                  style: TextStyle(
                                    color: isRead
                                        ? const Color(0xFF999999)
                                        : const Color(0xFF444444),
                                    fontSize: 12,
                                    height: 1.45,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),

                              const SizedBox(height: 7),

                              // Bottom chips row
                              Wrap(
                                spacing: 5,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Sender
                                  if (sentByName.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.person_outline_rounded,
                                          size: 11,
                                          color: Color(0xFF888888),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          sentByName,
                                          style: const TextStyle(
                                            color: Color(0xFF666666),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),

                                  // Type chip
                                  if (type.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isRead
                                            ? Colors.grey.shade100
                                            : Colors.teal.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: isRead
                                              ? Colors.grey.shade300
                                              : Colors.teal.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        type.replaceAll('_', ' '),
                                        style: TextStyle(
                                          color: isRead
                                              ? const Color(0xFF999999)
                                              : Colors.teal.shade700,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                  // Source tag
                                  if (source.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isRead
                                            ? Colors.grey.shade100
                                            : Colors.teal.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        source == 'personal'
                                            ? '👤 Personal'
                                            : '🏫 Class',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isRead
                                              ? const Color(0xFF999999)
                                              : Colors.teal.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
