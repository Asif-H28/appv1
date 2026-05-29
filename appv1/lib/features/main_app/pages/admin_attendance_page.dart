import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class AdminAttendancePage extends StatefulWidget {
  const AdminAttendancePage({Key? key}) : super(key: key);

  @override
  _AdminAttendancePageState createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends State<AdminAttendancePage> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isExporting = false;
  String _orgId = '';
  List<dynamic> _presentTeachers = [];

  @override
  void initState() {
    super.initState();
    _loadOrgIdAndFetchData();
  }

  Future<void> _loadOrgIdAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orgId = prefs.getString('orgId') ?? '';
    });
    _fetchPresentTeachers();
  }

  Future<void> _fetchPresentTeachers() async {
    if (_orgId.isEmpty) return;

    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      final response = await ApiService.get(
        '/teacher-attendance/org/$_orgId/present?date=$dateStr',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Check if data is a list directly or an object containing a list
          if (data is List) {
            _presentTeachers = data;
          } else if (data['attendances'] != null) {
            _presentTeachers = data['attendances'];
          } else if (data['presentTeachers'] != null) {
            _presentTeachers = data['presentTeachers'];
          } else if (data['data'] != null) {
            _presentTeachers = data['data'];
          } else {
            _presentTeachers = [];
          }
        });
      } else {
        _showSnackBar('Failed to load attendance', isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData({bool byMonth = false}) async {
    if (_orgId.isEmpty) return;

    setState(() => _isExporting = true);

    String urlPath;
    String fileName;
    if (byMonth) {
      urlPath = '/teacher-attendance/org/$_orgId/export?month=${_selectedDate.month}&year=${_selectedDate.year}';
      fileName = 'attendance_${_selectedDate.year}_${_selectedDate.month}.csv';
    } else {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      urlPath = '/teacher-attendance/org/$_orgId/export?date=$dateStr';
      fileName = 'attendance_$dateStr.csv';
    }

    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}$urlPath'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Save the file
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Open the file
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          _showSnackBar('File downloaded to: ${file.path}\nCould not open automatically.', isError: false);
        }
      } else {
        final responseBody = jsonDecode(response.body);
        _showSnackBar(responseBody['message'] ?? 'Failed to export data', isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchPresentTeachers();
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
    final dateDisplay = DateFormat('MMMM d, yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Attendance'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (_isExporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              tooltip: 'Export Data',
              onSelected: (value) {
                if (value == 'date') {
                  _exportData(byMonth: false);
                } else if (value == 'month') {
                  _exportData(byMonth: true);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'date',
                    child: Text('Export for $dateDisplay'),
                  ),
                  PopupMenuItem<String>(
                    value: 'month',
                    child: Text('Export for ${DateFormat('MMMM yyyy').format(_selectedDate)}'),
                  ),
                ];
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateDisplay,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Change Date'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Present Teachers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : _presentTeachers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No teachers checked in on this date.',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _presentTeachers.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final teacher = _presentTeachers[index];
                          // Format check-in and check-out times
                          String checkInTime = '--:--';
                          String checkOutTime = '--:--';
                          
                          if (teacher['checkIn'] != null) {
                            try {
                              checkInTime = DateFormat('hh:mm a').format(DateTime.parse(teacher['checkIn']).toLocal());
                            } catch (_) {}
                          }
                          
                          if (teacher['checkOut'] != null) {
                            try {
                              checkOutTime = DateFormat('hh:mm a').format(DateTime.parse(teacher['checkOut']).toLocal());
                            } catch (_) {}
                          }
                          
                          // Handle teacher info which might be populated or nested
                          String teacherName = 'Unknown Teacher';
                          String teacherEmail = '';
                          
                          if (teacher['teacherId'] is Map) {
                            teacherName = teacher['teacherId']['name'] ?? teacherName;
                            teacherEmail = teacher['teacherId']['email'] ?? teacherEmail;
                          } else {
                            teacherName = teacher['teacherName'] ?? teacherName;
                            teacherEmail = teacher['email'] ?? teacherEmail;
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.withOpacity(0.1),
                              child: Text(
                                teacherName.isNotEmpty ? teacherName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              teacherName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: teacherEmail.isNotEmpty
                                ? Text(teacherEmail, style: TextStyle(color: Colors.grey[600], fontSize: 12))
                                : null,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'In: $checkInTime',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Out: $checkOutTime',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: checkOutTime == '--:--' ? Colors.grey : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
