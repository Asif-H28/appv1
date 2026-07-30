import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/network/dio_http_adapter.dart' as http;
import '../../../../core/network/upload_part.dart';
import '../../../../core/widgets/in_app_camera_sheet.dart';
import '../../../../core/widgets/in_app_media_picker_sheet.dart';
import '../../../../core/services/pending_document_upload_service.dart';
import '../../../../core/services/document_picker_service.dart';
import 'pdf_viewer_page.dart';

class EndTutorSessionSheet extends StatefulWidget {
  final String sessionId;
  final String orgId;

  const EndTutorSessionSheet({
    Key? key,
    required this.sessionId,
    required this.orgId,
  }) : super(key: key);

  @override
  _EndTutorSessionSheetState createState() => _EndTutorSessionSheetState();
}

class _EndTutorSessionSheetState extends State<EndTutorSessionSheet> {
  final _descriptionCtrl = TextEditingController();
  bool _isHomeworkProvided = false;
  bool _isTestProvided = false;

  final List<Map<String, String>> _homeworkFiles = [];
  final List<Map<String, String>> _testFiles = [];

  bool _isSubmitting = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _collectParkedPick();
  }

  /// If Android tore us down while the file manager was open, the pick was
  /// written to disk natively and is waiting. Pick it up and upload it, so the
  /// teacher doesn't have to choose the same file twice.
  Future<void> _collectParkedPick() async {
    final file = await DocumentPickerService.consumePending();
    if (file == null || !mounted) return;

    final pending = await PendingDocumentUploadService.getPendingData();
    final forHomework = pending?['extra']?['forHomework'] as bool? ?? true;
    if (!mounted) return;

    setState(() => _isHomeworkProvided = _isHomeworkProvided || forHomework);
    await _uploadPicked(file, forHomework);
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _uploadFile(bool forHomework, {bool isCamera = false}) async {
    try {
      await PendingDocumentUploadService.markPendingUpload(
        targetScreen: 'TUTOR_SESSION',
        extraData: {
          'sessionId': widget.sessionId,
          'orgId': widget.orgId,
          'forHomework': forHomework,
        },
      );

      final PickedMediaFile? file = isCamera
          ? (await () async {
              final image = await InAppCameraSheet.show(context);
              if (image == null) return null;
              final b = await image.readAsBytes();
              return PickedMediaFile(path: image.path, name: image.name, bytes: b, isPdf: false);
            }())
          : await InAppMediaPickerSheet.show(context);

      if (file == null) {
        await PendingDocumentUploadService.clearPending();
        return;
      }

      await _uploadPicked(file, forHomework);
    } catch (e) {
      _showSnackBar('Error uploading: $e', isError: true);
    } finally {
      await PendingDocumentUploadService.clearPending();
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadPicked(PickedMediaFile file, bool forHomework) async {
    try {
      setState(() => _isUploading = true);

      final endpoint = file.isPdf ? '/upload/pdf' : '/upload/image';
      final url = '${ApiConstants.apiBaseUrl}$endpoint';

      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Always send bytes: MultipartFile.fromPath needs dart:io and throws on
      // web, which is where the PWA runs.
      final bytes = file.bytes;
      if (bytes == null) return;
      request.files.add(buildUploadPart(
        'file',
        bytes,
        name: file.name,
        isPdf: file.isPdf,
      ));
      
      final headers = await ApiService.getHeaders();
      request.headers.addAll(headers);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final fileUrl = body['file']['url'].toString();
        
        setState(() {
          if (forHomework) {
            _homeworkFiles.add({'url': fileUrl, 'name': file.name});
          } else {
            _testFiles.add({'url': fileUrl, 'name': file.name});
          }
        });
      } else {
        _showSnackBar('Upload failed: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error uploading: $e', isError: true);
    } finally {
      await PendingDocumentUploadService.clearPending();
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submit() async {
    if (_descriptionCtrl.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Warning'),
            ],
          ),
          content: const Text('Please provide a session description before ending the activity.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        "sessionDescription": _descriptionCtrl.text.trim(),
        "isHomeworkProvided": _isHomeworkProvided,
        "homeworkFiles": _homeworkFiles.map((f) => f['url']).toList(),
        "isTestProvided": _isTestProvided,
        "testFiles": _testFiles.map((f) => f['url']).toList(),
        "sessionEndedTime": DateTime.now().toUtc().toIso8601String(),
      };

      final response = await ApiService.put(
        '/tutor-sessions/${widget.sessionId}',
        headers: {'x-org-id': widget.orgId},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Session completed successfully');
        if (mounted) Navigator.pop(context, true);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to update session';
        _showSnackBar(error, isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
  
  void _viewFile(String url, String name) {
    final isPdf = url.toLowerCase().endsWith('.pdf') || name.toLowerCase().endsWith('.pdf');
    if (isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(
            url: url.startsWith('http') ? url : null,
            filePath: !url.startsWith('http') ? url : null,
            fileName: name,
          ),
        ),
      );
    } else {
      // Basic image viewer
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

  Widget _buildFileList(List<Map<String, String>> files, bool forHomework) {
    if (files.isEmpty) return const SizedBox.shrink();
    return Column(
      children: files.asMap().entries.map((entry) {
        final idx = entry.key;
        final f = entry.value;
        final isPdf = f['url']!.toLowerCase().endsWith('.pdf');
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: isPdf ? Colors.red : Colors.blue),
          title: Text(f['name']!, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                if (forHomework) {
                  _homeworkFiles.removeAt(idx);
                } else {
                  _testFiles.removeAt(idx);
                }
              });
            },
          ),
          onTap: () => _viewFile(f['url']!, f['name']!),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
            const Text(
              'End Session Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            if (_isUploading) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(color: Colors.teal, backgroundColor: Color(0xFFE0F2F1)),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Uploading document, please wait...',
                  style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Session Description', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'What was covered today?',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            
            // Homework Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Homework Provided', style: TextStyle(fontWeight: FontWeight.bold)),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    activeColor: Colors.teal,
                    value: _isHomeworkProvided,
                    onChanged: (val) => setState(() => _isHomeworkProvided = val),
                  ),
                ),
              ],
            ),
            if (_isHomeworkProvided) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : () => _uploadFile(true, isCamera: true),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Photo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : () => _uploadFile(true, isCamera: false),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('PDF / Gallery'),
                    ),
                  ),
                ],
              ),
              _buildFileList(_homeworkFiles, true),
            ],
            const Divider(height: 32),

            // Test Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Test Provided', style: TextStyle(fontWeight: FontWeight.bold)),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    activeColor: Colors.teal,
                    value: _isTestProvided,
                    onChanged: (val) => setState(() => _isTestProvided = val),
                  ),
                ),
              ],
            ),
            if (_isTestProvided) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : () => _uploadFile(false, isCamera: true),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Photo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : () => _uploadFile(false, isCamera: false),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('PDF / Gallery'),
                    ),
                  ),
                ],
              ),
              _buildFileList(_testFiles, false),
            ],
            
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: Colors.teal)),
              ),
              
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('End Session'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
