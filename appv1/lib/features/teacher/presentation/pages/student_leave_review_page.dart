import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

class StudentLeaveReviewPage extends StatefulWidget {
  final List<Map<String, dynamic>> classrooms;
  final String teacherId;

  const StudentLeaveReviewPage({
    super.key,
    required this.classrooms,
    required this.teacherId,
  });

  @override
  State<StudentLeaveReviewPage> createState() => _StudentLeaveReviewPageState();
}

class _StudentLeaveReviewPageState extends State<StudentLeaveReviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Per-class data
  bool _loading = true;
  List<Map<String, dynamic>> _allLeaves = [];
  List<Map<String, dynamic>> _pendingLeaves = [];

  // Filter: 0 = All, 1 = Pending, 2 = Approved, 3 = Rejected
  int _filter = 1; // default to pending

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLeaves();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaves() async {
    setState(() => _loading = true);
    final List<Map<String, dynamic>> all = [];
    final List<Map<String, dynamic>> pending = [];

    try {
      for (final cls in widget.classrooms) {
        final classId = cls['classId']?.toString() ?? '';
        if (classId.isEmpty) continue;

        // All leaves
        final resAll = await http.get(
          Uri.parse(
            'https://appv1backend.onrender.com/api/leave/student/class/$classId',
          ),
          headers: {'Content-Type': 'application/json'},
        );
        if (resAll.statusCode == 200) {
          final body = jsonDecode(resAll.body) as Map;
          final list = (body['leaves'] as List? ?? [])
              .map((e) => e as Map<String, dynamic>)
              .toList();
          all.addAll(list);
        }

        // Pending count
        final resPending = await http.get(
          Uri.parse(
            'https://appv1backend.onrender.com/api/leave/student/class/$classId/pending',
          ),
          headers: {'Content-Type': 'application/json'},
        );
        if (resPending.statusCode == 200) {
          final body = jsonDecode(resPending.body) as Map;
          final list = (body['leaves'] as List? ?? [])
              .map((e) => e as Map<String, dynamic>)
              .toList();
          pending.addAll(list);
        }
      }
    } catch (_) {}

    // Sort newest first
    all.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
    pending.sort(
      (a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''),
    );

    if (mounted) {
      setState(() {
        _allLeaves = all;
        _pendingLeaves = pending;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredLeaves {
    switch (_filter) {
      case 1:
        return _allLeaves.where((l) => l['status'] == 'pending').toList();
      case 2:
        return _allLeaves.where((l) => l['status'] == 'approved').toList();
      case 3:
        return _allLeaves.where((l) => l['status'] == 'rejected').toList();
      default:
        return _allLeaves;
    }
  }

  Future<void> _reviewLeave(String leaveId, String status, String note) async {
    try {
      final res = await http.put(
        Uri.parse(
          'https://appv1backend.onrender.com/api/leave/student/$leaveId/review',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'reviewedBy': widget.teacherId,
          'reviewNote': note,
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _snack(
          status == 'approved' ? 'Leave approved' : 'Leave rejected',
          status == 'approved' ? Colors.teal : Colors.red[600]!,
        );
        await _fetchLeaves();
      } else {
        _snack('Failed to update leave', Colors.red[600]!);
      }
    } catch (_) {
      if (mounted) _snack('No internet connection', Colors.red[600]!);
    }
  }

  void _showReviewDialog(Map<String, dynamic> leave, String action) {
    final noteCtrl = TextEditingController();
    final leaveId = leave['leaveId']?.toString() ?? '';
    final isApprove = action == 'approved';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isApprove ? Colors.teal : Colors.red).withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                isApprove
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_outlined,
                color: isApprove ? Colors.teal : Colors.red[600],
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isApprove ? 'Approve Leave' : 'Reject Leave',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student: ${leave['studentName'] ?? ''}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                hintText: isApprove
                    ? 'e.g. Get well soon (optional)'
                    : 'e.g. Exam on this day (optional)',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(
                    color: isApprove ? Colors.teal : Colors.red[400]!,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
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
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _reviewLeave(leaveId, action, noteCtrl.text.trim());
                  },
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: isApprove ? Colors.teal : Colors.red[600],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isApprove ? 'Approve' : 'Reject',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
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
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return Colors.teal;
      case 'rejected':
        return Colors.red[600]!;
      default:
        return Colors.orange[700]!;
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return Colors.teal.withOpacity(0.08);
      case 'rejected':
        return Colors.red.withOpacity(0.08);
      default:
        return Colors.orange.withOpacity(0.08);
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _allLeaves.where((l) => l['status'] == 'pending').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          // Filter chips
          // After
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _filterChip('All', 0, _allLeaves.length),
                  const SizedBox(width: 6),
                  _filterChip('Pending', 1, pending),
                  const SizedBox(width: 6),
                  _filterChip(
                    'Approved',
                    2,
                    _allLeaves.where((l) => l['status'] == 'approved').length,
                  ),
                  const SizedBox(width: 6),
                  _filterChip(
                    'Rejected',
                    3,
                    _allLeaves.where((l) => l['status'] == 'rejected').length,
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: Colors.grey[100]),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.teal,
                      strokeWidth: 2,
                    ),
                  )
                : _filteredLeaves.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    color: Colors.teal,
                    onRefresh: _fetchLeaves,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _filteredLeaves.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _buildLeaveCard(_filteredLeaves[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int index, int count) {
    final active = _filter == index;
    return GestureDetector(
      onTap: () => setState(() => _filter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.teal.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: active ? Colors.teal.withOpacity(0.3) : Colors.grey[200]!,
          ),
        ),
        child: Text(
          count > 0 ? '$label ($count)' : label,
          style: TextStyle(
            color: active ? Colors.teal : AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

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
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(
            children: [
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
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Leave Requests',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _loading
                          ? 'Loading...'
                          : '${_allLeaves.length} total requests',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _fetchLeaves,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No Leave Requests',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No requests match this filter.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final status = (leave['status'] ?? 'pending').toString();
    final dates = (leave['dates'] as List? ?? []).cast<String>();
    final reason = leave['reason']?.toString() ?? '';
    final totalDays = leave['totalDays'] ?? dates.length;
    final reviewNote = leave['reviewNote']?.toString() ?? '';
    final createdAt = leave['createdAt']?.toString() ?? '';
    final studentName = leave['studentName']?.toString() ?? 'Student';
    final isPending = status.toLowerCase() == 'pending';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student name + status
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.teal,
                  size: 17,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  studentName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg(status),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(status),
                      color: _statusColor(status),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Reason
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.edit_note_rounded, color: Colors.grey[400], size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reason,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '$totalDays day${totalDays == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Date chips
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: dates.map((d) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.teal.withOpacity(0.15)),
                ),
                child: Text(
                  _formatDate(d),
                  style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),

          // Review note
          if (reviewNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.comment_outlined,
                    color: Colors.grey[400],
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reviewNote,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Applied on ${_formatDate(createdAt)}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
            ),
          ],

          // Approve / Reject buttons — pending only
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showReviewDialog(leave, 'rejected'),
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            color: Colors.red[600],
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reject',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showReviewDialog(leave, 'approved'),
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: Colors.teal.withOpacity(0.25),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_rounded,
                            color: Colors.teal,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Approve',
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }
}
