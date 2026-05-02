import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notice_card.dart';
import 'notice_form_sheet.dart';
import 'notice_detail_page.dart';

class NoticePage extends StatefulWidget {
  const NoticePage({super.key});
  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  static const _teal = Color(0xFF00796B);
  static const _bg = Color(0xFFF8F9FA);
  static const _border = Color(0xFFE9ECEF);

  String _orgId = '';
  String _orgName = '';
  bool _loading = true;
  String _error = '';

  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _classrooms = [];

  // Filter
  String _sortBy = 'recent'; // 'recent' | 'oldest' | 'active' | 'expired'

  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_notices);
    switch (_sortBy) {
      case 'oldest':
        list.sort(
          (a, b) => (a['createdAt'] ?? '').compareTo(b['createdAt'] ?? ''),
        );
        break;
      case 'active':
        list = list
            .where((n) => !_isExpired(n['expiresAt']?.toString()))
            .toList();
        break;
      case 'expired':
        list = list
            .where((n) => _isExpired(n['expiresAt']?.toString()))
            .toList();
        break;
      default: // recent
        list.sort(
          (a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''),
        );
    }
    return list;
  }

  bool _isExpired(String? iso) {
    if (iso == null) return false;
    try {
      return DateTime.parse(iso).toLocal().isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    _orgName = prefs.getString('userOrg') ?? 'Academic Curator';
    await Future.wait([_fetchNotices(), _fetchClassrooms()]);
  }

  Future<void> _fetchNotices() async {
    if (_orgId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No org found';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/admin-notices/org/$_orgId',
        ),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['notices'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted)
          setState(() {
            _notices = list;
            _loading = false;
          });
      } else {
        if (mounted)
          setState(() {
            _loading = false;
            _error = 'Failed to load';
          });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Network error';
        });
    }
  }

  Future<void> _fetchClassrooms() async {
    if (_orgId.isEmpty) return;
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/classroom/org/$_orgId',
        ),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['classrooms'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted) setState(() => _classrooms = list);
      }
    } catch (_) {}
  }

  Future<void> _deleteNotice(String noticeId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        title: const Text(
          'Delete Notice',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: const Text(
          'This notice will be permanently deleted.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await http.delete(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/admin-notices/$noticeId',
        ),
      );
      _fetchNotices();
      if (mounted) _snack('Notice deleted', _teal);
    } catch (_) {
      if (mounted) _snack('Delete failed', Colors.red);
    }
  }

  void _openForm({Map<String, dynamic>? notice}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NoticeFormSheet(
          orgId: _orgId,
          classrooms: _classrooms,
          notice: notice,
        ),
      ),
    );
    if (result == true) _fetchNotices();
  }

  void _openDetail(Map<String, dynamic> notice) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NoticeDetailPage(
          notice: notice,
          onEdit: () => _openForm(notice: notice),
          onDelete: () => _deleteNotice(notice['noticeId']?.toString() ?? ''),
        ),
      ),
    );
    if (result == true) _fetchNotices();
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12.5)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navBottom = MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildTitleSection(),
              _buildFilterBar(),
              Expanded(child: _buildBody(navBottom)),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Icon(Icons.school_rounded, color: _teal, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _orgName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // â”€â”€ NEW: Create Notice button â”€â”€
          GestureDetector(
            onTap: () => _openForm(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 5),
                  Text(
                    'Create',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Title section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTitleSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INSTITUTIONAL COMMUNICATIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _teal,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10), // â† breathing room below text
          Container(height: 1, color: _border),
        ],
      ),
    );
  }

  // â”€â”€ Filter bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildFilterBar() {
    final labels = {
      'recent': 'Sorted by Recent',
      'oldest': 'Sorted by Oldest',
      'active': 'Active Only',
      'expired': 'Expired Only',
    };
    return GestureDetector(
      onTap: () => _showSortSheet(labels),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              labels[_sortBy] ?? 'Sorted by Recent',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(Map<String, String> labels) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(3),
          topRight: Radius.circular(3),
        ),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sort & Filter',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
          ...labels.entries.map(
            (e) => ListTile(
              onTap: () {
                setState(() => _sortBy = e.key);
                Navigator.pop(context);
              },
              leading: Icon(
                _sortBy == e.key
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: _sortBy == e.key ? _teal : const Color(0xFF9CA3AF),
                size: 20,
              ),
              title: Text(
                e.value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: _sortBy == e.key
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: _sortBy == e.key ? _teal : const Color(0xFF374151),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  // â”€â”€ Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildBody(double navBottom) {
    if (_loading) return const NoticeShimmer();
    if (_error.isNotEmpty) return _buildError();
    if (_filtered.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: _teal,
      onRefresh: _fetchNotices,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 100 + navBottom),
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final notice = _filtered[i];
          return NoticeCard(
            notice: notice,
            onTap: () => _openDetail(notice),
            onEdit: () => _openForm(notice: notice),
            onDelete: () => _deleteNotice(notice['noticeId']?.toString() ?? ''),
          );
        },
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 44),
        const SizedBox(height: 12),
        Text(
          _error,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _fetchNotices,
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          child: const Text('Retry', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Icon(Icons.campaign_outlined, color: _teal, size: 36),
        ),
        const SizedBox(height: 16),
        const Text(
          'No notices yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap + to create your first notice',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
        ),
      ],
    ),
  );
}

