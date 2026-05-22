import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/chat_socket_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String participantName;
  final String participantId;
  final bool isGroup;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.participantName,
    required this.participantId,
    this.isGroup = false,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatSocketService _socketService = ChatSocketService();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  String? _typingUserName;
  String _currentUserId = '';
  String _currentUserName = '';

  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  Timer? _typingTimer;
  bool _isOnline = false;
  String _lastSeen = '';

  // Stream Subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _stopTypingSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _onlineSubscription;

  @override
  void initState() {
    super.initState();
    _initChat();
    _setupSocketListeners();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMessages(loadMore: true);
    }
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId =
        prefs.getString('userId') ??
        prefs.getString('teacherId') ??
        prefs.getString('studentId') ??
        prefs.getString('orgId') ??
        '';
    _currentUserName =
        prefs.getString('userName') ??
        prefs.getString('teacherName') ??
        prefs.getString('studentName') ??
        'Me';

    await _loadMessages();
    _fetchInitialStatus();
    _socketService.joinConversation(widget.conversationId);
    ApiService.markMessagesAsRead(widget.conversationId);
    _socketService.triggerUnreadRefresh();

    // Mark undelivered messages as delivered
    for (var msg in _messages) {
      if (msg['senderId'] != _currentUserId && msg['status'] == 'sent') {
        _socketService.emitDelivered(msg['_id'], widget.conversationId);
      }
    }
  }

  void _setupSocketListeners() {
    _messageSubscription = _socketService.onNewMessage.listen((data) {
      if (data['conversationId'] == widget.conversationId) {
        if (mounted) {
          setState(() {
            final String? incomingId = data['_id']?.toString();
            final String? incomingTempId = data['tempId']?.toString();
            final String incomingSenderId = data['senderId']?.toString() ?? '';
            final bool isFromMe = incomingSenderId == _currentUserId;

            // Robust duplicate detection
            int existingIndex = _messages.indexWhere((m) {
              final String? localId = m['_id']?.toString();
              final String? localTempId = m['tempId']?.toString();

              // 1. Match by real ID
              if (localId != null &&
                  incomingId != null &&
                  localId == incomingId)
                return true;

              // 2. Match by temp ID
              if (localTempId != null &&
                  incomingTempId != null &&
                  localTempId == incomingTempId)
                return true;

              // 3. Fallback: Match optimistic message by content if ID is missing from local but present in incoming
              if (isFromMe && localId == null && incomingId != null) {
                final String incomingContent =
                    (data['content'] ?? data['text'] ?? '').toString().trim();
                final String localContent = (m['content'] ?? m['text'] ?? '')
                    .toString()
                    .trim();
                if (incomingContent == localContent) return true;
              }

              return false;
            });

            if (existingIndex == -1) {
              // Not found, insert as new message
              _messages.insert(0, data);
            } else {
              // Found, update the existing message (replaces optimistic with real server data)
              _messages[existingIndex] = data;
            }
          });

          if (data['senderId'] != _currentUserId) {
            _socketService.emitRead(widget.conversationId, _currentUserId);
            _socketService.emitDelivered(data['_id'], widget.conversationId);
          }
        }
      }
    });

    _typingSubscription = _socketService.onTyping.listen((data) {
      if (data['conversationId'] == widget.conversationId &&
          data['userId'] != _currentUserId) {
        if (mounted) {
          setState(() {
            _isTyping = true;
            _typingUserName = data['userName'];
          });
        }
      }
    });

    _stopTypingSubscription = _socketService.onStopTyping.listen((data) {
      if (data['conversationId'] == widget.conversationId &&
          data['userId'] != _currentUserId) {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
        }
      }
    });

    _statusSubscription = _socketService.onStatusUpdate.listen((data) {
      if (data['conversationId'] == widget.conversationId) {
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere(
              (m) => m['_id'] == data['messageId'],
            );
            if (index != -1) {
              _messages[index]['status'] = data['status'];
            }
          });
        }
      }
    });

    _onlineSubscription = _socketService.onOnlineStatus.listen((data) {
      if (data['userId'] == widget.participantId) {
        if (mounted) {
          setState(() {
            _isOnline = data['isOnline'] ?? data['online'] ?? false;
            if (!_isOnline) _lastSeen = data['lastSeen'] ?? '';
          });
        }
      }
    });
  }

  Future<void> _fetchInitialStatus() async {
    if (widget.participantId.isEmpty) return;
    final result = await ApiService.getUserStatus(widget.participantId);
    if (result['success'] && mounted) {
      setState(() {
        final data = result['data'];
        _isOnline = data['isOnline'] ?? data['online'] ?? false;
        _lastSeen = data['lastSeen'] ?? '';
      });
    }
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (widget.conversationId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (loadMore) {
      setState(() => _isLoadingMore = true);
      _page++;
    }

    final response = await ApiService.get(
      '/chat/messages/${widget.conversationId}?page=$_page&limit=30',
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List newMessages = [];
      if (decoded is List) {
        newMessages = decoded;
      } else if (decoded is Map && decoded['messages'] != null) {
        newMessages = decoded['messages'];
      }

      if (mounted) {
        setState(() {
          if (loadMore) {
            _messages.addAll(newMessages);
          } else {
            _messages = newMessages;
          }
          _hasMore = newMessages.length == 30;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } else {
      if (mounted)
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
    }
  }

  void _handleSendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final payload = {
      'conversationId': widget.conversationId,
      'senderId': _currentUserId,
      'senderName': _currentUserName,
      'content': text,
      'type': 'text',
      'tempId': tempId,
      'status': 'sent',
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Optimistic UI
    setState(() {
      _messages.insert(0, payload);
    });

    _socketService.sendMessage(payload);
    _messageController.clear();
    _socketService.emitStopTyping(widget.conversationId, _currentUserId);
  }

  void _onTextChanged(String val) {
    _socketService.emitTyping(
      widget.conversationId,
      _currentUserId,
      _currentUserName,
    );

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _socketService.emitStopTyping(widget.conversationId, _currentUserId);
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _stopTypingSubscription?.cancel();
    _statusSubscription?.cancel();
    _onlineSubscription?.cancel();

    ApiService.markMessagesAsRead(widget.conversationId);
    ChatSocketService().triggerUnreadRefresh();
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              color: Colors.teal,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }
                      final msg = _messages[index];
                      final isMe = msg['senderId'] == _currentUserId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.teal,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Text(
              widget.participantName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.teal,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.participantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!widget.isGroup)
                  Text(
                    _isOnline
                        ? 'Online'
                        : (_lastSeen.isNotEmpty
                              ? 'Last seen ${_formatLastSeen(_lastSeen)}'
                              : 'Offline'),
                    style: TextStyle(
                      color: _isOnline ? Colors.tealAccent : Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat.jm().format(date);
    } catch (_) {
      return '';
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe
                ? const Radius.circular(12)
                : const Radius.circular(0),
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isGroup && !isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  msg['senderName'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            Text(
              msg['text'] ?? msg['content'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.jm().format(
                    DateTime.parse(msg['createdAt']).toLocal(),
                  ),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _getStatusIcon(msg['status']),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusIcon(String? status) {
    switch (status) {
      case 'sent':
        return const Icon(Icons.done, size: 14, color: Colors.white70);
      case 'delivered':
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);
      case 'read':
        return const Icon(Icons.done_all, size: 14, color: Colors.cyanAccent);
      default:
        return const Icon(Icons.access_time, size: 14, color: Colors.white70);
    }
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${widget.isGroup ? _typingUserName : 'Participant'} is typing',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 4),
          const _BouncingDots(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  onChanged: _onTextChanged,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 4,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _handleSendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  const _BouncingDots({Key? key}) : super(key: key);

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(
                  0.3 + (0.7 * _controller.value),
                ),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
