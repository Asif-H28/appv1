import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/enter_ca_marks_sheet.dart';

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
        headers: {'Content-Type': 'application/json'},
      );
      print('[CaResultsPage] Students API status: ${res1.statusCode}');
      
      // Fetch results for this assessment
      final res2 = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/comprehensive-result/assessment/$assessmentId'),
        headers: {'Content-Type': 'application/json'},
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
