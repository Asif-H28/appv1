import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:intl/intl.dart';
import 'student_theme_manager.dart';

class UploadPaymentProofPage extends StatefulWidget {
  const UploadPaymentProofPage({super.key});

  @override
  State<UploadPaymentProofPage> createState() => _UploadPaymentProofPageState();
}

class _UploadPaymentProofPageState extends State<UploadPaymentProofPage> {
  bool _isLoading = false;
  bool _isUploadingImage = false;
  List<dynamic> _uploads = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchUploads();
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
      // Filter for payment screenshot uploads.
      final url = Uri.parse('${ApiConstants.apiBaseUrl}/student-uploads?page=$_currentPage&limit=10&uploadType=general');
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final allData = data['data'] ?? [];
          setState(() {
            _uploads = (allData as List).where((u) => u['title'] == 'payment screenshot').toList();
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
      final url = Uri.parse('${ApiConstants.apiBaseUrl}/student-uploads?page=$_currentPage&limit=10&uploadType=general');
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final moreData = data['data'] ?? [];
          setState(() {
            _uploads.addAll((moreData as List).where((u) => u['title'] == 'payment screenshot'));
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

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Library'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageAndUpload(ImageSource.gallery);
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageAndUpload(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageAndUpload(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image == null) return;

      setState(() => _isUploadingImage = true);

      // Upload Image
      final uploadUrl = '${ApiConstants.apiBaseUrl}/upload/image';
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      
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
      _showSnackBar('Error picking image: $e', true);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _createStudentUpload(String imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentName = prefs.getString('studentName') ?? prefs.getString('userEmail') ?? 'Unknown User';

      final url = Uri.parse('${ApiConstants.apiBaseUrl}/student-uploads');
      final body = {
        "title": "payment screenshot",
        "imageUrl": imageUrl,
        "uploadedByName": studentName,
        "uploadType": "general"
      };

      final response = await ApiService.post(url, body: jsonEncode(body));
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Upload successful!', false);
        _fetchUploads(); // Refresh list
      } else {
        _showSnackBar('Failed to upload payment proof: ${response.statusCode}', true);
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
            title: const Text('Upload Payment Proof', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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
                child: ElevatedButton.icon(
                  onPressed: _isUploadingImage ? null : () => _showPickerOptions(context),
                  icon: _isUploadingImage 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.upload_file),
                  label: Text(_isUploadingImage ? 'Uploading...' : 'Upload or Take Picture'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading 
                    ? Center(child: CircularProgressIndicator(color: theme.primary))
                    : _uploads.isEmpty
                        ? Center(child: Text('No payment proof records found.', style: TextStyle(color: theme.textSecondary)))
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
