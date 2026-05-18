import 'dart:convert';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'pdf_viewer_page.dart';

class NoticeDetailSheet extends StatefulWidget {
  final Map<String, dynamic> notice;

  const NoticeDetailSheet({super.key, required this.notice});

  @override
  State<NoticeDetailSheet> createState() => _NoticeDetailSheetState();
}

class _NoticeDetailSheetState extends State<NoticeDetailSheet> {
  late Map<String, dynamic> _notice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _notice = widget.notice;
    _fetchNoticeDetails();
  }

  Future<void> _fetchNoticeDetails() async {
    final noticeId = _notice['noticeId'];
    if (noticeId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/admin-notices/$noticeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['notice'] != null) {
          if (mounted) {
            setState(() {
              _notice = body['notice'];
              _loading = false;
            });
          }
        } else {
          if (mounted) setState(() => _loading = false);
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('[NoticeDetailSheet] fetch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _notice['title'] ?? 'Notice Detail';
    final desc = _notice['description'] ?? '';
    final createdAt = _notice['createdAt'] ?? '';
    final attachments = (_notice['attachments'] as List? ?? []);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: Colors.teal)),
            )
          else ...[
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Icon(Icons.campaign_rounded,
                              color: Colors.teal, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatFullDate(createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Message',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                    if (attachments.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Attachments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...attachments.map((a) => _buildAttachment(context, a)),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3)),
                    elevation: 0,
                  ),
                  child: const Text('Close',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, dynamic a) {
    final type = a['type'] ?? 'file';
    final url = a['url'] ?? '';
    final name = a['originalName'] ?? 'Attachment';
    final isPdf = type == 'pdf' || (name.toString().toLowerCase().endsWith('.pdf'));
    final isImage = type == 'image' || 
                   (name.toString().toLowerCase().endsWith('.jpg')) ||
                   (name.toString().toLowerCase().endsWith('.jpeg')) ||
                   (name.toString().toLowerCase().endsWith('.png'));

    if (isImage) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          url,
          fit: BoxFit.fitWidth,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            height: 60,
            color: Colors.grey.shade100,
            child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 120,
              color: Colors.grey.shade50,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal)),
            );
          },
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
            color: isPdf ? Colors.red.shade700 : Colors.teal.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: () {
              if (isPdf) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerPage(url: url, fileName: name),
                  ),
                );
              }
            },
            icon: Icon(
              isPdf ? Icons.open_in_new_rounded : Icons.download_rounded,
              size: 18,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = [
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
        'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • ${dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
    } catch (_) {
      return '';
    }
  }
}
