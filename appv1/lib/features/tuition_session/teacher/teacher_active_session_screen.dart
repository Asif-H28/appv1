import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:appv1/features/tuition_session/models/tuition_session_models.dart';
import 'package:appv1/features/tuition_session/services/tuition_session_service.dart';
import 'package:appv1/features/tuition_session/widgets/session_status_badge.dart';
import 'teacher_update_activity_screen.dart';
import 'teacher_session_summary_screen.dart';

class TeacherActiveSessionScreen extends StatefulWidget {
  final SessionDetailDTO session;

  const TeacherActiveSessionScreen({Key? key, required this.session}) : super(key: key);

  @override
  State<TeacherActiveSessionScreen> createState() => _TeacherActiveSessionScreenState();
}

class _TeacherActiveSessionScreenState extends State<TeacherActiveSessionScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();
    if (widget.session.checkInTime != null) {
      _elapsed = DateTime.now().difference(widget.session.checkInTime!);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.session.checkInTime ?? DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Future<Position?> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return null;
    } 

    return await Geolocator.getCurrentPosition();
  }

  void _endSession() async {
    setState(() => _isEnding = true);
    final pos = await _getLocation();
    if (pos == null) {
      setState(() => _isEnding = false);
      return;
    }

    final res = await TuitionSessionService.checkoutSession(
      sessionId: widget.session.id,
      teacherLat: pos.latitude,
      teacherLng: pos.longitude,
    );

    if (res['success']) {
      _timer?.cancel();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TeacherSessionSummaryScreen(session: res['session'])),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
        setState(() => _isEnding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Active Session', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF009688),
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent accidental back
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
                    const Text('Session Duration', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_elapsed),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF009688)),
                    ),
                    const SizedBox(height: 16),
                    SessionStatusBadge(status: 'ongoing', forcedCheckIn: widget.session.forcedCheckIn),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Student Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              elevation: 1,
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.person, color: Color(0xFF009688))),
                title: Text(widget.session.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: ${widget.session.studentId}'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TeacherUpdateActivityScreen(sessionId: widget.session.id)),
                );
              },
              icon: const Icon(Icons.edit_document, color: Colors.white),
              label: const Text('Update Session Activity', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isEnding ? null : _endSession,
              icon: _isEnding
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.stop_circle, color: Colors.white),
              label: Text(_isEnding ? 'Ending Session...' : 'End Session', style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
