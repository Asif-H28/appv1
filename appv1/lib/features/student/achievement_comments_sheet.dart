import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import 'student_theme_manager.dart';

class AchievementCommentsSheet extends StatefulWidget {
  final String achievementId;
  final String userId;
  final String userName;
  final String userRole;
  final List<Map<String, dynamic>> initialComments;
  final void Function(List<Map<String, dynamic>> comments, int count) onChanged;

  const AchievementCommentsSheet({
    super.key,
    required this.achievementId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.initialComments,
    required this.onChanged,
  });

  @override
  State<AchievementCommentsSheet> createState() =>
      _AchievementCommentsSheetState();
}

class _AchievementCommentsSheetState extends State<AchievementCommentsSheet> {
  late List<Map<String, dynamic>> _comments;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _submitting = false;
  int? _deletingIdx;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.initialComments.reversed);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    _ctrl.clear();
    _focus.unfocus();

    try {
      final url =
          '${ApiConstants.apiBaseUrl}/achievement'
          '/${widget.achievementId}/comment';
      final payload = {
        'userId': widget.userId,
        'userName': widget.userName,
        'userRole': widget.userRole,
        'text': text,
      };

      debugPrint('── [AddComment] POST $url');
      debugPrint('── [AddComment] Payload: ${jsonEncode(payload)}');

      final res = await ApiService.post(url, body: jsonEncode(payload));

      debugPrint('── [AddComment] Status: ${res.statusCode}');
      debugPrint('── [AddComment] Response body: ${res.body}');

      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map;
        final comment = Map<String, dynamic>.from(body['comment'] as Map);
        final count = body['commentCount'] as int? ?? _comments.length + 1;
        debugPrint('── [AddComment] ✅ Comment added: $comment');
        setState(() {
          _comments.insert(0, comment);
          _submitting = false;
        });
        widget.onChanged(List.from(_comments), count);
      } else {
        debugPrint(
          '── [AddComment] ❌ Failed with status ${res.statusCode}: ${res.body}',
        );
        if (mounted) setState(() => _submitting = false);
      }
    } catch (e, st) {
      debugPrint('── [AddComment] 🔥 Exception: $e');
      debugPrint('── [AddComment] StackTrace: $st');
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(int index) async {
    final commentId = _comments[index]['commentId']?.toString() ?? '';
    if (commentId.isEmpty) return;
    setState(() => _deletingIdx = index);
    try {
      await ApiService.delete(
        '${ApiConstants.apiBaseUrl}/achievement'
        '/${widget.achievementId}/comment/$commentId',
      );
      if (!mounted) return;
      setState(() {
        _comments.removeAt(index);
        _deletingIdx = null;
      });
      widget.onChanged(List.from(_comments), _comments.length);
    } catch (_) {
      if (mounted) setState(() => _deletingIdx = null);
    }
  }

  String _timeAgo(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      const m = [
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
      return '${d.day} ${m[d.month]}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    final navBar = mq.padding.bottom;
    final screenH = mq.size.height;

    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, child) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.only(bottom: keyboard > 0 ? keyboard : navBar),
          constraints: BoxConstraints(
            minHeight: screenH * 0.55,
            maxHeight: screenH * 0.92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: theme.primary,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Comments (${_comments.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: theme.dividerColor),

              Flexible(
                child: _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: theme.dividerColor,
                              size: 36,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No comments yet. Be the first!',
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: theme.dividerColor),
                        itemBuilder: (_, i) {
                          final c = _comments[i];
                          final isMe = c['userId']?.toString() == widget.userId;
                          final isDeleting = _deletingIdx == i;

                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isDeleting ? 0.45 : 1.0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: theme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      (c['userName']?.toString() ?? 'U')[0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: theme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              c['userName']?.toString() ?? '',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: theme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _timeAgo(
                                                c['commentedAt']?.toString() ??
                                                    '',
                                              ),
                                              style: TextStyle(
                                                color: theme.textSecondary,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          c['text']?.toString() ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.textPrimary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8,
                                        top: 2,
                                      ),
                                      child: isDeleting
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                color: Colors.red,
                                                strokeWidth: 1.8,
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: _deletingIdx != null
                                                  ? null
                                                  : () => _deleteComment(i),
                                              child: Icon(
                                                Icons.delete_outline_rounded,
                                                color: Colors.red[300],
                                                size: 16,
                                              ),
                                            ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              Divider(height: 1, color: theme.dividerColor),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Add a comment…',
                          hintStyle: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: theme.dividerColor.withOpacity(0.3),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(3),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(3),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(3),
                            borderSide: BorderSide(
                              color: theme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textPrimary,
                        ),
                        onSubmitted: (_) => _addComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _submitting ? null : _addComment,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _submitting
                              ? theme.primary.withOpacity(0.5)
                              : theme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.center,
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
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
}
