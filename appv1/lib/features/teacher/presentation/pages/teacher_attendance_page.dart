import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import '../../../../core/services/api_service.dart';

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({Key? key}) : super(key: key);

  @override
  _TeacherAttendancePageState createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  bool _isLoading = false;
  String _orgId = '';
  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadOrgId();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrgId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orgId = prefs.getString('orgId') ?? '';
    });
  }

  Future<void> _handleCheckIn() async {
    if (_orgId.isEmpty) {
      _showSnackBar('Organization ID not found', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post(
        '/teacher-attendance/checkin',
        body: jsonEncode({'orgId': _orgId}),
      );

      final responseBody = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && !responseBody.containsKey('error')) {
        _showSnackBar(responseBody['message'] ?? 'Checked in successfully!');
      } else {
        _showSnackBar(responseBody['error'] ?? responseBody['message'] ?? 'Failed to check in', isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckOut() async {
    if (_orgId.isEmpty) {
      _showSnackBar('Organization ID not found', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post(
        '/teacher-attendance/checkout',
        body: jsonEncode({'orgId': _orgId}),
      );

      final responseBody = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && !responseBody.containsKey('error')) {
        _showSnackBar(responseBody['message'] ?? 'Checked out successfully!');
      } else {
        _showSnackBar(responseBody['error'] ?? responseBody['message'] ?? 'Failed to check out', isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormatter = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 80,
                color: Colors.teal,
              ),
              const SizedBox(height: 24),
              Text(
                dateFormatter.format(_currentTime),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                timeFormatter.format(_currentTime),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 60),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleCheckIn,
                        icon: const Icon(Icons.login),
                        label: const Text('Check In'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleCheckOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Check Out'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
