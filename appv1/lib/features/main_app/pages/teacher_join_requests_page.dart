import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class TeacherJoinRequestsPage extends StatefulWidget {
  @override
  _TeacherJoinRequestsPageState createState() =>
      _TeacherJoinRequestsPageState();
}

class _TeacherJoinRequestsPageState extends State<TeacherJoinRequestsPage>
    with SingleTickerProviderStateMixin {
  String _orgId = '';
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _resolvedRequests = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initPage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    await _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    if (_orgId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/teacher/join-requests/$_orgId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        // ── Flexible parsing ──
        List<dynamic> rawList = [];
        if (body['requests'] != null) {
          rawList = body['requests'] as List;
        } else if (body['data'] != null) {
          rawList = body['data'] as List;
        } else if (body is List) {
          rawList = body as List;
        }

        final all = rawList.map((e) => e as Map<String, dynamic>).toList();

        setState(() {
          _isLoading = false;
          _hasError = false;
          _pendingRequests = all
              .where((r) => r['status']?.toString().toLowerCase() == 'pending')
              .toList();
          _resolvedRequests = all
              .where((r) => r['status']?.toString().toLowerCase() != 'pending')
              .toList();
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _approveRequest(String requestId, int index) async {
    _setCardLoading(index, true, isPending: true);

    try {
      final response = await http.put(
        Uri.parse(
          'https://appv1backend.onrender.com/api/teacher/join-requests/$requestId/approve',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final approved = _pendingRequests[index];
        approved['status'] = 'approved';

        setState(() {
          _pendingRequests.removeAt(index);
          _resolvedRequests.insert(0, approved);
        });

        _showSnackBar('Teacher approved successfully! ✅', Colors.green[600]!);
      } else {
        _setCardLoading(index, false, isPending: true);
        final body = jsonDecode(response.body);
        _showSnackBar(
          body['message']?.toString() ?? 'Failed to approve.',
          Colors.red[600]!,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _setCardLoading(index, false, isPending: true);
      _showSnackBar('No internet connection.', Colors.red[600]!);
    }
  }

  Future<void> _rejectRequest(String requestId, int index) async {
    _setCardLoading(index, true, isPending: true);

    try {
      final response = await http.put(
        Uri.parse(
          'https://appv1backend.onrender.com/api/teacher/join-requests/$requestId/reject',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final rejected = _pendingRequests[index];
        rejected['status'] = 'rejected';

        setState(() {
          _pendingRequests.removeAt(index);
          _resolvedRequests.insert(0, rejected);
        });

        _showSnackBar('Request rejected.', Colors.orange[700]!);
      } else {
        _setCardLoading(index, false, isPending: true);
        final body = jsonDecode(response.body);
        _showSnackBar(
          body['message']?.toString() ?? 'Failed to reject.',
          Colors.red[600]!,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _setCardLoading(index, false, isPending: true);
      _showSnackBar('No internet connection.', Colors.red[600]!);
    }
  }

  void _setCardLoading(int index, bool loading, {required bool isPending}) {
    setState(() {
      if (isPending) {
        _pendingRequests[index]['_loading'] = loading;
      } else {
        _resolvedRequests[index]['_loading'] = loading;
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showRejectConfirmDialog(String requestId, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(Icons.person_remove_rounded, color: Colors.red[600]),
            ),
            SizedBox(width: 12),
            Text(
              'Reject Request',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reject this join request? The teacher account will be deleted.',
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
              _rejectRequest(requestId, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reject',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Gradient Header ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top bar ──
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Join Requests',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Teacher approval management',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ── Pending badge + refresh ──
                        if (_pendingRequests.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_pendingRequests.length} pending',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (!_isLoading)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.refresh, color: Colors.white),
                              onPressed: _fetchRequests,
                              tooltip: 'Refresh',
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // ── Tab bar ──
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: Colors.white.withOpacity(0.9),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        padding: EdgeInsets.all(3),
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hourglass_top_rounded, size: 15),
                                SizedBox(width: 6),
                                Text('Pending'),
                                if (_pendingRequests.isNotEmpty) ...[
                                  SizedBox(width: 6),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_pendingRequests.length}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: 15),
                                SizedBox(width: 6),
                                Text('History'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ──
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isLoading
                  ? _buildLoadingState()
                  : _hasError
                  ? _buildErrorState()
                  : TabBarView(
                      controller: _tabController,
                      children: [_buildPendingTab(), _buildHistoryTab()],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading ──
  Widget _buildLoadingState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
        SizedBox(height: 16),
        Text(
          'Loading join requests...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    ),
  );

  // ── Error ──
  Widget _buildErrorState() => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey[400]),
          SizedBox(height: 14),
          Text(
            'Could not load requests',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Check your internet and try again.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _fetchRequests,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
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

  // ── Pending tab ──
  Widget _buildPendingTab() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline_rounded,
        color: Colors.green,
        title: 'All caught up!',
        subtitle: 'No pending join requests at the moment.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: _pendingRequests.length,
      separatorBuilder: (_, __) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = _pendingRequests[index];
        return _buildRequestCard(request: req, index: index, isPending: true);
      },
    );
  }

  // ── History tab ──
  Widget _buildHistoryTab() {
    if (_resolvedRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        color: Colors.grey,
        title: 'No history yet',
        subtitle: 'Approved or rejected requests will appear here.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: _resolvedRequests.length,
      separatorBuilder: (_, __) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = _resolvedRequests[index];
        return _buildRequestCard(request: req, index: index, isPending: false);
      },
    );
  }

  // ── Request card ──
  Widget _buildRequestCard({
    required Map<String, dynamic> request,
    required int index,
    required bool isPending,
  }) {
    final name =
        request['teacherName']?.toString() ??
        request['name']?.toString() ??
        'Unknown Teacher';
    final email = request['email']?.toString() ?? '';
    final requestId =
        request['requestId']?.toString() ?? request['_id']?.toString() ?? '';
    final status = request['status']?.toString() ?? 'pending';
    final isCardLoading = request['_loading'] == true;

    final isApproved = status.toLowerCase() == 'approved';
    final isRejected = status.toLowerCase() == 'rejected';

    final statusColor = isPending
        ? Colors.orange
        : isApproved
        ? Colors.green
        : Colors.red;

    final statusLabel = isPending
        ? 'Pending'
        : isApproved
        ? 'Approved'
        : 'Rejected';

    final statusIcon = isPending
        ? Icons.hourglass_top_rounded
        : isApproved
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.15), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Teacher info row ──
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'T',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ── Status badge ──
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Request ID ──
            if (requestId.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      requestId,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Action buttons (only for pending) ──
            if (isPending) ...[
              SizedBox(height: 14),
              Row(
                children: [
                  // Reject
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isCardLoading
                          ? null
                          : () => _showRejectConfirmDialog(requestId, index),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        side: BorderSide(color: Colors.red.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(Icons.close_rounded, size: 18),
                      label: Text(
                        'Reject',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Approve
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: isCardLoading
                          ? null
                          : () => _approveRequest(requestId, index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.green.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      icon: isCardLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        isCardLoading ? 'Processing...' : 'Approve',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Center(
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
                color: color.withOpacity(0.1),
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
