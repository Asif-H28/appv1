import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class NoticeDetailSheet extends StatelessWidget {
  final Map<String, dynamic> notice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoticeDetailSheet({
    super.key,
    required this.notice,
    required this.onEdit,
    required this.onDelete,
  });

  String _audienceLabel(String? a) {
    if (a == 'teachers_only') return 'Teachers Only';
    if (a == 'teachers_and_students') return 'Teachers & Students';
    return a ?? '';
  }

  Color _audienceColor(String? a) =>
      a == 'teachers_only' ? const Color(0xFF7C3AED) : const Color(0xFF009688);

  bool _isExpired(String? iso) {
    if (iso == null) return false;
    try {
      return DateTime.parse(iso).toLocal().isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      const mo = [
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
      return '${d.day} ${mo[d.month]} ${d.year}  '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = notice['title']?.toString() ?? '';
    final description = notice['description']?.toString() ?? '';
    final audience = notice['audience']?.toString();
    final scope = notice['targetScope']?.toString();
    final expiresAt = notice['expiresAt']?.toString();
    final createdAt = notice['createdAt']?.toString();
    final attachments = (notice['attachments'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final expired = _isExpired(expiresAt);
    final aColor = _audienceColor(audience);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F7F6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(3),
          topRight: Radius.circular(3),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF009688),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Notice Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title card
                  _detailCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: aColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Icon(
                            Icons.campaign_rounded,
                            color: aColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _chip(_audienceLabel(audience), aColor),
                                  const SizedBox(width: 6),
                                  _chip(
                                    expired ? 'Expired' : 'Active',
                                    expired
                                        ? Colors.red
                                        : const Color(0xFF38A169),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  _detailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Description'),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Color(0xFF4A5568),
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Meta info
                  _detailCard(
                    child: Column(
                      children: [
                        _metaRow(
                          Icons.people_rounded,
                          'Audience',
                          _audienceLabel(audience),
                          aColor,
                        ),
                        if (scope != null && scope.isNotEmpty) ...[
                          const Divider(height: 16),
                          _metaRow(
                            Icons.school_rounded,
                            'Scope',
                            scope == 'all_classes'
                                ? 'All Classes'
                                : 'Selected Classes',
                            const Color(0xFF009688),
                          ),
                        ],
                        const Divider(height: 16),
                        _metaRow(
                          Icons.schedule_rounded,
                          'Created',
                          _formatDate(createdAt),
                          const Color(0xFF718096),
                        ),
                        const Divider(height: 16),
                        _metaRow(
                          expired
                              ? Icons.timer_off_rounded
                              : Icons.timer_rounded,
                          'Expires',
                          _formatDate(expiresAt),
                          expired ? Colors.red : const Color(0xFF009688),
                        ),
                      ],
                    ),
                  ),

                  // Attachments
                  if (attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _detailCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Attachments (${attachments.length})'),
                          const SizedBox(height: 10),
                          ...attachments.map(
                            (att) => _AttachmentTile(attachment: att),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: const Color(0xFF009688).withOpacity(0.12)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF009688).withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Widget _sectionLabel(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      color: Color(0xFF009688),
      letterSpacing: 0.8,
    ),
  );

  Widget _metaRow(IconData icon, String key, String val, Color color) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(width: 10),
      Text(
        '$key  ',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF718096),
        ),
      ),
      Expanded(
        child: Text(
          val,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3748),
          ),
        ),
      ),
    ],
  );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ── Attachment Tile ──────────────────────────────────────

class _AttachmentTile extends StatelessWidget {
  final Map<String, dynamic> attachment;
  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final url = attachment['url']?.toString() ?? '';
    final name = attachment['originalName']?.toString() ?? 'Attachment';
    final type = attachment['resourceType']?.toString() ?? 'image';
    final isPdf = type == 'raw' || name.toLowerCase().endsWith('.pdf');

    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7F6),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFF009688).withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isPdf
                    ? Colors.red.withOpacity(0.08)
                    : const Color(0xFF009688).withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                size: 16,
                color: isPdf ? Colors.red[400] : const Color(0xFF009688),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              size: 14,
              color: Color(0xFF009688),
            ),
          ],
        ),
      ),
    );
  }
}
