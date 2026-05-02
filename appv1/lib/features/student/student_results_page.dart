import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_results_widgets.dart';
import 'student_result_detail_page.dart';

class StudentResultsPage extends StatefulWidget {
  const StudentResultsPage({super.key});

  @override
  State<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage>
    with SingleTickerProviderStateMixin {
  String _classId = '';
  String _studentId = '';

  bool _testsLoading = true;
  bool _testsError = false;
  List<Map<String, dynamic>> _tests = [];
  Map<String, dynamic>? _selectedTest;

  bool _resultsLoading = false;
  bool _resultsError = false;
  List<Map<String, dynamic>> _results = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _classId = prefs.getString('classId') ?? '';
      _studentId = prefs.getString('studentId') ?? '';
    });
    if (_classId.isNotEmpty) {
      await _fetchTests();
    } else {
      if (mounted) setState(() => _testsLoading = false);
    }
  }

  Future<void> _fetchTests() async {
    if (!mounted) return;
    setState(() {
      _testsLoading = true;
      _testsError = false;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/test/class/$_classId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final raw = (body['tests'] as List? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        setState(() {
          _tests = raw;
          _testsLoading = false;
          if (raw.isNotEmpty) {
            _selectedTest = raw.first;
          }
        });
        if (raw.isNotEmpty) {
          await _fetchResults(raw.first['testId'].toString());
        }
      } else {
        setState(() {
          _testsError = true;
          _testsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _testsError = true;
          _testsLoading = false;
        });
      }
    }
  }

  Future<void> _fetchResults(String testId) async {
    if (!mounted) return;
    setState(() {
      _resultsLoading = true;
      _resultsError = false;
      _results = [];
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/result/test/$testId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        setState(() {
          _results = (body['results'] as List? ?? [])
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _resultsLoading = false;
        });
      } else {
        setState(() {
          _resultsError = true;
          _resultsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resultsError = true;
          _resultsLoading = false;
        });
      }
    }
  }

  void _onTestSelected(Map<String, dynamic> test) {
    if (_selectedTest?['testId'] == test['testId']) return;
    setState(() => _selectedTest = test);
    _fetchResults(test['testId'].toString());
  }

  Map<String, dynamic>? get _myResult {
    try {
      return _results.firstWhere(
        (r) => r['studentId']?.toString() == _studentId,
      );
    } catch (_) {
      return null;
    }
  }

  int get _myRank {
    for (int i = 0; i < _results.length; i++) {
      if (_results[i]['studentId']?.toString() == _studentId) return i + 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // â”€â”€ Top control bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        ResultsTopBar(
          tests: _tests,
          selectedTest: _selectedTest,
          testsLoading: _testsLoading,
          tabController: _tabController,
          onTestSelected: _onTestSelected,
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

        // â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Expanded(
          child: _testsLoading
              ? const ResultsSkeleton()
              : _testsError
              ? ResultsErrorState(onRetry: _fetchTests)
              : _tests.isEmpty
              ? const ResultsNoTestsState()
              : TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // My Result tab
                    _resultsLoading
                        ? const ResultsSkeleton()
                        : _resultsError
                        ? ResultsErrorState(
                            onRetry: () => _fetchResults(
                              _selectedTest?['testId']?.toString() ?? '',
                            ),
                          )
                        : _myResult == null
                        ? const ResultsNoResultsState()
                        : MyResultTab(result: _myResult!, rank: _myRank),

                    // Class Results tab
                    _resultsLoading
                        ? const ResultsSkeleton()
                        : _resultsError
                        ? ResultsErrorState(
                            onRetry: () => _fetchResults(
                              _selectedTest?['testId']?.toString() ?? '',
                            ),
                          )
                        : _results.isEmpty
                        ? const ResultsNoResultsState()
                        : ClassResultsTab(
                            results: _results,
                            studentId: _studentId,
                          ),
                  ],
                ),
        ),
      ],
    );
  }
}

