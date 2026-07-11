import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';

class AdminParentAttendanceUploadsPage extends StatefulWidget {
  const AdminParentAttendanceUploadsPage({super.key});

  @override
  State<AdminParentAttendanceUploadsPage> createState() => _AdminParentAttendanceUploadsPageState();
}

class _AdminParentAttendanceUploadsPageState extends State<AdminParentAttendanceUploadsPage> {
  bool _isLoading = false;
  List<dynamic> _uploads = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;
  final ScrollController _scrollController = ScrollController();

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
      final url = Uri.parse('${ApiConstants.apiBaseUrl}/student-uploads?title=teacher%20Attendence&page=$_currentPage&limit=20');
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
      final url = Uri.parse('${ApiConstants.apiBaseUrl}/student-uploads?title=teacher%20Attendence&page=$_currentPage&limit=20');
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _uploads.addAll(data['data'] ?? []);
            _totalPages = data['totalPages'] ?? 1;
          });
        }
      } else {
        _currentPage--;
      }
    } catch (e) {
      _currentPage--;
    } finally {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Attendence Uploads'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _uploads.isEmpty
              ? const Center(child: Text('No attendance uploads found.', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                  itemCount: _uploads.length + (_isFetchingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _uploads.length) {
                      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.teal)));
                    }
                    final upload = _uploads[index];
                    final title = upload['title'] ?? 'Untitled';
                    final uploaderName = upload['uploadedByName'] ?? 'Unknown';
                    final teacherName = upload['teacherName'] ?? '';
                    final imageUrl = upload['imageUrl'];
                    final date = upload['createdAt'] != null 
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(upload['createdAt']).toLocal())
                        : '';
                    
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Text(
                                  date,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Uploaded By: $uploaderName', style: const TextStyle(fontSize: 14)),
                            if (teacherName.isNotEmpty)
                              Text('Teacher: $teacherName', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 12),
                            if (imageUrl != null && imageUrl.toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
