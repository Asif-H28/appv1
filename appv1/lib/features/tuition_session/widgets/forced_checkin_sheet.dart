import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;

class ForcedCheckinSheet extends StatefulWidget {
  final String teacherId;
  final String orgId;
  final String? initialAssignmentId;
  final String? initialStudentId;
  final String? initialStudentName;
  final Function({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String reason,
  }) onSubmit;

  const ForcedCheckinSheet({
    Key? key,
    required this.teacherId,
    required this.orgId,
    this.initialAssignmentId,
    this.initialStudentId,
    this.initialStudentName,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<ForcedCheckinSheet> createState() => _ForcedCheckinSheetState();
}

class _ForcedCheckinSheetState extends State<ForcedCheckinSheet> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _isFetchingClasses = true;
  bool _isFetchingStudents = false;
  
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];

  String? _selectedClassId;
  String? _selectedStudentId;
  String? _selectedStudentName;

  @override
  void initState() {
    super.initState();
    if (widget.initialAssignmentId != null) {
      _selectedClassId = widget.initialAssignmentId;
      _selectedStudentId = widget.initialStudentId;
      _selectedStudentName = widget.initialStudentName;
      _isFetchingClasses = false;
    } else {
      _fetchClasses();
    }
  }

  Future<void> _fetchClasses() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/classroom/org/${widget.orgId}'),
        headers: await ApiService.getHeaders(),
      );
      if (mounted) {
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          List raw = [];
          if (body is List) raw = body;
          else if (body['classrooms'] != null) raw = body['classrooms'];
          else if (body['data'] != null) raw = body['data'];
          
          setState(() {
            _classes = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _isFetchingClasses = false;
          });
        } else {
          setState(() => _isFetchingClasses = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isFetchingClasses = false);
    }
  }

  Future<void> _fetchStudents(String classId) async {
    setState(() {
      _isFetchingStudents = true;
      _students = [];
      _selectedStudentId = null;
      _selectedStudentName = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/student/class/$classId/names'),
        headers: await ApiService.getHeaders(),
      );
      if (mounted) {
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final List<dynamic> raw = body['students'] ?? [];
          setState(() {
            _students = raw.map((e) => e as Map<String, dynamic>).toList();
            _isFetchingStudents = false;
          });
        } else {
          setState(() => _isFetchingStudents = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isFetchingStudents = false);
    }
  }

  void _submit() async {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a class')));
      return;
    }
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a student')));
      return;
    }
    
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    await widget.onSubmit(
      assignmentId: _selectedClassId!,
      studentId: _selectedStudentId!,
      studentName: _selectedStudentName ?? 'Unknown',
      reason: reason,
    );
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPreFilled = widget.initialAssignmentId != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 80,
        left: 16,
        right: 16,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Forced Check-in',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Please provide a reason for bypassing the QR code scan. This will be logged.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            
            if (!isPreFilled) ...[
              if (_isFetchingClasses)
                const Center(child: CircularProgressIndicator(color: Colors.teal))
              else
                DropdownMenu<String>(
                  width: MediaQuery.of(context).size.width - 32,
                  hintText: 'Search and Select Class',
                  enableFilter: true,
                  enableSearch: true,
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(3),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                  ),
                  dropdownMenuEntries: _classes.map((c) {
                    return DropdownMenuEntry<String>(
                      value: c['classId'],
                      label: c['className'] ?? 'Unknown Class',
                    );
                  }).toList(),
                  onSelected: (val) {
                    setState(() => _selectedClassId = val);
                    if (val != null) _fetchStudents(val);
                  },
                ),
              const SizedBox(height: 16),
              
              if (_selectedClassId != null) ...[
                if (_isFetchingStudents)
                  const Center(child: CircularProgressIndicator(color: Colors.teal))
                else
                  DropdownMenu<String>(
                    width: MediaQuery.of(context).size.width - 32,
                    hintText: 'Search and Select Student',
                    enableFilter: true,
                    enableSearch: true,
                    inputDecorationTheme: InputDecorationTheme(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                    ),
                    dropdownMenuEntries: _students.map((s) {
                      return DropdownMenuEntry<String>(
                        value: s['studentId'],
                        label: s['name'] ?? 'Unknown',
                      );
                    }).toList(),
                    onSelected: (val) {
                      setState(() {
                        _selectedStudentId = val;
                        if (val != null) {
                          final st = _students.firstWhere((element) => element['studentId'] == val);
                          _selectedStudentName = st['name'];
                        }
                      });
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Class ID: ${widget.initialAssignmentId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Student: ${widget.initialStudentName}', style: const TextStyle(color: Colors.teal)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Student forgot device, QR scanning failed...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: Colors.teal),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm Check-in', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
