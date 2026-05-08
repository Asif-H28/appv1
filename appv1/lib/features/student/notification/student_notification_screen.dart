import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import 'notification_card.dart';

class StudentNotificationScreen extends StatefulWidget {
  const StudentNotificationScreen({super.key});

  @override
  State<StudentNotificationScreen> createState() =>
      _StudentNotificationScreenState();
}

class _StudentNotificationScreenState extends State<StudentNotificationScreen> {
  List<Map<String, dynamic>> _allNotifs = [];
  bool _loading = true;
  int _unreadCount = 0;

  String _studentId = '';
  String _classId = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getString('studentId') ?? '';
    _classId = prefs.getString('classId') ?? '';
    await _fetchAll();
    await _fetchUnreadCount();
  }

  // ── Fetch both APIs and merge into one sorted list ────
  Future<void> _fetchAll() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final List<Map<String, dynamic>> combined = [];

    try {
      // 1️⃣ My personal notifications
      if (_studentId.isNotEmpty) {
        final res = await ApiService.get(
          '${ApiConstants.apiBaseUrl}/notification/student/$_studentId',
        );
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final list = (body['notifications'] as List? ?? [])
              .map(
                (e) =>
                    Map<String, dynamic>.from(e as Map)
                      ..['_source'] = 'personal',
              )
              .toList();
          combined.addAll(list);
        }
      }

      // 2️⃣ Class-wide notifications
      if (_classId.isNotEmpty) {
        final res = await ApiService.get(
          '${ApiConstants.apiBaseUrl}/notification/class/$_classId',
        );
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final list = (body['notifications'] as List? ?? [])
              .map(
                (e) =>
                    Map<String, dynamic>.from(e as Map)..['_source'] = 'class',
              )
              .toList();
          combined.addAll(list);
        }
      }

      // Sort newest first
      combined.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
            DateTime(2000);
        final bDate =
            DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
            DateTime(2000);
        return bDate.compareTo(aDate);
      });
    } catch (_) {}

    if (mounted) {
      setState(() {
        _allNotifs = combined;
        _loading = false;
      });
    }
  }

  // ── Get unread count from API ─────────────────────────
  Future<void> _fetchUnreadCount() async {
    if (_classId.isEmpty || _studentId.isEmpty) return;
    try {
      final res = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/notification/class/$_classId/unread/$_studentId',
      );
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        setState(() {
          _unreadCount = body['unreadCount'] as int? ?? 0;
        });
      }
    } catch (_) {}
  }

  // ── Mark single notification as read ─────────────────
  Future<void> _markAsRead(String notifId) async {
    if (_studentId.isEmpty) return;
    try {
      await ApiService.put(
        '${ApiConstants.apiBaseUrl}/notification/$notifId/read',
        body: jsonEncode({'userId': _studentId}),
      );
      // Update local state instantly
      if (mounted) {
        setState(() {
          final idx = _allNotifs.indexWhere(
            (n) => n['notificationId'] == notifId,
          );
          if (idx != -1) {
            final readBy = List<String>.from(
              _allNotifs[idx]['readBy'] as List? ?? [],
            );
            if (!readBy.contains(_studentId)) {
              readBy.add(_studentId);
              _allNotifs[idx] = {..._allNotifs[idx], 'readBy': readBy};
              if (_unreadCount > 0) _unreadCount--;
            }
          }
        });
      }
    } catch (_) {}
  }

  // ── Mark all as read ──────────────────────────────────
  Future<void> _markAllAsRead() async {
    if (_classId.isEmpty || _studentId.isEmpty) return;
    try {
      await ApiService.put(
        '${ApiConstants.apiBaseUrl}/notification/class/$_classId/read-all',
        body: jsonEncode({'userId': _studentId}),
      );
      // Update all local items instantly
      if (mounted) {
        setState(() {
          _allNotifs = _allNotifs.map((n) {
            final readBy = List<String>.from(n['readBy'] as List? ?? []);
            if (!readBy.contains(_studentId)) readBy.add(_studentId);
            return {...n, 'readBy': readBy};
          }).toList();
          _unreadCount = 0;
        });
      }
    } catch (_) {}
  }

  bool _isRead(Map<String, dynamic> notif) {
    final readBy = List<String>.from(notif['readBy'] as List? ?? []);
    return readBy.contains(_studentId);
  }

  void _refresh() => _init();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.teal,
                      strokeWidth: 2.5,
                    ),
                  )
                : _allNotifs.isEmpty
                ? _buildEmpty()
                : _buildList(),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────
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
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title + unread badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '$_unreadCount unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Text(
                      'All your updates in one place',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Mark all read button
              if (_unreadCount > 0)
                GestureDetector(
                  onTap: _markAllAsRead,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                // Refresh button (shown when nothing unread)
                GestureDetector(
                  onTap: _refresh,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
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

  // ── Notification list ─────────────────────────────────
  Widget _buildList() {
    return RefreshIndicator(
      color: Colors.teal,
      onRefresh: () async => _refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
        itemCount: _allNotifs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final notif = _allNotifs[i];
          final isRead = _isRead(notif);
          final notifId = notif['notificationId']?.toString() ?? '';
          return NotificationCard(
            data: notif,
            isRead: isRead,
            onTap: isRead ? null : () => _markAsRead(notifId),
          );
        },
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.teal,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Results, attendance, notices\nwill all appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _refresh,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.teal.withOpacity(0.3)),
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

