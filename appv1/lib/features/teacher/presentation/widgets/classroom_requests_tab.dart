import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

class ClassroomRequestsTab extends StatefulWidget {
  final String classId;
  const ClassroomRequestsTab({required this.classId});

  @override
  _ClassroomRequestsTabState createState() => _ClassroomRequestsTabState();
}

class _ClassroomRequestsTabState extends State<ClassroomRequestsTab> {
  static const Color _accent = Colors.teal;

  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  bool _hasError = false;

  // Track per-request loading state
  final Map<String, bool> _loadingMap = {};

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/join/class/${widget.classId}',
        ),
        headers: await ApiService.getHeaders(),
      );

      debugPrint('REQUESTS STATUS: ${response.statusCode}');
      debugPrint('REQUESTS BODY: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> raw = [];
        if (body is List) {
          raw = body;
        } else if (body['requests'] != null) {
          raw = body['requests'] as List;
        } else if (body['data'] != null) {
          raw = body['data'] as List;
        }

        setState(() {
          _requests = raw.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      debugPrint('FETCH REQUESTS ERROR: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _approve(String requestId) async {
    setState(() => _loadingMap[requestId] = true);
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/join/$requestId/approve',
        ),
        headers: await ApiService.getHeaders(),
      );

      debugPrint('APPROVE STATUS: ${response.statusCode}');

      if (!mounted) return;
      setState(() => _loadingMap[requestId] = false);

      if (response.statusCode == 200) {
        _updateRequestStatus(requestId, 'approved');
        _snack('✅ Student approved!', Colors.green[600]!);
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _snack(
          body['message']?.toString() ?? 'Failed to approve.',
          Colors.red[600]!,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMap[requestId] = false);
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  Future<void> _reject(String requestId) async {
    final reason = await _showRejectDialog();
    if (reason == null) return; // cancelled

    setState(() => _loadingMap[requestId] = true);
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/join/$requestId/reject',
        ),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({'rejectionReason': reason}),
      );

      debugPrint('REJECT STATUS: ${response.statusCode}');

      if (!mounted) return;
      setState(() => _loadingMap[requestId] = false);

      if (response.statusCode == 200) {
        _updateRequestStatus(requestId, 'rejected');
        _snack('❌ Request rejected.', Colors.orange[700]!);
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _snack(
          body['message']?.toString() ?? 'Failed to reject.',
          Colors.red[600]!,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMap[requestId] = false);
      _snack('No internet connection.', Colors.red[600]!);
    }
  }

  void _updateRequestStatus(String requestId, String status) {
    setState(() {
      final idx = _requests.indexWhere(
        (r) =>
            r['requestId']?.toString() == requestId ||
            r['_id']?.toString() == requestId,
      );
      if (idx != -1) {
        _requests[idx] = Map.from(_requests[idx])..['status'] = status;
      }
    });
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.cancel_outlined,
                color: Colors.red[400],
                size: 18,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Reject Request',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason (optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: controller,
                cursorColor: Colors.teal,
                maxLines: 3,
                style: TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Class is full, Wrong class...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              ctx,
              controller.text.trim().isEmpty
                  ? 'No reason provided'
                  : controller.text.trim(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Reject',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
      );
    }

    if (_hasError) {
      return _buildError();
    }

    // ── Separate into pending vs actioned ──
    final pending = _requests
        .where((r) => r['status']?.toString() == 'pending')
        .toList();
    final actioned = _requests
        .where((r) => r['status']?.toString() != 'pending')
        .toList();

    if (_requests.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _fetchRequests,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // ── Pending ──
          if (pending.isNotEmpty) ...[
            _sectionHeader(
              Icons.pending_actions_rounded,
              'Pending Requests',
              '${pending.length}',
              Colors.orange[700]!,
            ),
            SizedBox(height: 10),
            ...pending.map((r) => _requestCard(r, isPending: true)),
            SizedBox(height: 20),
          ],

          // ── Actioned ──
          if (actioned.isNotEmpty) ...[
            _sectionHeader(
              Icons.history_rounded,
              'Previous Requests',
              '${actioned.length}',
              Colors.grey[500]!,
            ),
            SizedBox(height: 10),
            ...actioned.map((r) => _requestCard(r, isPending: false)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(
    IconData icon,
    String title,
    String count,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(width: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _requestCard(Map<String, dynamic> request, {required bool isPending}) {
    final requestId =
        request['requestId']?.toString() ?? request['_id']?.toString() ?? '';
    final studentName = request['studentName']?.toString() ?? 'Unknown Student';
    final studentEmail = request['studentEmail']?.toString() ?? '';
    final status = request['status']?.toString() ?? 'pending';
    final createdAt = request['createdAt']?.toString() ?? '';
    final isProcessing = _loadingMap[requestId] == true;

    // Format date
    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr =
            '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = Colors.green[600]!;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = Colors.red[400]!;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange[700]!;
        statusIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isPending
              ? Colors.orange.withOpacity(0.25)
              : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: avatar + name + status badge ──
            Row(
              children: [
                // ── Avatar ──
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accent, _accent.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      studentName.isNotEmpty
                          ? studentName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // ── Name + email ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (studentEmail.isNotEmpty)
                        Text(
                          studentEmail,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Status badge ──
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 11),
                      SizedBox(width: 4),
                      Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Date ──
            if (dateStr.isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 11,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Requested: $dateStr',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],

            // ── Action buttons (only for pending) ──
            if (isPending) ...[
              SizedBox(height: 12),
              isProcessing
                  ? Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: _accent,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        // ── Approve ──
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _approve(requestId),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.green[600],
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Approve',
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
                        ),
                        SizedBox(width: 8),

                        // ── Reject ──
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _reject(requestId),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Reject',
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
                        ),
                      ],
                    ),
            ],

            // ── Rejection reason (if rejected) ──
            if (status == 'rejected' && request['rejectionReason'] != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 12,
                      color: Colors.red[400],
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${request['rejectionReason']}',
                        style: TextStyle(color: Colors.red[400], fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.08),
            ),
            child: Icon(Icons.person_add_rounded, color: _accent, size: 32),
          ),
          SizedBox(height: 14),
          Text(
            'No Join Requests',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Students who request to join this class\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
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
          Icon(Icons.cloud_off_rounded, size: 46, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'Could not load requests',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchRequests,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: Icon(Icons.refresh, size: 15),
            label: Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    ),
  );
}

