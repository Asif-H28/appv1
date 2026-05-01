import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'leave_request_page.dart';
import '../../../../core/constants/app_colors.dart';

class AdminLeaveNotificationsPage extends StatefulWidget {
  const AdminLeaveNotificationsPage({super.key});

  @override
  State<AdminLeaveNotificationsPage> createState() =>
      _AdminLeaveNotificationsPageState();
}

class _AdminLeaveNotificationsPageState
    extends State<AdminLeaveNotificationsPage> {
  static const _teal = Color(0xFF00796B);

  String _orgId = '';
  bool _loading = true;
  bool _error = false;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    debugPrint('── [LeaveNotif] orgId from prefs: "$_orgId"');
    await _load();
  }

  Future<void> _load() async {
    if (_orgId.isEmpty) {
      debugPrint('── [LeaveNotif] ❌ orgId is empty — skipping fetch');
      setState(() {
        _loading = false;
        _error = false;
      });
      return;
    }
    debugPrint('── [LeaveNotif] Fetching for orgId: $_orgId');
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final list =
          await NotificationService.getTeacherLeaveNotifications(_orgId);
      debugPrint('── [LeaveNotif] Received ${list.length} items');
      for (int i = 0; i < list.length; i++) {
        debugPrint('── [LeaveNotif] Item[$i] keys: ${list[i].keys.toList()}');
        debugPrint('── [LeaveNotif] Item[$i]: ${list[i]}');
      }
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _loading = false;
      });
      // Mark all unread notifications as read
      _markAllRead(list);
    } catch (e, st) {
      debugPrint('── [LeaveNotif] ❌ Exception: $e');
      debugPrint('── [LeaveNotif] Stack: $st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _markAllRead(List<Map<String, dynamic>> list) {
    if (_orgId.isEmpty || list.isEmpty) return;
    // Single bulk call — marks all unread leave notifications as read
    NotificationService.markAllLeaveNotificationsRead(orgId: _orgId);
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }

  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Teacher leave requests',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2.5),
      );
    }
    if (_error) return _buildError();
    if (_notifications.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: Colors.teal,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 60),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildCard(_notifications[i]),
      ),
    );
  }

  // ── Notification card ─────────────────────────────────
  Widget _buildCard(Map<String, dynamic> n) {
    final title = n['title']?.toString() ?? 'Leave Request';
    final body = n['body']?.toString() ?? '';
    final sentByName = n['sentByName']?.toString() ?? '';
    final createdAt = n['createdAt']?.toString();
    final data = n['data'] as Map<String, dynamic>? ?? {};
    final leaveId = data['leaveId']?.toString() ?? '';
    final readBy = (n['readBy'] as List? ?? []);
    final isRead = readBy.any((r) => r.toString() == _orgId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border(
          left: BorderSide(
            color: isRead ? const Color(0xFFE5E7EB) : _teal,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: icon + title + time ───────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: _teal,
                    size: 18,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sentByName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              size: 11,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              sentByName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _timeAgo(createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),

            // ── Body text ────────────────────────────────
            if (body.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF4B5563),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ── Leave ID + View button ────────────────────
            const SizedBox(height: 12),
            Row(
              children: [
                if (leaveId.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: _teal.withOpacity(0.2)),
                    ),
                    child: Text(
                      'ID: $leaveId',
                      style: const TextStyle(
                        fontSize: 10,
                        color: _teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                // View Leave button
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaveRequestPage(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _teal,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Leave',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────
  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_rounded, size: 44, color: Colors.grey[400]),
        const SizedBox(height: 12),
        const Text(
          'Failed to load notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _load,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
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
  );

  // ── Empty state ────────────────────────────────────────
  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Icon(
            Icons.event_busy_rounded,
            color: _teal,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No leave notifications yet',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Teacher leave requests will appear here',
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    ),
  );
}
