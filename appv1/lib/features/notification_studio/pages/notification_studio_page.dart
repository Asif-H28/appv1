import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/notification_studio_controller.dart';
import '../models/notification_model.dart';

class NotificationStudioPage extends StatefulWidget {
  const NotificationStudioPage({super.key});

  @override
  State<NotificationStudioPage> createState() => _NotificationStudioPageState();
}

class _NotificationStudioPageState extends State<NotificationStudioPage> {
  final NotificationStudioController _controller = NotificationStudioController();

  @override
  void initState() {
    super.initState();
    // Load notifications on page open
    _controller.loadNotifications();
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final notifications = _controller.notifications;
        final unreadCount = _controller.unreadCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: const Text(
              'Notification Studio',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: () => _controller.markAllNotificationsRead(),
                  icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Mark all read',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          body: RefreshIndicator(
            color: Colors.teal,
            onRefresh: () => _controller.loadNotifications(),
            child: _controller.isLoading && notifications.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.teal,
                      strokeWidth: 2.5,
                    ),
                  )
                : notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return _buildNotificationCard(notif);
                        },
                      ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 64,
                  color: Colors.teal.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'All caught up!',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No new announcements at this time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notif.isRead ? Colors.transparent : Colors.teal.withOpacity(0.15),
          width: 1,
        ),
      ),
      color: notif.isRead ? Colors.white : Colors.teal.withOpacity(0.02),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!notif.isRead) {
            _controller.markSingleNotificationRead(notif.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread indicator dot or general icon
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: notif.isRead ? Colors.grey.shade300 : Colors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              color: const Color(0xFF1E293B),
                              fontSize: 14,
                              fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateTime(notif.createdAt),
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.body,
                      style: TextStyle(
                        color: const Color(0xFF475569),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
