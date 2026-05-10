import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({Key? key}) : super(key: key);

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  List<dynamic> _teachers = [];
  List<dynamic> _students = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _currentUserId = '';
  String _orgId = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId =
        prefs.getString('userId') ??
        prefs.getString('teacherId') ??
        prefs.getString('studentId') ??
        prefs.getString('orgId') ??
        '';
    _orgId = prefs.getString('orgId') ?? '';

    final teacherRes = await ApiService.fetchTeachers(_orgId);
    final studentRes = await ApiService.fetchStudents(_orgId);

    if (mounted) {
      setState(() {
        _teachers = teacherRes['success'] ? teacherRes['teachers'] : [];
        _students =
            []; // Removed students as chat is only for teachers and admin
        _isLoading = false;
        _filterContacts('');
      });
    }
  }

  void _filterContacts(String query) {
    _searchQuery = query;
    final all = [..._teachers, ..._students];
    setState(() {
      _filteredItems = all.where((u) {
        final name = (u['name'] ?? u['teacherName'] ?? u['studentName'] ?? '')
            .toString()
            .toLowerCase();
        // Don't show current user in the list
        final id =
            (u['userId'] ?? u['teacherId'] ?? u['studentId'] ?? u['_id'] ?? '')
                .toString();
        return name.contains(query.toLowerCase()) && id != _currentUserId;
      }).toList();
    });
  }

  Future<void> _startConversation(dynamic user) async {
    final participantId =
        (user['userId'] ??
                user['teacherId'] ??
                user['studentId'] ??
                user['_id'] ??
                '')
            .toString();
    final name =
        (user['name'] ??
                user['teacherName'] ??
                user['studentName'] ??
                'Unknown')
            .toString();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.teal)),
    );

    final result = await ApiService.createConversation(
      _currentUserId,
      participantId,
    );

    if (mounted) Navigator.pop(context); // Close loading

    if (result['success']) {
      final conv = result['conversation'];
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conv['_id'],
              participantName: name,
              participantId: participantId,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error starting chat')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'New Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: _filterContacts,
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                : _filteredItems.isEmpty
                ? const Center(child: Text('No contacts found'))
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final user = _filteredItems[index];
                      final name =
                          (user['name'] ??
                                  user['teacherName'] ??
                                  user['studentName'] ??
                                  'Unknown')
                              .toString();
                      final email =
                          (user['email'] ??
                                  user['teacherEmail'] ??
                                  user['studentEmail'] ??
                                  '')
                              .toString();
                      final role = user.containsKey('teacherId')
                          ? 'Teacher'
                          : 'Student';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: role == 'Teacher'
                              ? Colors.indigo
                              : Colors.orange,
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _startConversation(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
