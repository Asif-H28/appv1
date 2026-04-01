import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

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
  int? _deletingIdx; // ✅ tracks which row is being deleted

  @override
  void initState() {
    super.initState();
    // ✅ Reverse so latest comment is at top
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
      final res = await http.post(
        Uri.parse(
          'https://appv1backend.onrender.com/api/achievement'
          '/${widget.achievementId}/comment',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'userName': widget.userName,
          'userRole': widget.userRole,
          'text': text,
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map;
        final comment = Map<String, dynamic>.from(body['comment'] as Map);
        final count = body['commentCount'] as int? ?? _comments.length + 1;
        // ✅ Insert at top since list is latest-first
        setState(() => _comments.insert(0, comment));
        widget.onChanged(List.from(_comments), count);
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(int index) async {
    final commentId = _comments[index]['commentId']?.toString() ?? '';
    if (commentId.isEmpty) return;

    setState(() => _deletingIdx = index); // ✅ show spinner on this row

    try {
      await http.delete(
        Uri.parse(
          'https://appv1backend.onrender.com/api/achievement'
          '/${widget.achievementId}/comment/$commentId',
        ),
        headers: {'Content-Type': 'application/json'},
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 12),

          // ── Title ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.teal,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comments (${_comments.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // ── Comments list ─────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.42,
            ),
            child: _comments.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey[300],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _comments.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF6F6F6)),
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
                              // Avatar
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  (c['userName']?.toString() ?? 'U')[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c['userName']?.toString() ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _timeAgo(
                                            c['commentedAt']?.toString() ?? '',
                                          ),
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
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
                                        color: AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ✅ Spinner while deleting, icon when idle
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
                                          // Block taps while another delete runs
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

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // ── Input ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
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
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F7F7),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide: const BorderSide(
                          color: Colors.teal,
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
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
                          ? Colors.teal.withOpacity(0.5)
                          : Colors.teal,
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
  }
}
