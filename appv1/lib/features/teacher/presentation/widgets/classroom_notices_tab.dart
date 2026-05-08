import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
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
          '${ApiConstants.apiBaseUrl}/notice/classroom/${widget.classId}',
        ),
        headers: await ApiService.getHeaders(),
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
        Uri.parse('${ApiConstants.apiBaseUrl}/notice/$noticeId'),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _notices.removeAt(index));
        _snack('Notice deleted.', Colors.green[600]!);
      } else {
        _snack('Failed to delete notice.', Colors.red[600]!);
      }
    } catch (_) {
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  Future<void> _purgeExpired() async {
    try {
      await http.delete(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/notice/purge/${widget.classId}',
        ),
        headers: await ApiService.getHeaders(),
      );
      _fetchNotices();
      _snack('Expired notices cleared.', Colors.teal);
    } catch (_) {}
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

  void _confirmDelete(String noticeId, String title, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        titlePadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        contentPadding: EdgeInsets.fromLTRB(16, 10, 16, 0),
        actionsPadding: EdgeInsets.fromLTRB(16, 8, 16, 14),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.delete_rounded,
                color: Colors.red[600],
                size: 15,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Delete Notice',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Delete "$title"? This cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: Theme(
                    data: ThemeData(
                      colorScheme: ColorScheme.light(
                        primary: Colors.red[600]!,
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteNotice(noticeId, index);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
          padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(
            children: [
              // Count chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.campaign_rounded, color: _accent, size: 12),
                    SizedBox(width: 5),
                    Text(
                      '${_notices.length} Notice${_notices.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              // Purge expired
              SizedBox(
                width: 34,
                height: 34,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.auto_delete_rounded,
                      color: Colors.orange[700],
                      size: 16,
                    ),
                    onPressed: _purgeExpired,
                    tooltip: 'Clear expired',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ),
              ),
              SizedBox(width: 6),
              // Refresh
              SizedBox(
                width: 34,
                height: 34,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.refresh_rounded, color: _accent, size: 16),
                    onPressed: _fetchNotices,
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // New notice button
              GestureDetector(
                onTap: _openCreateSheet,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 5),
                      Text(
                        'New Notice',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 10),

        // ── Body ──
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: _accent,
                    strokeWidth: 2.5,
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
                    padding: EdgeInsets.fromLTRB(14, 4, 14, 40),
                    itemCount: _notices.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8),
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

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: _accent.withOpacity(0.08),
            ),
            child: Icon(Icons.campaign_outlined, color: _accent, size: 28),
          ),
          SizedBox(height: 14),
          Text(
            'No Notices Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Tap "New Notice" to create one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          SizedBox(height: 18),
          Theme(
            data: ThemeData(
              colorScheme: ColorScheme.light(
                primary: _accent,
                onPrimary: Colors.white,
              ),
            ),
            child: SizedBox(
              height: 38,
              child: ElevatedButton.icon(
                onPressed: _openCreateSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                icon: Icon(Icons.add_rounded, size: 15, color: Colors.white),
                label: Text(
                  'New Notice',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'Could not load notices',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Theme(
            data: ThemeData(
              colorScheme: ColorScheme.light(
                primary: _accent,
                onPrimary: Colors.white,
              ),
            ),
            child: SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: _fetchNotices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                icon: Icon(Icons.refresh, size: 14, color: Colors.white),
                label: Text(
                  'Retry',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

