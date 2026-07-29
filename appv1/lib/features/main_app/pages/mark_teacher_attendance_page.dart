import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:appv1/features/student/student_theme_manager.dart';
import 'package:appv1/core/widgets/in_app_camera_sheet.dart';

class MarkTeacherAttendancePage extends StatefulWidget {
  const MarkTeacherAttendancePage({super.key});

  @override
  State<MarkTeacherAttendancePage> createState() => _MarkTeacherAttendancePageState();
}

class _MarkTeacherAttendancePageState extends State<MarkTeacherAttendancePage> {
  bool _isLoading = false;
  bool _isUploadingImage = false;
  List<dynamic> _uploads = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _teachers = [];
  String? _selectedTeacherId;
  bool _isLoadingTeachers = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkLostData();
    _fetchTeachers();
    _fetchUploads();
  }

  Future<void> _checkLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        _uploadXFile(response.file!);
      }
    } catch (_) {}
  }

  Future<void> _fetchTeachers() async {
    setState(() => _isLoadingTeachers = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final orgId = prefs.getString('orgId') ?? '';
      if (orgId.isEmpty) return;

      final url = Uri.parse('${ApiConstants.apiBaseUrl}/teacher/org/$orgId');
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['teachers'] != null) {
          setState(() {
            final fetchedTeachers = List<Map<String, dynamic>>.from(data['teachers']);
            final uniqueTeachers = <String, Map<String, dynamic>>{};
            for (var t in fetchedTeachers) {
              final id = t['teacherId'] ?? t['_id'];
              if (id != null) {
                uniqueTeachers[id.toString()] = t;
              }
            }
            _teachers = uniqueTeachers.values.toList();
          });
        }
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingTeachers = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isFetchingMore &&
        _currentPage < _totalPages) {
      _fetchMoreUploads();
    }
  }

  Future<void> _fetchUploads() async {
    setState(() => _isLoading = true);
    try {
      _currentPage = 1;
      final url = Uri.parse('${ApiConstants.apiBaseUrl}/student-uploads?page=$_currentPage&limit=10&uploadType=teacher');
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _uploads = data['data'] ?? [];
            _totalPages = data['totalPages'] ?? 1;
          });
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreUploads() async {
    setState(() => _isFetchingMore = true);
    try {
      _currentPage++;
      final url = Uri.parse('${ApiConstants.apiBaseUrl}/student-uploads?page=$_currentPage&limit=10&uploadType=teacher');
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _uploads.addAll(data['data'] ?? []);
            _totalPages = data['totalPages'] ?? _totalPages;
          });
        }
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  Future<void> _takePictureAndUpload() async {
    try {
      final XFile? image = await InAppCameraSheet.show(context);
      if (image == null) return;
      await _uploadXFile(image);
    } catch (e) {
      _showSnackBar('Error taking picture: $e', true);
    }
  }

  Future<void> _uploadXFile(XFile image) async {
    setState(() => _isUploadingImage = true);

    try {
      // Upload Image
      final uploadUrl = '${ApiConstants.apiBaseUrl}/upload/image';
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: image.name,
      ));
      
      final headers = await ApiService.getHeaders();
      request.headers.addAll(headers);

      final streamedResponse = await request.send();
      final uploadResponse = await http.Response.fromStream(streamedResponse);

      if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
        final body = jsonDecode(uploadResponse.body);
        final imageUrl = body['file']['url'].toString();

        // Create student upload
        await _createStudentUpload(imageUrl);
      } else {
        _showSnackBar('Failed to upload image: ${uploadResponse.statusCode}', true);
      }
    } catch (e) {
      _showSnackBar('Error taking picture: $e', true);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _createStudentUpload(String imageUrl) async {
    if (_selectedTeacherId == null) {
      _showSnackBar('Please select a teacher first.', true);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentName = prefs.getString('studentName') ?? prefs.getString('userEmail') ?? 'Unknown User';

      final selectedTeacher = _teachers.firstWhere(
        (t) => (t['teacherId'] ?? t['_id']).toString() == _selectedTeacherId,
        orElse: () => <String, dynamic>{},
      );
      final teacherName = selectedTeacher['name'] ?? 'Unknown Teacher';

      final url = Uri.parse('${ApiConstants.apiBaseUrl}/student-uploads');
      final body = {
        "title": "teacher Attendence",
        "imageUrl": imageUrl,
        "uploadedByName": studentName,
        "uploadType": "teacher",
        "teacherId": _selectedTeacherId,
        "teacherName": teacherName,
      };

      final response = await ApiService.post(url, body: jsonEncode(body));
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Attendance marked successfully!', false);
        _fetchUploads(); // Refresh list
      } else {
        _showSnackBar('Failed to mark attendance: ${response.statusCode}', true);
      }
    } catch (e) {
      _showSnackBar('Network error occurred.', true);
    }
  }

  Future<void> _deleteUpload(String id) async {
    try {
      final url = Uri.parse('${ApiConstants.apiBaseUrl}/student-uploads/$id');
      final response = await ApiService.delete(url);
      if (response.statusCode == 200) {
        _showSnackBar('Deleted successfully.', false);
        _fetchUploads();
      } else {
        _showSnackBar('Failed to delete.', true);
      }
    } catch (e) {
      _showSnackBar('Network error occurred.', true);
    }
  }

  Future<void> _editUploadTitle(String id, String currentTitle) async {
    final controller = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Title'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newTitle == null || newTitle.isEmpty || newTitle == currentTitle) return;

    try {
      final url = Uri.parse('${ApiConstants.apiBaseUrl}/student-uploads/$id');
      final body = {"title": newTitle};
      final response = await ApiService.put(url, body: body);

      if (response.statusCode == 200) {
        _showSnackBar('Updated successfully.', false);
        _fetchUploads();
      } else {
        _showSnackBar('Failed to update.', true);
      }
    } catch (e) {
      _showSnackBar('Network error occurred.', true);
    }
  }

  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            title: const Text('Mark Teacher Attendance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            backgroundColor: theme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.cardBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isLoadingTeachers)
                      Center(child: CircularProgressIndicator(color: theme.primary))
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedTeacherId,
                        hint: Text(_teachers.isEmpty ? 'No Teachers Found' : 'Select Teacher', style: TextStyle(color: theme.textSecondary)),
                        dropdownColor: theme.cardBackground,
                        isExpanded: true,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.dividerColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        style: TextStyle(color: theme.textPrimary, fontSize: 14),
                        items: _teachers.isEmpty 
                          ? []
                          : _teachers.map((teacher) {
                          return DropdownMenuItem<String>(
                                value: (teacher['teacherId'] ?? teacher['_id'])?.toString(),
                                child: Text(teacher['name']?.toString() ?? 'Unknown'),
                              );
                            }).toList(),
                        onChanged: _teachers.isEmpty ? null : (val) {
                          setState(() {
                            _selectedTeacherId = val;
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: (_isUploadingImage || _selectedTeacherId == null) ? null : _takePictureAndUpload,
                      icon: _isUploadingImage 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(Icons.camera_alt),
                      label: Text(_isUploadingImage ? 'Uploading...' : 'Take Picture'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading 
                    ? Center(child: CircularProgressIndicator(color: theme.primary))
                    : _uploads.isEmpty
                        ? Center(child: Text('No attendance records found.', style: TextStyle(color: theme.textSecondary)))
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _uploads.length + (_isFetchingMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index == _uploads.length) {
                                return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: CircularProgressIndicator(color: theme.primary)));
                              }
                              final upload = _uploads[index];
                          final id = upload['_id'];
                          final title = upload['title'] ?? 'Untitled';
                          final imageUrl = upload['imageUrl'];
                              final date = upload['createdAt'] != null 
                                  ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(upload['createdAt']).toLocal())
                                  : '';
                              
                              return Container(
                                decoration: BoxDecoration(
                                  color: theme.cardBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.dividerColor),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(8),
                                  leading: imageUrl != null 
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: theme.dividerColor, child: Icon(Icons.image_not_supported, color: theme.textSecondary)),
                                          ),
                                        )
                                      : Container(width: 60, height: 60, color: theme.dividerColor, child: Icon(Icons.image, color: theme.textSecondary)),
                                  title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textPrimary)),
                                  subtitle: Text(date, style: TextStyle(fontSize: 12, color: theme.textSecondary)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                    onPressed: () => _deleteUpload(id),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
