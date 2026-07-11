import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/features/student/student_theme_manager.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StudentLeaveScreen extends StatefulWidget {
  const StudentLeaveScreen({super.key});

  @override
  State<StudentLeaveScreen> createState() => _StudentLeaveScreenState();
}

class _StudentLeaveScreenState extends State<StudentLeaveScreen>
    with SingleTickerProviderStateMixin {
  StudentThemeConfig get theme => StudentThemeManager.themeNotifier.value;
  late TabController _tabController;
  String _studentId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPrefs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentId = prefs.getString('studentId') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              _buildHeader(context),
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.primary,
                  unselectedLabelColor: theme.textSecondary,
                  indicatorColor: theme.primary,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Apply Leave'),
                    Tab(text: 'My Requests'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ApplyLeaveTab(
                      studentId: _studentId,
                      onApplied: () => _tabController.animateTo(1),
                    ),
                    _MyLeavesTab(studentId: _studentId),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.primary.withOpacity(0.8)],
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
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave Requests',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Apply and track your leaves',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Icon(
                  Icons.event_note_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Apply Leave Tab ───────────────────────────────────────────────────────────

class _ApplyLeaveTab extends StatefulWidget {
  final String studentId;
  final VoidCallback onApplied;

  const _ApplyLeaveTab({required this.studentId, required this.onApplied});

  @override
  State<_ApplyLeaveTab> createState() => _ApplyLeaveTabState();
}

class _ApplyLeaveTabState extends State<_ApplyLeaveTab> {
  StudentThemeConfig get theme => StudentThemeManager.themeNotifier.value;
  final _reasonCtrl = TextEditingController();
  List<DateTime> _selectedDates = [];
  bool _applying = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(primary: theme.primary),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (picked != null &&
        !_selectedDates.any(
          (d) =>
              d.year == picked.year &&
              d.month == picked.month &&
              d.day == picked.day,
        )) {
      setState(() => _selectedDates.add(picked));
    }
  }

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      _snack('Please enter a reason', Colors.orange[700]!);
      return;
    }
    if (_selectedDates.isEmpty) {
      _snack('Please select at least one date', Colors.orange[700]!);
      return;
    }
    setState(() => _applying = true);
    try {
      final dates = _selectedDates
          .map(
            (d) =>
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
          )
          .toList();

      final res = await ApiService.post(
        '${ApiConstants.apiBaseUrl}/leave/student/apply',
        body: jsonEncode({
          'studentId': widget.studentId,
          'reason': _reasonCtrl.text.trim(),
          'dates': dates,
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack('Leave applied successfully', theme.primary);
        _reasonCtrl.clear();
        setState(() => _selectedDates = []);
        widget.onApplied();
      } else {
        _snack('Failed to apply leave', Colors.red[600]!);
      }
    } catch (_) {
      if (mounted) _snack('No internet connection', Colors.red[600]!);
    }
    if (mounted) setState(() => _applying = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEAVE APPLICATION',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _reasonCtrl,
                      maxLines: 3,
                      style: TextStyle(color: theme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Reason for Leave',
                        labelStyle: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 12,
                        ),
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 32),
                          child: Icon(
                            Icons.edit_note_rounded,
                            color: theme.primary,
                            size: 18,
                          ),
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
                            color: theme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDates.isEmpty
                                ? 'No dates selected'
                                : '${_selectedDates.length} date${_selectedDates.length == 1 ? '' : 's'} selected',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: theme.primary.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: theme.primary,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add Date',
                                  style: TextStyle(
                                    color: theme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedDates.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedDates.map((d) {
                          final label = '${d.day}/${d.month}/${d.year}';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: theme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: theme.primary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedDates.remove(d)),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: theme.primary,
                                    size: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _applying ? null : _submit,
                      child: Container(
                        width: double.infinity,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _applying
                              ? theme.primary.withOpacity(0.6)
                              : theme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.center,
                        child: _applying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Leave Request',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: theme.primary.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: theme.primary,
                      size: 15,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your leave request will be reviewed by your teacher. You can track the status in "My Requests" tab.',
                        style: TextStyle(
                          color: theme.primary,
                          fontSize: 11.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

// ── My Leaves Tab ─────────────────────────────────────────────────────────────

class _MyLeavesTab extends StatefulWidget {
  final String studentId;
  const _MyLeavesTab({required this.studentId});

  @override
  State<_MyLeavesTab> createState() => _MyLeavesTabState();
}

class _MyLeavesTabState extends State<_MyLeavesTab> {
  StudentThemeConfig get theme => StudentThemeManager.themeNotifier.value;
  bool _loading = true;
  List<Map<String, dynamic>> _leaves = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    if (widget.studentId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/leave/student/${widget.studentId}',
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final raw = (body['leaves'] as List? ?? []);
        _leaves = raw.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteLeave(String leaveId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red[600],
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Delete Leave',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this leave request?',
          style: TextStyle(
            color: theme.textSecondary,
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
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textSecondary,
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
                        color: theme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
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
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await ApiService.delete(
        '${ApiConstants.apiBaseUrl}/leave/student/$leaveId',
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _snack('Leave request deleted', theme.primary);
        await _fetchLeaves();
      } else {
        final body = jsonDecode(res.body) as Map;
        _snack(
          body['error']?.toString() ?? 'Failed to delete',
          Colors.red[600]!,
        );
      }
    } catch (_) {
      if (mounted) _snack('No internet connection', Colors.red[600]!);
    }
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
        return theme.primary;
      case 'rejected':
        return Colors.red[600]!;
      default:
        return Colors.orange[700]!;
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return theme.primary.withOpacity(0.08);
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
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        return RefreshIndicator(
          color: theme.primary,
          onRefresh: _fetchLeaves,
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.primary,
                    strokeWidth: 2,
                  ),
                )
              : _leaves.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  itemCount: _leaves.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _LeaveCard(
                    leave: _leaves[i],
                    formatDate: _formatDate,
                    statusColor: _statusColor,
                    statusBg: _statusBg,
                    statusIcon: _statusIcon,
                    onDelete: _deleteLeave,
                  ),
                ),
        );
      },
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
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your leave requests will appear here.',
              style: TextStyle(color: theme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
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

// ── Leave Card ────────────────────────────────────────────────────────────────

class _LeaveCard extends StatefulWidget {
  final Map<String, dynamic> leave;
  final String Function(String) formatDate;
  final Color Function(String) statusColor;
  final Color Function(String) statusBg;
  final IconData Function(String) statusIcon;
  final Future<void> Function(String) onDelete;

  const _LeaveCard({
    required this.leave,
    required this.formatDate,
    required this.statusColor,
    required this.statusBg,
    required this.statusIcon,
    required this.onDelete,
  });

  @override
  State<_LeaveCard> createState() => _LeaveCardState();
}

class _LeaveCardState extends State<_LeaveCard> {
  StudentThemeConfig get theme => StudentThemeManager.themeNotifier.value;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        final status = (widget.leave['status'] ?? 'pending').toString();
        final dates = (widget.leave['dates'] as List? ?? []).cast<String>();
        final reason = widget.leave['reason']?.toString() ?? '';
        final totalDays = widget.leave['totalDays'] ?? dates.length;
        final reviewNote = widget.leave['reviewNote']?.toString() ?? '';
        final createdAt = widget.leave['createdAt']?.toString() ?? '';
        final leaveId = widget.leave['leaveId']?.toString() ?? '';
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
              // Status + days + delete
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.statusBg(status),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.statusIcon(status),
                          color: widget.statusColor(status),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            color: widget.statusColor(status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '$totalDays day${totalDays == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Delete button — pending only
                  if (isPending)
                    GestureDetector(
                      onTap: _deleting
                          ? null
                          : () async {
                              setState(() => _deleting = true);
                              await widget.onDelete(leaveId);
                              if (mounted) setState(() => _deleting = false);
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                          ),
                        ),
                        child: _deleting
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  color: Colors.red[600],
                                  strokeWidth: 1.5,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red[600],
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.red[600],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Reason
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: Colors.grey[400],
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 12.5,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: theme.primary.withOpacity(0.15)),
                    ),
                    child: Text(
                      widget.formatDate(d),
                      style: TextStyle(
                        color: theme.primary,
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
                            color: theme.textSecondary,
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Applied date
              if (createdAt.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Applied on ${widget.formatDate(createdAt)}',
                  style: TextStyle(color: theme.textSecondary, fontSize: 10.5),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
