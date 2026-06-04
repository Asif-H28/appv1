import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:appv1/features/tuition_session/services/tuition_session_service.dart';
import 'package:appv1/features/tuition_session/models/tuition_session_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentSessionGeneratorScreen extends StatefulWidget {
  final String classId;

  const StudentSessionGeneratorScreen({Key? key, required this.classId}) : super(key: key);

  @override
  State<StudentSessionGeneratorScreen> createState() => _StudentSessionGeneratorScreenState();
}

class _StudentSessionGeneratorScreenState extends State<StudentSessionGeneratorScreen> {
  bool _isLoading = true;
  List<TeacherDTO> _teachers = [];
  TeacherDTO? _selectedTeacher;
  String _orgId = '';
  String _studentId = '';
  String _studentName = '';
  
  String? _qrToken;
  bool _isGeneratingQr = false;
  
  Timer? _refreshTimer;
  int _countdown = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    _studentId = prefs.getString('studentId') ?? '';
    _studentName = prefs.getString('studentName') ?? 'Student';

    if (_orgId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final res = await TuitionSessionService.fetchTeachers(_orgId);
    if (res['success']) {
      setState(() {
        _teachers = (res['teachers'] as List<TeacherDTO>);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
  }

  void _generateQr() async {
    if (_selectedTeacher == null) return;
    
    setState(() => _isGeneratingQr = true);
    final res = await TuitionSessionService.generateQr(
      assignmentId: widget.classId,
      studentId: _studentId,
      studentName: _studentName,
      teacherId: _selectedTeacher!.teacherId,
      teacherName: _selectedTeacher!.name,
      orgId: _orgId,
    );

    if (res['success']) {
      setState(() {
        _qrToken = res['qrToken'];
        _isGeneratingQr = false;
        _countdown = 300;
      });
      _startTimer();
    } else {
      setState(() => _isGeneratingQr = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        setState(() => _qrToken = null);
      }
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_qrToken == null) ...[
                    const Text(
                      'Select a teacher to check-in with:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TeacherDTO>(
                          value: _selectedTeacher,
                          hint: const Text('Select Teacher'),
                          isExpanded: true,
                          items: _teachers.map((t) {
                            return DropdownMenuItem<TeacherDTO>(
                              value: t,
                              child: Row(
                                children: [
                                  const Icon(Icons.person, color: Color(0xFF009688)),
                                  const SizedBox(width: 8),
                                  Text(t.name),
                                  if (t.verified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, size: 16, color: Colors.blue),
                                  ]
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedTeacher = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: (_selectedTeacher == null || _isGeneratingQr) ? null : _generateQr,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                      child: _isGeneratingQr
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Generate Session QR', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ] else ...[
                    Card(
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text('Show this QR to your teacher', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            QrImageView(
                              data: _qrToken!,
                              version: QrVersions.auto,
                              size: 200.0,
                              foregroundColor: const Color(0xFF009688),
                            ),
                            const SizedBox(height: 16),
                            Text('Expires in: ${_formatTime(_countdown)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: _generateQr,
                              icon: const Icon(Icons.refresh, color: Color(0xFF009688)),
                              label: const Text('Regenerate QR', style: TextStyle(color: Color(0xFF009688))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF009688)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
