import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/pending_document_upload_service.dart';
import '../widgets/teacher_drawer.dart';
import 'start_tutor_session_page.dart';
import '../widgets/end_tutor_session_sheet.dart';
import '../widgets/tutor_session_details_sheet.dart';

class TutorSessionHistoryPage extends StatefulWidget {
  const TutorSessionHistoryPage({Key? key}) : super(key: key);

  @override
  _TutorSessionHistoryPageState createState() => _TutorSessionHistoryPageState();
}

class _TutorSessionHistoryPageState extends State<TutorSessionHistoryPage> {
  bool _isLoading = true;
  String _orgId = '';
  List<dynamic> _sessions = [];
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadOrgIdAndFetch();
  }

  Future<void> _loadOrgIdAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orgId = prefs.getString('orgId') ?? '';
    });
    await _fetchSessions();

    final pending = await PendingDocumentUploadService.getPendingData();
    if (pending != null && mounted) {
      final extra = pending['extra'] as Map<String, dynamic>?;
      final sessionId = extra?['sessionId'] ?? '';
      if (sessionId.toString().isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showEndSessionSheet(sessionId.toString());
        });
      }
    }
  }

  Future<void> _fetchSessions() async {
    if (_orgId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await ApiService.get(
        '/tutor-sessions?date=$dateStr',
        headers: {'x-org-id': _orgId},
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        var parsedSessions = [];
        if (body is List) {
          parsedSessions = body;
        } else if (body is Map) {
          if (body['sessions'] is List) {
            parsedSessions = body['sessions'];
          } else if (body['data'] is List) {
            parsedSessions = body['data'];
          } else if (body.containsKey('sessionStartedTime') || body.containsKey('_id')) {
             parsedSessions = [body];
          } else {
             parsedSessions = [];
          }
        }
        setState(() {
          _sessions = parsedSessions;
        });
      } else {
        _showSnackBar('Failed to load sessions', isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showEndSessionSheet(String sessionId) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EndTutorSessionSheet(sessionId: sessionId, orgId: _orgId),
    );
    if (result == true) {
      _fetchSessions();
    }
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TutorSessionDetailsSheet(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tutor Session'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const TeacherDrawer(currentRoute: TeacherDrawerRoute.tutorSession),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _sessions.isEmpty
              ? _buildEmptyState()
              : _buildSessionList(),
      floatingActionButton: _sessions.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StartTutorSessionPage()),
                );
                if (result == true) _fetchSessions();
              },
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 90,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Sessions Today',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have not started any tutor sessions for today. Click below to start a new session.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StartTutorSessionPage()),
                );
                if (result == true) {
                  _fetchSessions();
                }
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList() {
    return RefreshIndicator(
      onRefresh: _fetchSessions,
      color: Colors.teal,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final bool isCompleted = session['sessionEndedTime'] != null;
          final List<String> studentIds = (session['studentIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.08),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.teal : Colors.white,
                          border: Border.all(color: Colors.teal),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle_outline : Icons.pending_actions,
                              color: isCompleted ? Colors.white : Colors.teal,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCompleted ? 'Completed' : 'Active',
                              style: TextStyle(
                                color: isCompleted ? Colors.white : Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.withOpacity(0.5)),
                        ),
                        child: Text(
                          DateFormat('hh:mm a').format(DateTime.parse(session['sessionStartedTime'] ?? DateTime.now().toIso8601String()).toLocal()),
                          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.schedule_rounded, color: Colors.teal, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Duration', style: TextStyle(color: Colors.teal.shade700, fontSize: 12)),
                                  Text(
                                    '${session['duration'] ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.group_rounded, color: Colors.teal, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Students', style: TextStyle(color: Colors.teal.shade700, fontSize: 12)),
                                  Text(
                                    studentIds.isEmpty ? 'None' : studentIds.join(', '),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isCompleted)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showSessionDetails(session),
                        icon: const Icon(Icons.visibility_outlined, color: Colors.teal),
                        label: const Text('View Details', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.teal),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showSessionDetails(session),
                            icon: const Icon(Icons.visibility_outlined, color: Colors.teal),
                            label: const Text('View Details', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.teal),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showEndSessionSheet(session['_id']),
                            icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
                            label: const Text('End Session', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
