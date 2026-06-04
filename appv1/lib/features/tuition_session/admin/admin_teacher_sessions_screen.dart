import 'package:flutter/material.dart';
import 'package:appv1/features/tuition_session/models/tuition_session_models.dart';
import 'package:appv1/features/tuition_session/widgets/session_status_badge.dart';
import 'package:intl/intl.dart';
import 'admin_session_detail_screen.dart';

class AdminTeacherSessionsScreen extends StatelessWidget {
  final String teacherName;
  final DateTime date;
  final List<SessionSummaryDTO> sessions;

  const AdminTeacherSessionsScreen({
    Key? key,
    required this.teacherName,
    required this.date,
    required this.sessions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$teacherName\'s Sessions', style: const TextStyle(color: Colors.white, fontSize: 18)),
            Text(DateFormat('MMMM d, yyyy').format(date), style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF009688),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: sessions.isEmpty
          ? const Center(child: Text('No sessions for this teacher.', style: TextStyle(color: Colors.grey, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
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
                        MaterialPageRoute(builder: (_) => AdminSessionDetailScreen(sessionId: session.id)),
                      );
                    },
                    // Highlight the teacher's name prominently as requested
                    title: Text(session.teacherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF009688))),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text('Student: ${session.studentName}', style: const TextStyle(color: Colors.black87))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.assignment, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text('Assignment: ${session.assignmentId}', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                          ],
                        ),
                      ],
                    ),
                    trailing: SessionStatusBadge(status: session.status, forcedCheckIn: session.forcedCheckIn),
                    isThreeLine: true,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                );
              },
            ),
    );
  }
}
