import 'package:flutter/material.dart';
import 'package:appv1/features/tuition_session/models/tuition_session_models.dart';
import 'package:appv1/features/tuition_session/services/tuition_session_service.dart';
import 'package:appv1/features/tuition_session/widgets/session_status_badge.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appv1/features/teacher/presentation/widgets/pdf_viewer_page.dart';

class AdminSessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const AdminSessionDetailScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<AdminSessionDetailScreen> createState() => _AdminSessionDetailScreenState();
}

class _AdminSessionDetailScreenState extends State<AdminSessionDetailScreen> {
  bool _isLoading = true;
  SessionDetailDTO? _session;
  Map<String, dynamic>? _activityData;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    setState(() => _isLoading = true);
    
    // Fetch base session details
    final res = await TuitionSessionService.fetchSessionDetail(widget.sessionId);
    
    // Fetch new activity API data
    Map<String, dynamic>? newActivity;
    final actRes = await TuitionSessionService.fetchSessionActivity(widget.sessionId);
    if (actRes['success']) {
      newActivity = actRes['activity'];
    }

    if (res['success']) {
      setState(() {
        _session = res['session'] as SessionDetailDTO;
        _activityData = newActivity ?? _session!.activity;
        _isLoading = false;
      });
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat('hh:mm a').format(time);
  }

  void _openPdf(String url, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(url: url, fileName: fileName),
      ),
    );
  }

  void _openImage(String url, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          body: InteractiveViewer(
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatSectionName(String section) {
    if (section == 'homeworkProvided') return 'Homework Provided';
    if (section == 'studentCompletedHomework') return 'Student Completed Homework';
    if (section == 'testGiven') return 'Test Given';
    return section;
  }

  Widget _buildAttachmentsSection(List<dynamic>? attachments) {
    if (attachments == null || attachments.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
        const SizedBox(height: 12),
        Column(
          children: attachments.map((att) {
            final type = att['type']?.toString() ?? 'unknown';
            final url = att['url']?.toString() ?? '';
            final name = att['filename']?.toString() ?? 'Attachment';
            final section = att['section']?.toString() ?? 'File';

            IconData icon = Icons.insert_drive_file_rounded;
            if (type == 'image') icon = Icons.image_rounded;
            if (type == 'pdf') icon = Icons.picture_as_pdf_rounded;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (url.isEmpty) return;
                    
                    final lowerUrl = url.toLowerCase();
                    final isPdf = lowerUrl.contains('.pdf') || type == 'pdf';
                    final isImage = lowerUrl.contains('.jpg') || lowerUrl.contains('.png') || lowerUrl.contains('.jpeg') || lowerUrl.contains('.webp') || type == 'image';

                    if (isPdf) {
                      _openPdf(url, name);
                    } else if (isImage) {
                      _openImage(url, name);
                    } else {
                      // Fallback
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: Colors.teal, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatSectionName(section),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.teal,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Session Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _session == null
              ? const Center(child: Text('Session not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SessionStatusBadge(status: _session!.status, forcedCheckIn: _session!.forcedCheckIn),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Check-in', style: TextStyle(color: Colors.black54)),
                                      Text(_formatTime(_session!.checkInTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Check-out', style: TextStyle(color: Colors.black54)),
                                      Text(_formatTime(_session!.checkOutTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text('Duration: ${_session!.durationMinutes} min', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Participants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.person, color: Colors.blue),
                                title: Text(_session!.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Student (${_session!.studentId})'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.school, color: Colors.orange),
                                title: Text(_session!.teacherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Teacher (${_session!.teacherId})'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_session!.forcedCheckIn) ...[
                        const SizedBox(height: 24),
                        const Text('Forced Check-in Reason', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                        const SizedBox(height: 8),
                        Card(
                          color: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(_session!.forcedCheckInReason ?? 'No reason provided.'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text('Activity & Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _activityData == null
                              ? const Text('No activity logged yet.')
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_activityData!['description'] != null && _activityData!['description'].toString().isNotEmpty) ...[
                                      const Text('Description:', style: TextStyle(color: Colors.black54)),
                                      const SizedBox(height: 4),
                                      Text(_activityData!['description'].toString(), style: const TextStyle(fontSize: 15)),
                                      const SizedBox(height: 16),
                                    ],
                                    Row(
                                      children: [
                                        Icon(_activityData!['homeworkProvided'] == true || _activityData!['homeworkProvided'] == 'true' ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.teal),
                                        const SizedBox(width: 8),
                                        const Text('Homework Provided'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(_activityData!['studentCompletedHomework'] == true || _activityData!['studentCompletedHomework'] == 'true' ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.teal),
                                        const SizedBox(width: 8),
                                        const Text('Student Completed Homework'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(_activityData!['testGiven'] == true || _activityData!['testGiven'] == 'true' ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.teal),
                                        const SizedBox(width: 8),
                                        const Text('Test Given'),
                                      ],
                                    ),
                                    const Divider(height: 32),
                                    _buildAttachmentsSection(_activityData!['attachments'] as List<dynamic>?),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
