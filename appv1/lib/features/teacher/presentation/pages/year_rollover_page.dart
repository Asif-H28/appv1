import 'dart:convert';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class YearRolloverPage extends StatefulWidget {
  final String classId;
  final String className;
  final String orgId;
  final String teacherId;

  const YearRolloverPage({
    super.key,
    required this.classId,
    required this.className,
    required this.orgId,
    required this.teacherId,
  });

  @override
  State<YearRolloverPage> createState() => _YearRolloverPageState();
}

class _YearRolloverPageState extends State<YearRolloverPage> {
  final Color _accent = Colors.teal;
  final Color _bg = const Color(0xFFF8FAFC);
  final Color _border = const Color(0xFFE2E8F0);

  int _currentStep = 1; // 1: Year Details, 2: Students, 3: Confirm
  bool _isLoadingStudents = true;
  List<Map<String, dynamic>> _students = [];
  Set<String> _promotedIds = {};
  Set<String> _retainedIds = {};

  final _academicYearController = TextEditingController(text: '2026-2027');
  final _startDateController = TextEditingController(text: '01 Jun 2026');
  final _newClassNameController = TextEditingController();

  DateTime _selectedDate = DateTime(2026, 6, 1);

  @override
  void initState() {
    super.initState();
    _newClassNameController.text = _incrementClassName(widget.className);
    _fetchStudents();
  }

  String _incrementClassName(String name) {
    // Basic logic to increment "Class 2A" to "Class 3A"
    final regExp = RegExp(r'(\d+)');
    final match = regExp.firstMatch(name);
    if (match != null) {
      final num = int.parse(match.group(1)!);
      return name.replaceFirst(match.group(1)!, (num + 1).toString());
    }
    return 'e.g. Class 3A';
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/student/class/${widget.classId}/names',
        ),
        headers: await ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> raw = body['students'] ?? [];

