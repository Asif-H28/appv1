import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class PwaNotificationPanel extends StatefulWidget {
  const PwaNotificationPanel({super.key});

  @override
  State<PwaNotificationPanel> createState() => _PwaNotificationPanelState();
}

class _PwaNotificationPanelState extends State<PwaNotificationPanel> {
  bool _isEnabled = false;
  bool _checking = true;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final enabled = await NotificationService.isNotificationEnabled();
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _checking = false;
      });
    }
  }

  Future<void> _enableNotifications() async {
    setState(() => _requesting = true);
    try {
      final success = await NotificationService.requestPermission();
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        final role = prefs.getString('userRole') ?? '';
        
        if (role == 'admin') {
          final orgId = prefs.getString('orgId') ?? '';
          if (orgId.isNotEmpty) {
            await NotificationService.saveAdminTokenAfterLogin(orgId: orgId);
          }
        } else if (role == 'teacher') {
          final teacherId = prefs.getString('teacherId') ?? '';
          if (teacherId.isNotEmpty) {
            await NotificationService.saveTokenAfterLogin(userId: teacherId, role: 'teacher');
          }
        } else if (role == 'student') {
          final studentId = prefs.getString('studentId') ?? '';
          if (studentId.isNotEmpty) {
            await NotificationService.saveTokenAfterLogin(userId: studentId, role: 'student');
          }
        }
        
        setState(() => _isEnabled = true);
        _showSnack('Notifications enabled successfully!', Colors.teal);
      } else {
        _showiOSInstructionDialog();
      }
    } catch (e) {
      _showSnack('Failed to enable notifications: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _requesting = false);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  void _showiOSInstructionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        title: const Text('Notification Permission Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To enable notifications, please allow permissions. If you are on iOS, follow these steps:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              '1. Ensure this app is added to your Home Screen.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            Text(
              '2. Open iOS Settings > Notifications > SchoolSync.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            Text(
              '3. Turn on "Allow Notifications".',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'After completing these settings, click the "Enable Push Notifications" button again.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PUSH NOTIFICATIONS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.teal,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isEnabled ? 'Notifications Active' : 'Notifications Paused',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isEnabled ? Colors.teal.withOpacity(0.08) : Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _isEnabled ? Colors.teal.withOpacity(0.2) : Colors.orange.withOpacity(0.2)),
                ),
                child: Icon(
                  _isEnabled ? Icons.notifications_active_rounded : Icons.notifications_paused_rounded,
                  color: _isEnabled ? Colors.teal : Colors.orange,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Get real-time updates for school notices, leave requests, achievements, and transport alerts directly on your device.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: _isEnabled
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.teal),
                    label: const Text(
                      'NOTIFICATIONS ENABLED',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 1.1),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.teal, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _requesting ? null : _enableNotifications,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    ),
                    child: _requesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'ENABLE PUSH NOTIFICATIONS',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
