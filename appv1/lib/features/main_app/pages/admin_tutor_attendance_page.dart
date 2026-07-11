import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import 'admin_tutor_session_activity_page.dart';

class AdminTutorAttendancePage extends StatefulWidget {
  const AdminTutorAttendancePage({Key? key}) : super(key: key);

  @override
  State<AdminTutorAttendancePage> createState() => _AdminTutorAttendancePageState();
}

class _AdminTutorAttendancePageState extends State<AdminTutorAttendancePage> {
  DateTime _dailyDate = DateTime.now();
  DateTime _reportStartDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _reportEndDate = DateTime.now();

  List<dynamic> _dailyData = [];
  List<dynamic> _reportData = [];
  
  bool _isLoadingDaily = false;
  bool _isLoadingReport = false;
  bool _isExporting = false;

  String _orgId = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _orgId = prefs.getString('orgId') ?? '');
    _fetchDailyData();
    _fetchReportData();
  }

  Future<void> _fetchDailyData() async {
    setState(() => _isLoadingDaily = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_dailyDate);
      final response = await ApiService.get(
        '/tutor-attendance/present?date=$dateStr',
        headers: {'x-org-id': _orgId},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() => _dailyData = body['data'] ?? []);
      } else {
        _showSnackBar('Failed to load daily attendance', true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', true);
    } finally {
      if (mounted) setState(() => _isLoadingDaily = false);
    }
  }

  Future<void> _fetchReportData() async {
    setState(() => _isLoadingReport = true);
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_reportStartDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_reportEndDate);
      final response = await ApiService.get(
        '/tutor-attendance/report?startDate=$startStr&endDate=$endStr',
        headers: {'x-org-id': _orgId},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() => _reportData = body['data'] ?? []);
      } else {
        _showSnackBar('Failed to load report', true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', true);
    } finally {
      if (mounted) setState(() => _isLoadingReport = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_reportStartDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_reportEndDate);
      final url = '${ApiConstants.apiBaseUrl}/tutor-attendance/export?startDate=$startStr&endDate=$endStr';

      final headers = await ApiService.getHeaders();
      headers['x-org-id'] = _orgId;

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/tutor_attendance_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final dio = Dio();
      await dio.download(
        url,
        filePath,
        options: Options(headers: headers),
      );

      _showSnackBar('Report downloaded successfully');
      OpenFile.open(filePath);
    } catch (e) {
      _showSnackBar('Failed to export report: $e', true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSnackBar(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Tutor Attendance'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Daily View'),
              Tab(text: 'Report View'),
            ],
          ),
        ),
        body: Builder(
          builder: (context) {
            final isReportView = DefaultTabController.of(context).index == 1;
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: TabBarView(
                children: [
                  _buildDailyView(),
                  _buildReportView(),
                ],
              ),
              floatingActionButton: _reportData.isNotEmpty 
                  ? FloatingActionButton.extended(
                      onPressed: _isExporting ? null : _exportExcel,
                      backgroundColor: Colors.teal,
                      icon: _isExporting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.download, color: Colors.white),
                      label: Text(_isExporting ? 'Exporting...' : 'Export Excel', style: const TextStyle(color: Colors.white)),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDailyView() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${DateFormat('MMM dd, yyyy').format(_dailyDate)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _dailyDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selected != null) {
                    setState(() => _dailyDate = selected);
                    _fetchDailyData();
                  }
                },
                icon: const Icon(Icons.calendar_month, color: Colors.teal),
                label: const Text('Change Date', style: TextStyle(color: Colors.teal)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.teal)),
              )
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: _isLoadingDaily
              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
              : _dailyData.isEmpty
                  ? _buildEmptyState('No tutors marked present on this date.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _dailyData.length,
                      itemBuilder: (context, index) {
                        final tutor = _dailyData[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.shade100),
                            boxShadow: [
                              BoxShadow(color: Colors.teal.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal.shade100,
                                  child: Text(
                                    tutor['name']?.substring(0, 1).toUpperCase() ?? 'T',
                                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(tutor['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(tutor['email'] ?? 'No email'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: const Text('Present', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdminTutorSessionActivityPage(
                                            teacherId: tutor['teacherId'],
                                            teacherName: tutor['name'] ?? 'Unknown',
                                            date: DateFormat('yyyy-MM-dd').format(_dailyDate),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.history_edu, color: Colors.teal, size: 16),
                                    label: const Text('View Session Activity', style: TextStyle(color: Colors.teal)),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.teal.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildReportView() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: DateTimeRange(start: _reportStartDate, end: _reportEndDate),
                      );
                      if (selected != null) {
                        setState(() {
                          _reportStartDate = selected.start;
                          _reportEndDate = selected.end;
                        });
                        _fetchReportData();
                      }
                    },
                    icon: const Icon(Icons.date_range, color: Colors.teal, size: 18),
                    label: Text(
                      '${DateFormat('MMM dd').format(_reportStartDate)} - ${DateFormat('MMM dd').format(_reportEndDate)}',
                      style: const TextStyle(color: Colors.teal),
                    ),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.teal)),
                  )
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: _isLoadingReport
              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
              : _reportData.isEmpty
                  ? _buildEmptyState('No attendance records found for this date range.')
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                      itemCount: _reportData.length,
                      itemBuilder: (context, index) {
                        final report = _reportData[index];
                        final dayWise = (report['dayWise'] as Map<String, dynamic>? ?? {});
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.teal.shade100),
                            boxShadow: [
                              BoxShadow(color: Colors.teal.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade100,
                                child: Text(
                                  report['name']?.substring(0, 1).toUpperCase() ?? 'T',
                                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(report['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${report['totalPresent']} Present / ${report['totalAbsent']} Absent',
                                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500),
                                  ),
                                  if (report['salaryType'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.currency_rupee_rounded, size: 14, color: Colors.grey.shade700),
                                          Text(
                                            '${report['totalSalary']} Total (${report['salaryType'] == 'monthwise' ? 'Monthly' : 'Daily'})',
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      if (report['salaryType'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                          margin: const EdgeInsets.only(bottom: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.teal.shade100),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              _buildSalaryInfoStat('Base Salary', '₹${report['salaryAmount']}'),
                                              _buildSalaryInfoStat('Type', report['salaryType'] == 'monthwise' ? 'Monthly' : 'Daily'),
                                              _buildSalaryInfoStat('Total Pay', '₹${report['totalSalary']}', isHighlight: true),
                                            ],
                                          ),
                                        ),
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: EdgeInsets.only(bottom: 8.0),
                                          child: Text('Daily Attendance Breakdown', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                                        ),
                                      ),
                                      ...dayWise.entries.map((entry) {
                                      final isPresent = entry.value.toString().toLowerCase() == 'present';
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(DateTime.parse(entry.key)),
                                              style: const TextStyle(color: Colors.black54),
                                            ),
                                            Text(
                                              entry.value.toString(),
                                              style: TextStyle(
                                                color: isPresent ? Colors.green : Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSalaryInfoStat(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.teal.shade700)),
        const SizedBox(height: 4),
        Text(
          value, 
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.bold, 
            color: isHighlight ? Colors.teal.shade900 : Colors.teal.shade800
          )
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 80, color: Colors.teal.shade200),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.teal.shade700, fontSize: 16)),
        ],
      ),
    );
  }

}
