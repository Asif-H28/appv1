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

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    final rawTitle = upload['title'] ?? 'Untitled';
                    final title = rawTitle.isNotEmpty 
                        ? '${rawTitle[0].toUpperCase()}${rawTitle.substring(1)}'
                        : rawTitle;
                    final uploaderName = upload['uploadedByName'] ?? 'Unknown';
                    final teacherName = upload['teacherName'] ?? '';
                    final imageUrl = upload['imageUrl'];
                    final date = upload['createdAt'] != null 
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(upload['createdAt']).toLocal())
                        : '';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.teal.shade100, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl != null && imageUrl.toString().isNotEmpty)
                              GestureDetector(
                                onTap: () => _showFullImage(context, imageUrl),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    width: 85,
                                    height: 85,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 85,
                                      height: 85,
                                      color: Colors.teal.shade50,
                                      child: const Icon(Icons.broken_image, color: Colors.teal),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 85,
                                height: 85,
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.image_not_supported, color: Colors.teal),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 14, color: Colors.teal),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          uploaderName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, color: Colors.teal),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (teacherName.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.school_outlined, size: 14, color: Colors.teal),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            teacherName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13, color: Colors.teal),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(top: 2),
                                              child: Icon(Icons.calendar_today_outlined, size: 12, color: Colors.teal),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                date,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.teal,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (imageUrl != null && imageUrl.toString().isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _showFullImage(context, imageUrl),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.teal,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.visibility, size: 14, color: Colors.white),
                                                SizedBox(width: 4),
                                                Text(
                                                  'View',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
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
