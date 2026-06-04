import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appv1/features/tuition_session/services/tuition_session_service.dart';
import 'package:appv1/features/tuition_session/models/tuition_session_models.dart';
import 'package:appv1/features/tuition_session/widgets/session_status_badge.dart';
import 'package:appv1/features/tuition_session/widgets/forced_checkin_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'teacher_qr_scanner_screen.dart';
import 'teacher_active_session_screen.dart';
import 'package:appv1/features/tuition_session/admin/admin_session_detail_screen.dart';

class TeacherTodaySessionsScreen extends StatefulWidget {
  const TeacherTodaySessionsScreen({Key? key}) : super(key: key);

  @override
  State<TeacherTodaySessionsScreen> createState() => _TeacherTodaySessionsScreenState();
}

class _TeacherTodaySessionsScreenState extends State<TeacherTodaySessionsScreen> {
  bool _isLoading = true;
  List<SessionSummaryDTO> _sessions = [];
  String _orgId = '';
  String _teacherId = '';

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

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final res = await TuitionSessionService.fetchOrgSessions(_orgId, date: today);
    if (res['success']) {
      final allSessions = List<SessionSummaryDTO>.from(res['sessions']);
      _teacherId = prefs.getString('teacherId') ?? '';
      setState(() {
        _sessions = allSessions.where((s) => s.teacherId == _teacherId).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<Position?> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        }
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      }
      return null;
    } 

    return await Geolocator.getCurrentPosition();
  }

  void _handleForceCheckin([SessionSummaryDTO? session]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ForcedCheckinSheet(
        teacherId: _teacherId,
        orgId: _orgId,
        initialAssignmentId: session?.assignmentId,
        initialStudentId: session?.studentId,
        initialStudentName: session?.studentName,
        onSubmit: ({required assignmentId, required studentId, required studentName, required reason}) async {
          final pos = await _getLocation();
          if (pos == null) {
            Navigator.pop(context);
            return;
          }
          final res = await TuitionSessionService.forceCheckIn(
            assignmentId: assignmentId,
            studentId: studentId,
            studentName: studentName,
            orgId: _orgId,
            reason: reason,
            teacherLat: pos.latitude,
            teacherLng: pos.longitude,
          );
          if (res['success']) {
            Navigator.pop(context);
            _navigateToActiveSession(res['session']);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
          }
        },
      ),
    );
  }

  void _navigateToActiveSession(SessionDetailDTO session) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TeacherActiveSessionScreen(session: session)),
    );
    _loadSessions();
  }

  void _navigateToScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeacherQrScannerScreen()),
    );
    if (result == true) {
      _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Today\'s Sessions', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF009688),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: 'Manual Force Check-in',
            onPressed: () => _handleForceCheckin(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToScanner,
        backgroundColor: const Color(0xFF009688),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('Scan QR', style: TextStyle(color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
          : _sessions.isEmpty
              ? const Center(child: Text('No sessions for today', style: TextStyle(fontSize: 16, color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  color: const Color(0xFF009688),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                        elevation: 1,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminSessionDetailScreen(sessionId: session.id),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        session.studentName,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SessionStatusBadge(status: session.status, forcedCheckIn: session.forcedCheckIn),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Student ID: ${session.studentId}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                const SizedBox(height: 16),
                                if (session.status == 'pending') ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _handleForceCheckin(session),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: const BorderSide(color: Colors.redAccent),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                          ),
                                          child: const Text('Force Check-in'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _navigateToScanner,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF009688),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                          ),
                                          child: const Text('Scan QR', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (session.status == 'ongoing') ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final res = await TuitionSessionService.fetchSessionDetail(session.id);
                                        if (res['success']) {
                                          _navigateToActiveSession(res['session']);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orangeAccent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                      ),
                                      child: const Text('Resume Session', style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
