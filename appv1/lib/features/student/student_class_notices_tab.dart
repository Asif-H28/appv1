import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_theme_manager.dart';
import 'student_notice_card.dart';
import 'student_notice_detail_screen.dart';

class StudentClassNoticesTab extends StatefulWidget {
  @override
  _StudentClassNoticesTabState createState() => _StudentClassNoticesTabState();
}

class _StudentClassNoticesTabState extends State<StudentClassNoticesTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _notices = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final classId = prefs.getString('classId') ?? '';

    if (classId.isEmpty) {
      setState(() {
        _error = 'Classroom not assigned.';
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/notice/classroom/$classId',
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> raw = [];
        if (body['notices'] != null)
          raw = body['notices'] as List;
        else if (body is List)
          raw = body;

        setState(() {
          _notices = raw.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load notices.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No internet connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        if (_isLoading) return _buildLoader(theme);
        if (_error.isNotEmpty) return _buildError(theme);
        if (_notices.isEmpty) return _buildEmpty(theme);

        return RefreshIndicator(
          color: theme.primary,
          onRefresh: _fetchNotices,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              14,
              16,
              14,
              40 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: _notices.length,
            separatorBuilder: (_, __) => SizedBox(height: 10),
            itemBuilder: (_, i) => StudentNoticeCard(
              notice: _notices[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StudentNoticeDetailScreen(notice: _notices[i]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoader(StudentThemeConfig theme) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: theme.primary, strokeWidth: 2.5),
        SizedBox(height: 14),
        Text(
          'Loading notices...',
          style: TextStyle(color: theme.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildError(StudentThemeConfig theme) => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red[400],
              size: 30,
            ),
          ),
          SizedBox(height: 14),
          Text(
            _error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchNotices,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty(StudentThemeConfig theme) => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primary.withOpacity(0.08),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: theme.primary,
              size: 32,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No Notices Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: theme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your teacher hasn\'t posted any\nnotices for this classroom yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}
