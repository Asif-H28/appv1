import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> with SingleTickerProviderStateMixin {
  String _orgId = '';
  String _adminId = '';
  bool _isLoading = true;
  String _error = '';
  
  List<dynamic> _allLeaves = [];
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    _adminId = prefs.getString('userId') ?? 'ADM_SYSTEM'; // Fallback if missing
    
    if (_orgId.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Organization ID missing. Please login again.';
          _isLoading = false;
        });
      }
      return;
    }
    
    await _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/leave/teacher/org/$_orgId',
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _allLeaves = data['leaves'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load leaves: ${res.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reviewLeave(String leaveId, String status, String note) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF009688))),
    );

    try {
      final res = await http.put(
        Uri.parse('${ApiConstants.apiBaseUrl}/leave/teacher/$leaveId/review'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'status': status,
          'reviewedBy': _adminId,
          'reviewNote': note,
        }),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave request $status successfully'),
            backgroundColor: const Color(0xFF009688),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchLeaves(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update leave: ${res.statusCode}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating leave: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showReviewDialog(Map<String, dynamic> leave, String actionStatus) {
    final noteController = TextEditingController();
    final isApproval = actionStatus == 'approved';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          title: Text(
            isApproval ? 'Approve Leave' : 'Reject Leave',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748), fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to ${isApproval ? 'approve' : 'reject'} the leave for ${leave['teacherName']}?',
                style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Review Note (Optional)',
                  labelStyle: const TextStyle(color: Color(0xFF718096), fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: const BorderSide(color: Color(0xFF009688), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF718096))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isApproval ? const Color(0xFF009688) : Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                _reviewLeave(leave['leaveId'], actionStatus, noteController.text.trim());
              },
              child: Text(isApproval ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Leave Requests',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaveList('pending'),
                    _buildLeaveList('approved'),
                    _buildLeaveList('rejected'),
                  ],
                ),
    );
  }

  Widget _buildLeaveList(String status) {
    final filtered = _allLeaves.where((l) => l['status'] == status).toList();

    if (filtered.isEmpty) {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(
               Icons.event_available_rounded,
               size: 64,
               color: const Color(0xFF009688).withOpacity(0.3),
             ),
             const SizedBox(height: 16),
             Text(
               'No $status requests',
               style: const TextStyle(color: Color(0xFF718096), fontSize: 16),
             ),
           ],
         ),
       );
    }

    return RefreshIndicator(
      color: const Color(0xFF009688),
      onRefresh: _fetchLeaves,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final leave = filtered[index];
          return _buildLeaveCard(leave, status);
        },
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave, String status) {
    final dates = (leave['dates'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final totalDays = leave['totalDays'] ?? 0;
    
    // Formatting dates nicely
    String dateLabel = '';
    if (dates.isNotEmpty) {
      if (dates.length == 1) {
        dateLabel = _formatDateStr(dates.first);
      } else {
        dateLabel = '${_formatDateStr(dates.first)} to ${_formatDateStr(dates.last)}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF009688).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF009688).withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  leave['teacherName'] ?? 'Unknown Teacher',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 16, color: const Color(0xFF009688).withOpacity(0.7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$dateLabel ($totalDays ${totalDays == 1 ? "day" : "days"})',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.subject_rounded, size: 16, color: const Color(0xFF009688).withOpacity(0.7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  leave['reason'] ?? 'No reason provided',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                ),
              ),
            ],
          ),
          
          if (status != 'pending' && leave['reviewNote'] != null && leave['reviewNote'].toString().isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Color(0xFFE2E8F0)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.rate_review_rounded, size: 16, color: const Color(0xFF009688).withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Admin Note: ${leave['reviewNote']}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568), fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],

          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showReviewDialog(leave, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                   ),
                  child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _showReviewDialog(leave, 'approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    elevation: 0,
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    
    if (status == 'approved') {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF059669);
    } else if (status == 'rejected') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  String _formatDateStr(String raw) {
    try {
      final d = DateTime.parse(raw);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return raw;
    }
  }
}

