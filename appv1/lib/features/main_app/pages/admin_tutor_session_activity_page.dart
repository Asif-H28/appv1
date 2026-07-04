import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/services/api_service.dart';
import '../../teacher/presentation/widgets/pdf_viewer_page.dart';

class AdminTutorSessionActivityPage extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String? date;

  const AdminTutorSessionActivityPage({
    Key? key,
    required this.teacherId,
    required this.teacherName,
    this.date,
  }) : super(key: key);

  @override
  State<AdminTutorSessionActivityPage> createState() => _AdminTutorSessionActivityPageState();
}

class _AdminTutorSessionActivityPageState extends State<AdminTutorSessionActivityPage> {
  List<dynamic> _sessions = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      String endpoint = '/tutor-sessions/admin/teacher/${widget.teacherId}';
      if (widget.date != null) {
        endpoint += '?date=${widget.date}';
      }
      final response = await ApiService.get(endpoint);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          setState(() {
            _sessions = body['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = body['message'] ?? 'Failed to load sessions';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch sessions: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDuration(String? startTime, String? endTime, String fallback) {
    if (startTime == null || endTime == null) return fallback;
    try {
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime);
      final diff = end.difference(start);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0 && minutes > 0) return '$hours hr $minutes min';
      if (hours > 0) return '$hours hr';
      return '$minutes min';
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Session Activity', style: TextStyle(fontSize: 18, color: Colors.white)),
            Text(widget.teacherName, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = '';
                });
                _fetchSessions();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.teal.shade200),
            const SizedBox(height: 16),
            Text('No session activity found for ${widget.teacherName}.', style: TextStyle(color: Colors.teal.shade700)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(dynamic session) {
    final String dateStr = session['date'] != null 
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(session['date'])) 
        : 'Unknown Date';
        
    final String startTimeStr = session['sessionStartedTime'] != null
        ? DateFormat('hh:mm a').format(DateTime.parse(session['sessionStartedTime']).toLocal())
        : '--:--';
        
    final String endTimeStr = session['sessionEndedTime'] != null
        ? DateFormat('hh:mm a').format(DateTime.parse(session['sessionEndedTime']).toLocal())
        : '--:--';

    final String actualDuration = _formatDuration(session['sessionStartedTime'], session['sessionEndedTime'], session['duration']?.toString() ?? 'N/A');
    
    final bool isCompleted = session['status'] == 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Colors.teal.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.event, size: 18, color: Colors.teal.shade700),
                    const SizedBox(width: 8),
                    Text(dateStr, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session['status']?.toString() ?? 'Active',
                    style: TextStyle(
                      color: isCompleted ? Colors.green.shade800 : Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Times & Duration
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTimeBlock('Start', startTimeStr),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 16),
                ),
                _buildTimeBlock('End', endTimeStr),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Duration', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(actualDuration, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  ],
                ),
              ],
            ),
          ),
          
          // Location with Map
          if (session['location'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session['location']['address'] ?? 'Unknown location',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  if (session['location']['lat'] != null && session['location']['lng'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Stack(
                        children: [
                          _SessionMapPreview(
                            lat: (session['location']['lat'] as num).toDouble(),
                            lng: (session['location']['lng'] as num).toDouble(),
                          ),
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openFullMap(
                                  context, 
                                  (session['location']['lat'] as num).toDouble(),
                                  (session['location']['lng'] as num).toDouble(),
                                  session['location']['address'] ?? 'Location'
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (session['location']['lat'] != null && session['location']['lng'] != null)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _openFullMap(
                          context, 
                          (session['location']['lat'] as num).toDouble(),
                          (session['location']['lng'] as num).toDouble(),
                          session['location']['address'] ?? 'Location'
                        ),
                        icon: const Icon(Icons.map, size: 16, color: Colors.teal),
                        label: const Text('View Full Map', style: TextStyle(color: Colors.teal)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: Colors.teal.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
          // Student Photos
          if (session['studentPhotos'] != null && (session['studentPhotos'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Student Photos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: (session['studentPhotos'] as List).length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final url = session['studentPhotos'][index];
                        return GestureDetector(
                          onTap: () => _openImage(url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Activity Description
          if (session['sessionDescription'] != null && session['sessionDescription'].toString().isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Activity Info', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    session['sessionDescription'],
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Homework & Tests
          if (session['isHomeworkProvided'] == true || session['isTestProvided'] == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  if (session['isHomeworkProvided'] == true && session['homeworkFiles'] != null)
                    _buildFileListSection('Homework', session['homeworkFiles'], Colors.blue),
                  if (session['isHomeworkProvided'] == true && session['isTestProvided'] == true)
                    const SizedBox(height: 12),
                  if (session['isTestProvided'] == true && session['testFiles'] != null)
                    _buildFileListSection('Test', session['testFiles'], Colors.purple),
                ],
              ),
            ),
            
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTimeBlock(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _buildFileListSection(String title, List<dynamic> files, MaterialColor color) {
    if (files.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(title == 'Homework' ? Icons.assignment : Icons.quiz, size: 16, color: color),
            const SizedBox(width: 4),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color.shade800)),
          ],
        ),
        const SizedBox(height: 8),
        ...files.map((fileUrl) => _buildFileRow(fileUrl.toString(), color)).toList(),
      ],
    );
  }

  Widget _buildFileRow(String url, MaterialColor color) {
    final bool isPdf = url.toLowerCase().contains('.pdf');
    final String fileName = url.split('/').last;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isPdf ? Colors.red.shade50 : Colors.teal.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: isPdf ? Colors.red.shade500 : Colors.teal.shade500, size: 18),
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ElevatedButton.icon(
          onPressed: () {
            if (isPdf) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewerPage(url: url, fileName: fileName),
                ),
              );
            } else {
              _openImage(url);
            }
          },
          icon: const Icon(Icons.visibility, size: 14),
          label: const Text('View', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.shade50,
            foregroundColor: color.shade700,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            minimumSize: const Size(0, 32),
          ),
        ),
      ),
    );
  }
  
  void _openImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(imageUrl: url),
      ),
    );
  }
  
  void _openFullMap(BuildContext context, double lat, double lng, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.map, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: _SessionMapPreview(lat: lat, lng: lng, isInteractive: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionMapPreview extends StatefulWidget {
  final double lat;
  final double lng;
  final bool isInteractive;
  const _SessionMapPreview({required this.lat, required this.lng, this.isInteractive = false});

  @override
  State<_SessionMapPreview> createState() => _SessionMapPreviewState();
}

class _SessionMapPreviewState extends State<_SessionMapPreview> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final url = 'https://maps.google.com/maps?q=${widget.lat},${widget.lng}&z=16&output=embed';
    final htmlString = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            body, html { margin: 0; padding: 0; height: 100%; width: 100%; }
            iframe { border: 0; width: 100%; height: 100%; }
          </style>
        </head>
        <body>
          <iframe src="$url" onload="window.MapLoaded.postMessage('loaded')" allowfullscreen></iframe>
        </body>
      </html>
    ''';
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadHtmlString(htmlString);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.isInteractive ? double.infinity : 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: widget.isInteractive ? BorderRadius.zero : BorderRadius.circular(8),
        border: widget.isInteractive ? null : Border.all(color: Colors.teal.shade200),
      ),
      child: ClipRRect(
        borderRadius: widget.isInteractive ? BorderRadius.zero : BorderRadius.circular(8),
        child: AbsorbPointer(
          absorbing: !widget.isInteractive,
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(color: Colors.teal);
            },
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey, size: 64),
          ),
        ),
      ),
    );
  }
}
