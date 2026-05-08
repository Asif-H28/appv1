import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/enter_ca_marks_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle;
import 'package:http_parser/http_parser.dart';
import 'dart:io';

class CaResultsPage extends StatefulWidget {
  final Map<String, dynamic> assessment;
  final String classId;
  final String orgId;
  final String teacherName;

  const CaResultsPage({
    Key? key,
    required this.assessment,
    required this.classId,
    required this.orgId,
    required this.teacherName,
  }) : super(key: key);

  @override
  _CaResultsPageState createState() => _CaResultsPageState();
}

class _CaResultsPageState extends State<CaResultsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _results = [];
  
  // Search queries
  String _studentSearchQuery = '';
  String _resultsSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final assessmentId = widget.assessment['assessmentId']?.toString() ?? widget.assessment['_id']?.toString() ?? '';
      print('[CaResultsPage] Fetching data for assessment: $assessmentId');
      
      // Fetch students in class using the join/class endpoint (more reliable for student details)
      final res1 = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/join/class/${widget.classId}'),
        headers: await ApiService.getHeaders(),
      );
      print('[CaResultsPage] Students API status: ${res1.statusCode}');
      
      // Fetch results for this assessment
      final res2 = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/comprehensive-result/assessment/$assessmentId'),
        headers: await ApiService.getHeaders(),
      );
      print('[CaResultsPage] Results API status: ${res2.statusCode}');

      if (!mounted) return;

      if (res1.statusCode == 200 && res2.statusCode == 200) {
        // Handle Students
        final body1 = jsonDecode(res1.body);
        print('[CaResultsPage] Students body type: ${body1.runtimeType}');
        
        List<dynamic> rawStudents = [];
        if (body1 is List) rawStudents = body1;
        else if (body1['requests'] is List) rawStudents = body1['requests'] as List;
        else if (body1['data'] is List) rawStudents = body1['data'] as List;
        
        final approvedStudents = rawStudents
            .map((e) => e as Map<String, dynamic>)
            .where((r) => r['status']?.toString() == 'approved')
            .toList();
        print('[CaResultsPage] Total approved students: ${approvedStudents.length}');

        // Handle Results
        final body2 = jsonDecode(res2.body);
        final resultList = body2 is List ? body2.map((e) => e as Map<String, dynamic>).toList() : (body2['data'] as List? ?? []).map((e) => e as Map<String, dynamic>).toList();
        print('[CaResultsPage] Total results: ${resultList.length}');

        setState(() {
          _students = approvedStudents;
          _results = resultList;
          _isLoading = false;
        });
      } else {
        print('[CaResultsPage] API error: res1=${res1.statusCode}, res2=${res2.statusCode}');
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      print('[CaResultsPage] Exception in _fetchData: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _openEntrySheet(Map<String, dynamic> student) {
    final studentId = student['studentId']?.toString() ?? student['_id']?.toString() ?? '';
    final existing = _results.firstWhere(
      (r) => r['studentId']?.toString() == studentId,
      orElse: () => <String, dynamic>{},
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EnterCaMarksSheet(
        assessment: widget.assessment,
        student: student,
        classId: widget.classId,
        orgId: widget.orgId,
        teacherName: widget.teacherName,
        existingResult: existing.isEmpty ? null : existing,
        onSaved: (newResult) {
          _fetchData();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.assessment['title']?.toString() ?? 'Assessment Results';
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.file_upload_outlined),
            tooltip: 'Import Results from Excel',
            onPressed: _openImportSheet,
          ),
          SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Enter Marks'),
            Tab(text: 'View Results'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : _hasError
          ? _buildError()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEntryTab(),
                _buildResultsTab(),
              ],
            ),
    );
  }

  Widget _buildEntryTab() {
    final filteredStudents = _students.where((s) {
      final name = s['name']?.toString().toLowerCase() ?? '';
      return name.contains(_studentSearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            onChanged: (v) => setState(() => _studentSearchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search student...',
              prefixIcon: Icon(Icons.search, size: 20, color: Colors.teal),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide(color: Colors.teal),
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredStudents.isEmpty
              ? _buildEmpty('No students found.')
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: filteredStudents.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    final studentId = student['studentId']?.toString() ?? student['_id']?.toString() ?? '';
                    final hasResult = _results.any((r) => r['studentId']?.toString() == studentId);
                    
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                        side: BorderSide(color: Colors.teal.shade50),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        onTap: () => _openEntrySheet(student),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: Text(
                              (student['studentName']?.toString() ?? student['name']?.toString() ?? '?')[0].toUpperCase(),
                              style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        title: Text(
                          student['studentName']?.toString() ?? student['name']?.toString() ?? 'Unknown',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal[900]),
                        ),
                        subtitle: Text(
                          student['studentEmail']?.toString() ?? student['email']?.toString() ?? 'No email',
                          style: TextStyle(fontSize: 11, color: Colors.teal[600]),
                        ),
                        trailing: hasResult
                            ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade500,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'COMPLETED',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              )
                            : Icon(Icons.arrow_forward_ios_rounded, color: Colors.teal[200], size: 14),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResultsTab() {
    final filteredResults = _results.where((r) {
      final name = r['studentName']?.toString().toLowerCase() ?? '';
      return name.contains(_resultsSearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            onChanged: (v) => setState(() => _resultsSearchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search results by student name...',
              prefixIcon: Icon(Icons.search, size: 20, color: Colors.teal),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide(color: Colors.teal),
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredResults.isEmpty
              ? _buildEmpty('No results found.')
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: filteredResults.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, index) => _resultCard(filteredResults[index]),
                ),
        ),
      ],
    );
  }

  Widget _resultCard(Map<String, dynamic> result) {
    final scholastic = result['scholasticResults'] as List? ?? [];
    final coScholastic = result['coScholasticResults'] as List? ?? [];
    
    // Calculate total marks across all scholastic subjects
    double totalScored = 0;
    double totalMax = 0;
    
    for (final s in scholastic) {
      totalScored += (s['totalMarksScored'] as num?)?.toDouble() ?? 0;
      // Try to find max score from assessment subjects
      final subName = s['subjectName']?.toString();
      final assessmentSubjects = widget.assessment['scholasticSubjects'] as List? ?? [];
      final assessmentSub = assessmentSubjects.firstWhere(
        (as) => as['subjectName'] == subName,
        orElse: () => null,
      );
      if (assessmentSub != null) {
        final internalMax = (assessmentSub['internalMaximumScore'] as num?)?.toDouble() ?? 0;
        final externalMax = (assessmentSub['externalMaximumScore'] as num?)?.toDouble() ?? 0;
        totalMax += (internalMax + externalMax);
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: BorderSide(color: Colors.teal.shade100, width: 1),
      ),
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: Colors.teal,
        collapsedIconColor: Colors.teal.shade300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        title: Text(
          result['studentName']?.toString() ?? 'Student',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal[900]),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.stars_rounded, size: 14, color: Colors.teal[600]),
              SizedBox(width: 4),
              Text(
                'Total: ${totalScored.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal[800]),
              ),
              Spacer(),
              Text(
                'View Details',
                style: TextStyle(fontSize: 11, color: Colors.teal[700], fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.02),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scholastic Table
                if (scholastic.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 16, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'SCHOLASTIC AREAS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal[700], letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'SUBJECT',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[900], letterSpacing: 0.5),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'MARKS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[900], letterSpacing: 0.5),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'GRADE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[900], letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Subject Rows
                        ...scholastic.map((s) {
                          final subName = s['subjectName']?.toString() ?? '';
                          final scored = (s['totalMarksScored'] as num?)?.toDouble() ?? 0;
                          final grade = s['grade']?.toString() ?? '-';
                          
                          // Look up max score
                          final assessmentSubjects = widget.assessment['scholasticSubjects'] as List? ?? [];
                          final assessmentSub = assessmentSubjects.firstWhere(
                            (as) => as['subjectName'] == subName,
                            orElse: () => null,
                          );
                          double max = 0;
                          if (assessmentSub != null) {
                            final iM = (assessmentSub['internalMaximumScore'] as num?)?.toDouble() ?? 0;
                            final eM = (assessmentSub['externalMaximumScore'] as num?)?.toDouble() ?? 0;
                            max = iM + eM;
                          }

                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    subName,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${scored.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    grade,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal[700]),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        // Total Row
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Total',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${totalScored.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.teal[900]),
                                ),
                              ),
                              Expanded(child: SizedBox()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Co-Scholastic Results
                if (coScholastic.isNotEmpty) ...[
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.palette_rounded, size: 16, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'CO-SCHOLASTIC ACTIVITIES',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal[700], letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'ACTIVITY',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[900], letterSpacing: 0.5),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'GRADE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[900], letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Activity Rows
                        ...coScholastic.map((c) {
                          final name = c['activityName']?.toString() ?? '';
                          final grade = c['grade']?.toString() ?? '-';
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    name,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    grade,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal[700]),
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

                // Footer / Remarks
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Published by ${result['publishedBy'] ?? widget.teacherName}',
                      style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openImportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImportResultsSheet(
        assessmentId: widget.assessment['assessmentId']?.toString() ?? widget.assessment['_id']?.toString() ?? '',
        teacherName: widget.teacherName,
        onSuccess: () {
          _fetchData();
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildEmpty(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
        SizedBox(height: 16),
        Text(msg, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
        SizedBox(height: 16),
        Text('Could not load data.', style: TextStyle(color: Colors.grey[600])),
        TextButton(onPressed: _fetchData, child: Text('Retry')),
      ],
    ),
  );
}

class _ImportResultsSheet extends StatefulWidget {
  final String assessmentId;
  final String teacherName;
  final VoidCallback onSuccess;

  const _ImportResultsSheet({
    required this.assessmentId,
    required this.teacherName,
    required this.onSuccess,
  });

  @override
  __ImportResultsSheetState createState() => __ImportResultsSheetState();
}

class __ImportResultsSheetState extends State<_ImportResultsSheet> {
  File? _selectedFile;
  List<List<dynamic>> _previewData = [];
  bool _isUploading = false;
  bool _showPreview = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _selectedFile = file;
          _showPreview = false;
          _previewData = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _generatePreview() async {
    if (_selectedFile == null) return;
    
    try {
      final bytes = _selectedFile!.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      
      final table = excel.tables[excel.tables.keys.first];
      if (table != null) {
        setState(() {
          // Get first 10 rows for preview
          _previewData = table.rows.take(10).map((row) => row.map((cell) => cell?.value).toList()).toList();
          _showPreview = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error parsing Excel: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);
    try {
      final url = '${ApiConstants.apiBaseUrl}/comprehensive-result/import/${widget.assessmentId}';
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      request.fields['publishedBy'] = widget.teacherName;
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _selectedFile!.path,
        contentType: MediaType('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Results imported successfully!'), backgroundColor: Colors.green),
          );
          widget.onSuccess();
        }
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Upload failed';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.file_upload_rounded, color: Colors.teal, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Import Results',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // File Selection Area
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.withOpacity(0.2), style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFile == null ? Icons.upload_file_rounded : Icons.check_circle_rounded,
                              size: 48,
                              color: _selectedFile == null ? Colors.teal[300] : Colors.green[400],
                            ),
                            SizedBox(height: 12),
                            Text(
                              _selectedFile == null ? 'Tap to select Excel file' : 'File selected',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                            ),
                            if (_selectedFile != null) ...[
                              SizedBox(height: 4),
                              Text(
                                _selectedFile!.path.split('/').last,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
    
                    if (_selectedFile != null) ...[
                      if (!_showPreview)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _generatePreview,
                            icon: Icon(Icons.visibility_outlined, size: 18),
                            label: Text('Preview Data'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal,
                              side: BorderSide(color: Colors.teal),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        )
                      else ...[
                        Text(
                          'Data Preview (First 10 rows)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowHeight: 30,
                                dataRowHeight: 25,
                                horizontalMargin: 12,
                                columnSpacing: 20,
                                columns: _previewData.isEmpty 
                                  ? [] 
                                  : _previewData.first.map((c) => DataColumn(label: Text(c?.toString() ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))).toList(),
                                rows: _previewData.length <= 1 
                                  ? [] 
                                  : _previewData.skip(1).map((row) => DataRow(cells: row.map((c) => DataCell(Text(c?.toString() ?? '', style: TextStyle(fontSize: 10)))).toList())).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _uploadFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: _isUploading
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Proceed to Import', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
