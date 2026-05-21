import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class InAppNotificationOverlay {
  static void show(NotificationModel notification) {
    final context = DioClient.navigatorKey.currentContext;
    if (context == null) return;

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: SafeArea(
          top: false,
          bottom: false,
          child: _InAppToastWidget(
            notification: notification,
            onDismiss: () {
              if (overlayEntry.mounted) {
                overlayEntry.remove();
              }
            },
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    // Auto dismiss after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _InAppToastWidget extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;

  const _InAppToastWidget({required this.notification, required this.onDismiss});

  @override
  State<_InAppToastWidget> createState() => _InAppToastWidgetState();
}

class _InAppToastWidgetState extends State<_InAppToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: () {
            widget.onDismiss();
            // Optional: Tap action to open notification page
          },
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                // Premium glassmorphic dark design
                color: const Color(0xFF1E1E2E).withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.teal, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.notification.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.notification.body,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                    onPressed: widget.onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
