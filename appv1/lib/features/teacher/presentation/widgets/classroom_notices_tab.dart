import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notice_card.dart';
import 'create_notice_sheet.dart';
import 'edit_notice_sheet.dart';

class ClassroomNoticesTab extends StatefulWidget {
  final String classId;
  const ClassroomNoticesTab({required this.classId});

  @override
  _ClassroomNoticesTabState createState() => _ClassroomNoticesTabState();
}

class _ClassroomNoticesTabState extends State<ClassroomNoticesTab> {
  static const Color _accent = Colors.teal;
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _notices = [];
  String _teacherName = '';

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
    _fetchNotices();
  }

  Future<void> _loadTeacherName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _teacherName = prefs.getString('teacherName') ?? 'Teacher');
  }

  Future<void> _fetchNotices() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/notice/classroom/${widget.classId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['notices'] != null)
          raw = body['notices'] as List;
        else if (body['data'] != null)
          raw = body['data'] as List;

        setState(() {
          _notices = raw.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _deleteNotice(String noticeId, int index) async {
    try {
      final response = await http.delete(
        Uri.parse('https://appv1backend.onrender.com/api/notice/$noticeId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _notices.removeAt(index));
        _showSnackBar('Notice deleted.', Colors.green[600]!);
      } else {
        _showSnackBar('Failed to delete notice.', Colors.red[600]!);
      }
    } catch (_) {
      _showSnackBar('No internet connection.', Colors.red[600]!);
    }
  }

  Future<void> _purgeExpired() async {
    try {
      await http.delete(
        Uri.parse(
          'https://appv1backend.onrender.com/api/notice/purge/${widget.classId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      _fetchNotices();
      _showSnackBar('Expired notices cleared.', Colors.teal);
    } catch (_) {}
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmDelete(String noticeId, String title, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(Icons.delete_rounded, color: Colors.red[600]),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Notice',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Delete "$title"? This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteNotice(noticeId, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateNoticeSheet(
        classId: widget.classId,
        createdBy: _teacherName,
        onCreated: _fetchNotices,
      ),
    );
  }

  void _openEditSheet(Map<String, dynamic> notice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditNoticeSheet(notice: notice, onUpdated: _fetchNotices),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Action bar ──
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openCreateSheet,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'New Notice',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              _iconBtn(
                Icons.refresh_rounded,
                _accent,
                _fetchNotices,
                tooltip: 'Refresh',
              ),
              SizedBox(width: 8),
              _iconBtn(
                Icons.auto_delete_rounded,
                Colors.orange[700]!,
                _purgeExpired,
                tooltip: 'Clear expired',
              ),
            ],
          ),
        ),
        SizedBox(height: 12),

        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: _accent,
                    strokeWidth: 3,
                  ),
                )
              : _hasError
              ? _buildError()
              : _notices.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: _accent,
                  onRefresh: _fetchNotices,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 40),
                    itemCount: _notices.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notice = _notices[index];
                      final noticeId =
                          notice['noticeId']?.toString() ??
                          notice['_id']?.toString() ??
                          '';
                      return NoticeCard(
                        notice: notice,
                        onEdit: () => _openEditSheet(notice),
                        onDelete: () => _confirmDelete(
                          noticeId,
                          notice['title']?.toString() ?? 'Notice',
                          index,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _iconBtn(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? tooltip,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: IconButton(
      icon: Icon(icon, color: color, size: 20),
      onPressed: onTap,
      tooltip: tooltip,
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'Could not load notices',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchNotices,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.refresh),
            label: Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.1),
            ),
            child: Icon(Icons.campaign_outlined, color: _accent, size: 36),
          ),
          SizedBox(height: 16),
          Text(
            'No Notices Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tap "New Notice" to create one.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}
