import 'package:flutter/material.dart';
import 'package:appv1/features/tuition_session/models/tuition_session_models.dart';
import 'package:appv1/features/tuition_session/widgets/session_status_badge.dart';
import 'package:intl/intl.dart';

class TeacherSessionSummaryScreen extends StatelessWidget {
  final SessionDetailDTO session;

  const TeacherSessionSummaryScreen({Key? key, required this.session}) : super(key: key);

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat('hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Session Summary', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF009688),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // Prevent returning to active session
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF009688), size: 64),
                    const SizedBox(height: 16),
                    const Text('Session Completed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
                    const SizedBox(height: 16),
                    SessionStatusBadge(status: session.status, forcedCheckIn: session.forcedCheckIn),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Duration', style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text('${session.durationMinutes} min', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Start Time', style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text(_formatTime(session.checkInTime), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('End Time', style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text(_formatTime(session.checkOutTime), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              child: ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF009688)),
                title: Text(session.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: ${session.studentId}'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Activity Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (session.activity != null && session.activity!['description'] != null && session.activity!['description'].toString().isNotEmpty) ...[
                      const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(session.activity!['description']),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Icon(session.activity?['homeworkProvided'] == 'true' ? Icons.check_box : Icons.check_box_outline_blank, color: const Color(0xFF009688)),
                        const SizedBox(width: 8),
                        const Text('Homework Provided'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(session.activity?['studentCompletedHomework'] == 'true' ? Icons.check_box : Icons.check_box_outline_blank, color: const Color(0xFF009688)),
                        const SizedBox(width: 8),
                        const Text('Student Completed Homework'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(session.activity?['testGiven'] == 'true' ? Icons.check_box : Icons.check_box_outline_blank, color: const Color(0xFF009688)),
                        const SizedBox(width: 8),
                        const Text('Test Given'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to Today's Sessions
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              ),
              child: const Text('Back to Dashboard', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
