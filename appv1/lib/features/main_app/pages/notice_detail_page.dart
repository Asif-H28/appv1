import 'package:flutter/material.dart';
import '../../teacher/presentation/widgets/pdf_viewer_page.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticeDetailPage extends StatelessWidget {
  final Map<String, dynamic> notice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoticeDetailPage({
    super.key,
    required this.notice,
    required this.onEdit,
    required this.onDelete,
  });

  static const _teal = Color(0xFF00796B);
  static const _border = Color(0xFFE9ECEF);
  static const _bg = Color(0xFFF8F9FA);

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
      return iso ?? '';
    }
  }

  String _audienceLabel(String? a) {
    if (a == 'teachers_only') return 'Teachers Only';
    if (a == 'teachers_and_students') return 'Teachers & Students';
    return a ?? '';
  }

  Color _audienceColor(String? a) =>
      a == 'teachers_only' ? const Color(0xFF2D7DD2) : _teal;

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

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        title: const Text(
          'Notice Detail',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, color: _teal, size: 20),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () async {
              Navigator.pop(context);
              onDelete();
            },
            icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
            tooltip: 'Delete',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          32 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status + date row ────────────────────────
            Row(
              children: [
                _chip(
                  expired ? 'EXPIRED' : 'ACTIVE',
                  expired ? const Color(0xFFE53E3E) : const Color(0xFF38A169),
                ),
                const SizedBox(width: 8),
                _chip(
                  audience == 'teachers_only'
                      ? 'TEACHERS'
                      : 'TEACHERS & STUDENTS',
                  aColor,
                ),
                const Spacer(),
                Text(
                  _formatDate(createdAt).split('  ').first,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Title ────────────────────────────────────
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _teal,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _border),
              ),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Meta card ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  _metaRow(
                    Icons.people_rounded,
                    'Audience',
                    _audienceLabel(audience),
                    aColor,
                  ),
                  if (scope != null && scope.isNotEmpty) ...[
                    const Divider(height: 20, color: _border),
                    _metaRow(
                      Icons.school_rounded,
                      'Scope',
                      scope == 'all_classes'
                          ? 'All Classes'
                          : 'Selected Classes',
                      _teal,
                    ),
                  ],
                  const Divider(height: 20, color: _border),
                  _metaRow(
                    Icons.calendar_today_rounded,
                    'Created',
                    _formatDate(createdAt),
                    const Color(0xFF6B7280),
                  ),
                  const Divider(height: 20, color: _border),
                  _metaRow(
                    expired ? Icons.timer_off_rounded : Icons.timer_rounded,
                    'Expires',
                    _formatDate(expiresAt),
                    expired ? const Color(0xFFE53E3E) : _teal,
                  ),
                ],
              ),
            ),

            // ── Attachments ──────────────────────────────
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'ATTACHMENTS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B7280),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              ...attachments.map(
                (att) => _AttachmentRow(attachment: att, context: context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 0.5,
      ),
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
        key,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ),
      ),
      const Spacer(),
      Text(
        val,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
        ),
      ),
    ],
  );
}

// ── Attachment row ─────────────────────────────────────────

class _AttachmentRow extends StatelessWidget {
  final Map<String, dynamic> attachment;
  final BuildContext context;
  const _AttachmentRow({required this.attachment, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final name = attachment['originalName']?.toString() ?? 'Attachment';
    final url = attachment['url']?.toString() ?? '';
    final type = attachment['resourceType']?.toString() ?? 'image';
    final isPdf = type == 'raw' || name.toLowerCase().endsWith('.pdf');

    return GestureDetector(
      onTap: () {
        if (isPdf) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfViewerPage(url: url, fileName: name),
            ),
          );
        } else {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isPdf
                    ? Colors.red.withOpacity(0.08)
                    : const Color(0xFF00796B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                size: 16,
                color: isPdf ? Colors.red[400] : const Color(0xFF00796B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    isPdf ? 'PDF Document' : 'Image',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              size: 15,
              color: Color(0xFF00796B),
            ),
          ],
        ),
      ),
    );
  }
}
