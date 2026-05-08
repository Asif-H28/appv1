import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import 'create_ca_sheet.dart';
import 'edit_ca_sheet.dart';
import '../pages/ca_results_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ClassroomTestsTab extends StatefulWidget {
  final String classId;
  final String teacherId;
  final String teacherName;
  final String orgId;
  final String className;
  final List<Map<String, dynamic>> classSubjects;

  const ClassroomTestsTab({
    required this.classId,
    required this.teacherId,
    required this.teacherName,
    required this.orgId,
    required this.className,
    required this.classSubjects,
  });

  @override
  _ClassroomTestsTabState createState() => _ClassroomTestsTabState();
}

class _ClassroomTestsTabState extends State<ClassroomTestsTab> {
  static const Color _accent = Colors.teal;
  List<Map<String, dynamic>> _tests = [];
  bool _isLoading = true;
  bool _hasError = false;
  final Map<String, bool> _deletingMap = {};
  Map<String, bool> _exportingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchTests();
  }

  Future<void> _fetchTests() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final res2 = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/comprehensive-assessment/list?orgId=${widget.orgId}&classId=${widget.classId}'),
        headers: await ApiService.getHeaders(),
      );

      if (!mounted) return;

      List<Map<String, dynamic>> raw2 = [];
      if (res2.statusCode == 200) {
        final body2 = jsonDecode(res2.body);
        if (body2 is List) raw2 = body2.map((e) => e as Map<String, dynamic>).toList();
        else if (body2['data'] is List) raw2 = (body2['data'] as List).map((e) => e as Map<String, dynamic>).toList();
        for (var t in raw2) t['isCA'] = true;
      }

      raw2.sort((a, b) {
        final d1 = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(2000);
        final d2 = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(2000);
        return d2.compareTo(d1);
      });

      setState(() {
        _tests = raw2;
        _isLoading = false;
        _hasError = (res2.statusCode != 200);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _deleteTest(String testId) async {
    print('Attempting to delete test with ID: $testId');
    setState(() => _deletingMap[testId] = true);
    try {
      final url = '${ApiConstants.apiBaseUrl}/comprehensive-assessment/delete/$testId';
      print('Delete URL: $url');
      final response = await http.delete(
        Uri.parse(url),
        headers: await ApiService.getHeaders(),
      );
      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');
      
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _deletingMap.remove(testId);
          _tests.removeWhere((t) => t['assessmentId']?.toString() == testId || t['_id']?.toString() == testId || t['testId']?.toString() == testId);
        });
        _snack('Assessment deleted.', Colors.green[600]!);
      } else {
        setState(() => _deletingMap.remove(testId));
        final Map<String, dynamic> bodyDecoded = jsonDecode(response.body);
        _snack(bodyDecoded['message']?.toString() ?? 'Failed to delete. Status: ${response.statusCode}', Colors.red[600]!);
      }
    } catch (e) {
      print('Delete exception: $e');
      if (!mounted) return;
      setState(() => _deletingMap.remove(testId));
      _snack('No internet connection or server error.', Colors.red[600]!);
    }
  }

  void _confirmDelete(String testId, String testName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        titlePadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        contentPadding: EdgeInsets.fromLTRB(16, 10, 16, 0),
        actionsPadding: EdgeInsets.fromLTRB(16, 8, 16, 14),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.delete_rounded,
                color: Colors.red[600],
                size: 15,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Delete Test',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Delete "$testName"? This cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: Theme(
                    data: ThemeData(
                      colorScheme: ColorScheme.light(
                        primary: Colors.red[600]!,
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteTest(testId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportTest(String assessmentId, String testName) async {
    setState(() => _exportingIds[assessmentId] = true);
    try {
      // 1. Request permissions if on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // If storage permission is denied, we can still try to save to app-specific folder
          // but let's notify the user.
          debugPrint('Storage permission denied. Falling back to internal storage.');
        }
      }

      final url = Uri.parse('${ApiConstants.apiBaseUrl}/comprehensive-assessment/export/$assessmentId');
      final response = await http.get(
        url,
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        String? selectedPath;
        final fileName = '${testName.replaceAll(' ', '_')}_Marks.xlsx';

        if (Platform.isAndroid) {
          // Attempt to save to the public Download folder
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            selectedPath = '${downloadDir.path}/$fileName';
          } else {
            // Fallback to external storage app-specific directory
            final externalDir = await getExternalStorageDirectory();
            selectedPath = '${externalDir?.path}/$fileName';
          }
        } else {
          // iOS or other platforms
          final directory = await getApplicationDocumentsDirectory();
          selectedPath = '${directory.path}/$fileName';
        }

        if (selectedPath != null) {
          final file = File(selectedPath);
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved to: ${Platform.isAndroid ? 'Downloads' : 'Documents'}'),
                backgroundColor: Colors.green[700],
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Open',
                  textColor: Colors.white,
                  onPressed: () => OpenFile.open(selectedPath),
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to export test: ${response.statusCode}'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting test: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exportingIds[assessmentId] = false);
      }
    }
  }

  void _openCreateCaSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateCaSheet(
        classId: widget.classId,
        teacherId: widget.teacherId,
        teacherName: widget.teacherName,
        orgId: widget.orgId,
        className: widget.className,
        classSubjects: widget.classSubjects,
        onCreated: (newTest) {
          newTest['isCA'] = true;
          setState(() => _tests.insert(0, newTest));
          _snack('Assessment created!', Colors.green[600]!);
        },
      ),
    );
  }

  void _openEditCaSheet(Map<String, dynamic> test) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditCaSheet(
        test: test,
        onUpdated: (updated) {
          final idx = _tests.indexWhere(
            (t) => (t['assessmentId']?.toString() ?? t['_id']?.toString()) == (updated['assessmentId']?.toString() ?? updated['_id']?.toString()),
          );
          if (idx != -1) setState(() => _tests[idx] = updated);
          _snack('Assessment updated!', Colors.green[600]!);
        },
      ),
    );
  }

  void _openResultsPage(Map<String, dynamic> test) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaResultsPage(
          assessment: test,
          classId: widget.classId,
          orgId: widget.orgId,
          teacherName: widget.teacherName,
        ),
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
      );
    if (_hasError) return _buildError();

    return Column(
      children: [
        // â”€â”€ Action bar â”€â”€
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(
            children: [
              // Count chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_rounded, color: _accent, size: 12),
                    SizedBox(width: 5),
                    Text(
                      '${_tests.length} Test${_tests.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              // Refresh
              // Refresh
              SizedBox(
                width: 38,
                height: 38,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.refresh_rounded, color: _accent, size: 16),
                    onPressed: _fetchTests,
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ),
              ),

              SizedBox(width: 8),
              // Create button
              GestureDetector(
                onTap: _openCreateCaSheet,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 5),
                      Text(
                        'Create Test',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 10),

        // â”€â”€ Body â”€â”€
        _tests.isEmpty
            ? _buildEmpty()
            : Expanded(
                child: RefreshIndicator(
                  color: _accent,
                  onRefresh: _fetchTests,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(14, 4, 14, 40),
                    itemCount: _tests.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8),
                    itemBuilder: (_, i) => _testCard(_tests[i]),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _testCard(Map<String, dynamic> test) {
    final testId = test['assessmentId']?.toString() ?? test['_id']?.toString() ?? '';
    final testName = test['title']?.toString() ?? 'Unnamed Assessment';
    final tName = test['teacherName']?.toString() ?? 'Unknown Teacher';
    final cName = test['className']?.toString() ?? 'Unknown Class';
    final createdAt = test['createdAt']?.toString() ?? '';
    final isDeleting = _deletingMap[testId] == true;

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ Card header â”€â”€
          Container(
            padding: EdgeInsets.fromLTRB(10, 9, 6, 9),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.04),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(Icons.assignment_turned_in_rounded, color: _accent, size: 16),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 10, color: AppColors.textSecondary),
                          SizedBox(width: 3),
                          Text(tName, style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
                          SizedBox(width: 8),
                          Icon(Icons.class_outlined, size: 10, color: AppColors.textSecondary),
                          SizedBox(width: 3),
                          Text(cName, style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
                        ],
                      ),
                      if (dateStr.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 9,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 3),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (isDeleting)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.red[400],
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconBtn(
                        Icons.edit_outlined,
                        _accent,
                        () => _openEditCaSheet(test),
                      ),
                      SizedBox(width: 4),
                      _iconBtn(
                        Icons.delete_outline_rounded,
                        Colors.red[400]!,
                        () => _confirmDelete(testId, testName),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // â”€â”€ Footer: Enter Marks button â”€â”€
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                // Export button
                GestureDetector(
                  onTap: _exportingIds[testId] == true
                      ? null
                      : () => _exportTest(testId, testName),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_exportingIds[testId] == true)
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.blue[700],
                            ),
                          )
                        else
                          Icon(
                            Icons.file_download_outlined,
                            color: Colors.blue[700],
                            size: 14,
                          ),
                        SizedBox(width: 5),
                        Text(
                          _exportingIds[testId] == true ? 'Exporting...' : 'Export XLS',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Spacer(),
                // Enter marks button
                GestureDetector(
                  onTap: () => _openResultsPage(test),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Enter / View Marks',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
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

  Widget _scoreBadge(String label, String value, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      '$label: $value',
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
    ),
  );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      );

  Widget _buildEmpty() => Expanded(
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _accent.withOpacity(0.08),
              ),
              child: Icon(Icons.quiz_outlined, color: _accent, size: 28),
            ),
            SizedBox(height: 14),
            Text(
              'No Tests Yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Create a test to evaluate\nstudents in this classroom.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            SizedBox(height: 18),
            Theme(
              data: ThemeData(
                colorScheme: ColorScheme.light(
                  primary: _accent,
                  onPrimary: Colors.white,
                ),
              ),
              child: SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: _openCreateCaSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  icon: Icon(Icons.add_rounded, size: 15, color: Colors.white),
                  label: Text(
                    'Create Test',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'Could not load tests',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Theme(
            data: ThemeData(
              colorScheme: ColorScheme.light(
                primary: _accent,
                onPrimary: Colors.white,
              ),
            ),
            child: SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: _fetchTests,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                icon: Icon(Icons.refresh, size: 14, color: Colors.white),
                label: Text(
                  'Retry',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

