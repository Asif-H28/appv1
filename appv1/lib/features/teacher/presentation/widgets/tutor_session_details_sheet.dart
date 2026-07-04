import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pdf_viewer_page.dart';

class TutorSessionDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> session;

  const TutorSessionDetailsSheet({Key? key, required this.session}) : super(key: key);

  void _viewFile(BuildContext context, String url) {
    if (url.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfViewerPage(url: url, fileName: 'Document')),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context, List<String> files) {
    if (files.isEmpty) return const Text('None', style: TextStyle(color: Colors.black54));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: files.map((url) {
        final isPdf = url.toLowerCase().endsWith('.pdf');
        return InkWell(
          onTap: () => _viewFile(context, url),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.teal.shade100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    url.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.teal, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageGrid(BuildContext context, List<String> images) {
    if (images.isEmpty) return const Text('None', style: TextStyle(color: Colors.black54));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images.map((url) {
        return InkWell(
          onTap: () => _viewFile(context, url),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.shade200),
              image: DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = session['sessionEndedTime'] != null;
    final List<String> studentIds = (session['studentIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
    
    final List<String> studentPhotos = (session['studentPhotos'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final List<String> homeworkFiles = (session['homeworkFiles'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final List<String> testFiles = (session['testFiles'] as List?)?.map((e) => e.toString()).toList() ?? [];

    String startedTime = 'N/A';
    if (session['sessionStartedTime'] != null) {
      startedTime = DateFormat('MMM d, yyyy - hh:mm a').format(DateTime.parse(session['sessionStartedTime']).toLocal());
    }

    String endedTime = 'N/A';
    String actualDuration = 'N/A';
    if (session['sessionEndedTime'] != null) {
      final end = DateTime.parse(session['sessionEndedTime']);
      endedTime = DateFormat('MMM d, yyyy - hh:mm a').format(end.toLocal());
      
      if (session['sessionStartedTime'] != null) {
        final start = DateTime.parse(session['sessionStartedTime']);
        final diff = end.difference(start);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        if (hours > 0 && minutes > 0) {
          actualDuration = '$hours hr $minutes min';
        } else if (hours > 0) {
          actualDuration = '$hours hr';
        } else {
          actualDuration = '$minutes min';
        }
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Session Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.teal),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const Divider(color: Colors.teal),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  
                  // Status & Times
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Status', isCompleted ? 'Completed' : 'Active'),
                        _buildDetailRow('Started At', startedTime),
                        if (isCompleted) _buildDetailRow('Ended At', endedTime),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),
                        _buildDetailRow('Selected Duration', session['duration']?.toString() ?? 'N/A'),
                        if (isCompleted)
                           _buildDetailRow('Actual Duration', actualDuration),
                      ],
                    ),
                  ),
                  
                  // Students
                  _buildSectionHeader('Students', Icons.group_rounded),
                  _buildDetailRow('Student IDs', studentIds.isEmpty ? 'None' : studentIds.join(', ')),
                  const SizedBox(height: 8),
                  const Text('Student Photos', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildImageGrid(context, studentPhotos),

                  if (isCompleted) ...[
                    // Description
                    _buildSectionHeader('Activity Info', Icons.info_outline),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade100),
                      ),
                      child: Text(
                        session['sessionDescription']?.toString() ?? 'No description provided',
                        style: const TextStyle(color: Colors.black87, fontSize: 14, fontStyle: FontStyle.italic, height: 1.5),
                      ),
                    ),
                    
                    // Homework & Tests
                    _buildSectionHeader('Materials', Icons.attachment),
                    const Text('Homework Files', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    _buildFileList(context, homeworkFiles),
                    const SizedBox(height: 12),
                    const Text('Test Files', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    _buildFileList(context, testFiles),
                  ],
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
