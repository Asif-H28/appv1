import 'package:flutter/material.dart';
import 'package:appv1/features/tuition_session/models/tuition_session_models.dart';
import 'package:appv1/features/tuition_session/services/tuition_session_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_teacher_sessions_screen.dart';

class AdminSessionDashboardScreen extends StatefulWidget {
  const AdminSessionDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminSessionDashboardScreen> createState() => _AdminSessionDashboardScreenState();
}

class _AdminSessionDashboardScreenState extends State<AdminSessionDashboardScreen> {
  bool _isLoading = true;
  List<SessionSummaryDTO> _allSessions = [];
  String _orgId = '';
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    if (_orgId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final res = await TuitionSessionService.fetchOrgSessions(_orgId, date: dateStr);
    
    if (res['success']) {
      setState(() {
        _allSessions = List<SessionSummaryDTO>.from(res['sessions']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF009688),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadSessions();
    }
  }

  Map<String, List<SessionSummaryDTO>> _getGroupedAndFilteredTeachers() {
    Map<String, List<SessionSummaryDTO>> teacherMap = {};
    for (var session in _allSessions) {
      final name = session.teacherName.trim();
      // Filter by search query
      if (_searchQuery.isNotEmpty && !name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        continue;
      }
      if (!teacherMap.containsKey(name)) {
        teacherMap[name] = [];
      }
      teacherMap[name]!.add(session);
    }
    return teacherMap;
  }

  @override
  Widget build(BuildContext context) {
    final groupedTeachers = _getGroupedAndFilteredTeachers();
    final teacherNames = groupedTeachers.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Session Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF009688),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Picker Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar, size: 18, color: Color(0xFF009688)),
                  label: const Text('Change Date', style: TextStyle(color: Color(0xFF009688))),
                )
              ],
            ),
          ),
          
          // Search Bar Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by teacher name...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF009688)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: Color(0xFF009688)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          const Divider(height: 1, thickness: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
                : teacherNames.isEmpty
                    ? const Center(child: Text('No teachers found.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: _loadSessions,
                        color: const Color(0xFF009688),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: teacherNames.length,
                          itemBuilder: (context, index) {
                            final tName = teacherNames[index];
                            final tSessions = groupedTeachers[tName]!;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: Colors.white,
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                              elevation: 1,
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminTeacherSessionsScreen(
                                        teacherName: tName,
                                        date: _selectedDate,
                                        sessions: tSessions,
                                      ),
                                    ),
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF009688).withOpacity(0.1),
                                  child: Text(
                                    tName.isNotEmpty ? tName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(tName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Text(
                                  '${tSessions.length} Session${tSessions.length == 1 ? '' : 's'}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
