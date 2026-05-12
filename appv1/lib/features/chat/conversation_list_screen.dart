import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/chat_socket_service.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';
import '../teacher/presentation/pages/teacher_settings_page.dart';
import 'package:intl/intl.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({Key? key}) : super(key: key);

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String _currentUserId = '';
  final _socketService = ChatSocketService();
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _messageSubscription = _socketService.onNewMessage.listen(
      (_) => _loadConversations(),
    );
    _socketService.onStatusUpdate.listen((_) => _loadConversations());
    _socketService.onRefreshUnread.listen((_) => _loadConversations());
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId =
        prefs.getString('userId') ??
        prefs.getString('teacherId') ??
        prefs.getString('studentId') ??
        prefs.getString('orgId') ??
        '';

    if (_currentUserId.isEmpty) return;

    final response = await ApiService.get(
      '/chat/conversations/$_currentUserId',
    );
    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          _conversations = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getParticipantName(Map<String, dynamic> conversation) {
    if (conversation['isGroup'] == true)
      return conversation['groupName'] ?? 'Group Chat';
    final participants = conversation['participants'] as List;
    final other = participants.firstWhere((p) {
      final id = p is Map ? (p['userId'] ?? p['_id']) : p;
      return id != _currentUserId;
    }, orElse: () => participants[0]);

    if (other is Map) return other['userName'] ?? other['name'] ?? 'User';
    return 'User';
  }

  String _getParticipantId(Map<String, dynamic> conversation) {
    if (conversation['isGroup'] == true) return conversation['_id'];
    final participants = conversation['participants'] as List;
    final other = participants.firstWhere((p) {
      final id = p is Map ? (p['userId'] ?? p['_id']) : p;
      return id != _currentUserId;
    }, orElse: () => participants[0]);

    return other is Map ? (other['userId'] ?? other['_id']) : other;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TeacherSettingsPage()),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.teal.withOpacity(0.2)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.teal,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _conversations.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadConversations,
              color: Colors.teal,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: _conversations.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey[200], indent: 80),
                itemBuilder: (context, index) {
                  final conv = _conversations[index];
                  final lastMsg =
                      conv['lastMessage']; // This is a String in your backend
                  final participantName = _getParticipantName(conv);
                  final participantId = _getParticipantId(conv);

                  // Backend uses 'unreadCounts' (plural)
                  final unreadCounts = conv['unreadCounts'] ?? {};
                  final unreadCount = unreadCounts[_currentUserId] ?? 0;

                  final lastTime = conv['lastMessageAt'] != null
                      ? DateTime.parse(conv['lastMessageAt']).toLocal()
                      : DateTime.now();

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: conv['_id'],
                            participantName: participantName,
                            participantId: participantId,
                            isGroup: conv['isGroup'] ?? false,
                          ),
                        ),
                      ).then((_) => _loadConversations());
                    },
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.teal.withOpacity(0.1),
                      child: Text(
                        participantName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            participantName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(lastTime),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMsg ?? 'No messages yet',
                              style: TextStyle(
                                color: unreadCount > 0
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.teal,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'new_chat_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewChatScreen()),
          ).then((_) => _loadConversations()); // Refresh list on return
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.chat_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.day == time.day &&
        now.month == time.month &&
        now.year == time.year) {
      return DateFormat.jm().format(time);
    }
    return DateFormat.yMd().format(time);
  }
}