        setState(() {
          _students = raw.map((e) => e as Map<String, dynamic>).toList();
          _promotedIds = _students
              .map((e) => e['studentId']?.toString() ?? '')
              .toSet();
          _isLoadingStudents = false;
        });
      } else {
        setState(() => _isLoadingStudents = false);
      }
    } catch (_) {
      setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _performRollover() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.teal)),
    );

    try {
      final url = '${ApiConstants.apiBaseUrl}/org/${widget.orgId}/rollup-year';
      final body = {
        "newAcademicYear": _academicYearController.text,
        "newAcademicYearStartDate": _selectedDate.toIso8601String().split(
          'T',
        )[0],
        "classMappings": [
          {
            "oldClassId": widget.classId,
            "promotedToNewClassName": _newClassNameController.text,
            "teacherId": widget.teacherId,
            "studentsToPromote": _promotedIds.toList(),
            "studentsToRetain": _retainedIds.toList(),
          },
        ],
      };

      final response = await http.post(
        Uri.parse(url),
        headers: await ApiService.getHeaders(),
        body: jsonEncode(body),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.teal,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Rollover Successful!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '${_newClassNameController.text} for ${_academicYearController.text} has been created with ${_promotedIds.length} students successfully promoted.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context); // Dialog
                    Navigator.pop(context, true); // Page
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  child: const Text(
                    'Go Back to Class',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStep1(),
            const SizedBox(height: 16),
            _buildStep2(),
            const SizedBox(height: 16),
            _buildStep3(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    final isOpen = _currentStep == 1;
    final isDone = _currentStep > 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _currentStep = 1),
            title: Text(
              'New Academic Year',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDone ? Colors.teal : const Color(0xFF1E293B),
              ),
            ),
            subtitle: isDone
                ? Text(
                    '${_academicYearController.text} Â· ${_newClassNameController.text} Â· ${_startDateController.text}',
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
            trailing: isDone
                ? const Icon(Icons.check_circle_outline, color: Colors.teal)
                : Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Academic Year'),
                  _buildTextField(_academicYearController, 'e.g. 2025-2026'),
                  const SizedBox(height: 16),
                  _buildLabel('Start Date'),
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildLabel('New Class Name'),
                  _buildTextField(_newClassNameController, 'e.g. Class 3A'),
                  const SizedBox(height: 8),
                  Text(
                    'Name of the class students will be promoted to',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _currentStep = 2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final isOpen = _currentStep == 2;
    final isLocked = _currentStep < 2;
    final isDone = _currentStep > 2;

    return Container(
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFF1F5F9) : Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: isLocked ? null : () => setState(() => _currentStep = 2),
            leading: isLocked ? const Icon(Icons.lock_outline, size: 20) : null,
            title: Text(
              'Select Student Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.grey : const Color(0xFF1E293B),
              ),
            ),
            trailing: isLocked
                ? null
                : Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Students (${_students.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006064),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _promotedIds = _students
                                .map((e) => e['studentId']?.toString() ?? '')
                                .toSet();
                            _retainedIds = {};
                          });
                        },
                        child: const Text(
                          'All Promote',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text(' | ', style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _retainedIds = _students
                                .map((e) => e['studentId']?.toString() ?? '')
                                .toSet();
                            _promotedIds = {};
                          });
                        },
                        child: const Text(
                          'All Retain',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (_isLoadingStudents)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _students.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final id = student['studentId']?.toString() ?? '';
                        final name = student['name'] ?? 'Unknown';
                        final roll = student['rollNumber'] ?? 'N/A';
                        final isPromoted = _promotedIds.contains(id);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[200],
                                child: Text(
                                  name[0],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Roll No: $roll',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildToggleButton(id, isPromoted),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_promotedIds.length} Promote',
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.circle, size: 4, color: Colors.grey),
                        const SizedBox(width: 16),
                        Text(
                          '${_retainedIds.length} Retain',
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _currentStep = 3),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final isOpen = _currentStep == 3;
    final isLocked = _currentStep < 3;

    return Container(
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFF1F5F9) : Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: isLocked ? null : () => setState(() => _currentStep = 3),
            leading: isLocked ? const Icon(Icons.lock_outline, size: 20) : null,
            title: Text(
              'Confirm Rollover',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.grey : const Color(0xFF1E293B),
              ),
            ),
            trailing: isLocked
                ? null
                : Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Current Class:',
                    '${widget.className} (2024-25)',
                  ),
                  _buildInfoRow(
                    'New Class:',
                    '${_newClassNameController.text} (${_academicYearController.text})',
                  ),
                  _buildInfoRow('Start Date:', _startDateController.text),
                  const Divider(height: 32),
                  _buildInfoRow(
                    'Promoting:',
                    '${_promotedIds.length} students',
                    isValueBold: true,
                  ),
                  _buildInfoRow(
                    'Retaining:',
                    '${_retainedIds.length} students',
                    isValueBold: true,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This action cannot be undone. Retained students will stay in ${widget.className} for the next term.',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _performRollover,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Year Rollover',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: _border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        // Ensure initialDate is at or after firstDate
        final initial = _selectedDate.isBefore(now) ? now : _selectedDate;

        final date = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(
            2020,
          ), // Allow selection of past dates if needed, or stick to now
          lastDate: now.add(const Duration(days: 730)),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
            final months = [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec',
            ];
            _startDateController.text =
                '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
          });
        }
      },
      child: AbsorbPointer(
        child: TextField(
          controller: _startDateController,
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: BorderSide(color: _border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String id, bool isPromoted) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _promotedIds.add(id);
              _retainedIds.remove(id);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isPromoted ? const Color(0xFF006064) : Colors.white,
              border: Border.all(
                color: isPromoted ? const Color(0xFF006064) : _border,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
              ),
            ),
            child: Text(
              'PROMOTE',
              style: TextStyle(
                color: isPromoted ? Colors.white : const Color(0xFF006064),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _retainedIds.add(id);
              _promotedIds.remove(id);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: !isPromoted ? const Color(0xFF006064) : Colors.white,
              border: Border.all(
                color: !isPromoted ? const Color(0xFF006064) : _border,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
            ),
            child: Text(
              'RETAIN',
              style: TextStyle(
                color: !isPromoted ? Colors.white : const Color(0xFF006064),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isValueBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF006064),
              fontSize: 13,
              fontWeight: isValueBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
