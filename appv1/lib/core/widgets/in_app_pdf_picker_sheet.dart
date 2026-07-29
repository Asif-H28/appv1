import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../services/pending_document_upload_service.dart';
import 'in_app_media_picker_sheet.dart';

class InAppPdfPickerSheet extends StatefulWidget {
  const InAppPdfPickerSheet({Key? key}) : super(key: key);

  static Future<PickedMediaFile?> show(BuildContext context) async {
    return showModalBottomSheet<PickedMediaFile?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const InAppPdfPickerSheet(),
    );
  }

  @override
  State<InAppPdfPickerSheet> createState() => _InAppPdfPickerSheetState();
}

class _InAppPdfPickerSheetState extends State<InAppPdfPickerSheet> {
  bool _isLoading = true;
  List<FileSystemEntity> _pdfFiles = [];
  List<FileSystemEntity> _filteredFiles = [];
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Pagination & Performance Optimizations ──
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  int _displayedCount = _pageSize;
  final Map<String, Map<String, dynamic>> _fileStatCache = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _scanPdfFiles();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (_displayedCount < _filteredFiles.length) {
        setState(() {
          _displayedCount = (_displayedCount + _pageSize).clamp(0, _filteredFiles.length);
        });
      }
    }
  }

  Future<void> _scanPdfFiles() async {
    if (kIsWeb) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      if (Platform.isAndroid) {
        if (!await Permission.storage.isGranted) {
          await Permission.storage.request();
        }
      }
    } catch (_) {}

    final Set<String> foundPaths = {};
    final List<FileSystemEntity> pdfs = [];

    try {
      final List<Directory> dirsToScan = [];

      try {
        final docsDir = await getApplicationDocumentsDirectory();
        dirsToScan.add(docsDir);
      } catch (_) {}

      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) dirsToScan.add(downloadsDir);
      } catch (_) {}

      if (Platform.isAndroid) {
        final List<String> androidPaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Documents',
          '/storage/emulated/0/Download/Telegram',
          '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
          '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents',
        ];
        for (var p in androidPaths) {
          final dir = Directory(p);
          if (dir.existsSync()) dirsToScan.add(dir);
        }
      }

      for (var dir in dirsToScan) {
        if (!dir.existsSync()) continue;
        try {
          final entities = dir.listSync(recursive: true, followLinks: false);
          for (var entity in entities) {
            if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
              if (!foundPaths.contains(entity.path)) {
                foundPaths.add(entity.path);
                pdfs.add(entity);
              }
            }
          }
        } catch (_) {
          try {
            final entities = dir.listSync(recursive: false, followLinks: false);
            for (var entity in entities) {
              if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
                if (!foundPaths.contains(entity.path)) {
                  foundPaths.add(entity.path);
                  pdfs.add(entity);
                }
              }
            }
          } catch (_) {}
        }
      }

      // Quick sort by path without heavy statSync upfront
      pdfs.sort((a, b) => a.path.compareTo(b.path));
    } catch (_) {}

    if (mounted) {
      setState(() {
        _pdfFiles = pdfs;
        _filteredFiles = pdfs;
        _displayedCount = _pageSize.clamp(0, pdfs.length);
        _isLoading = false;
      });
    }
  }

  void _filterFiles(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredFiles = _pdfFiles;
        _displayedCount = _pageSize.clamp(0, _pdfFiles.length);
      });
      return;
    }
    final q = query.toLowerCase();
    final filtered = _pdfFiles.where((f) => f.path.split(Platform.pathSeparator).last.toLowerCase().contains(q)).toList();
    setState(() {
      _filteredFiles = filtered;
      _displayedCount = _pageSize.clamp(0, filtered.length);
    });
  }

  Future<void> _selectSystemFilePicker() async {
    try {
      // Note: the caller (EndTutorSessionSheet) already marks the pending
      // upload with the full context (sessionId/orgId/forHomework) before
      // opening this sheet — don't overwrite it with a bare flag here, or
      // that context is lost right before the risky external Activity launch.

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty || !mounted) {
        await PendingDocumentUploadService.clearPending();
        return;
      }

      final file = result.files.single;
      List<int>? bytes = file.bytes;
      if (bytes == null && !kIsWeb && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      Navigator.pop(
        context,
        PickedMediaFile(
          path: file.path,
          name: file.name,
          bytes: bytes,
          isPdf: true,
        ),
      );
    } catch (e) {
      await PendingDocumentUploadService.clearPending();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectLocalFile(File file) async {
    try {
      final name = file.path.split(Platform.pathSeparator).last;
      final bytes = await file.readAsBytes();
      if (mounted) {
        Navigator.pop(
          context,
          PickedMediaFile(
            path: file.path,
            name: name,
            bytes: bytes,
            isPdf: true,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Map<String, dynamic> _getFileStats(File file) {
    if (_fileStatCache.containsKey(file.path)) {
      return _fileStatCache[file.path]!;
    }
    int sizeBytes = 0;
    DateTime? modified;
    try {
      final stat = file.statSync();
      sizeBytes = stat.size;
      modified = stat.modified;
    } catch (_) {}

    final result = {
      'size': sizeBytes,
      'modified': modified,
    };
    _fileStatCache[file.path] = result;
    return result;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final totalCount = _filteredFiles.length;
    final renderCount = _displayedCount.clamp(0, totalCount);

    return Container(
      height: size.height * 0.85,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select PDF Document',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        'Choose PDF file to attach',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary Browse Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectSystemFilePicker,
              icon: const Icon(Icons.folder_open_rounded, size: 20),
              label: const Text(
                'Choose PDF from Phone',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          TextField(
            controller: _searchCtrl,
            onChanged: _filterFiles,
            decoration: InputDecoration(
              hintText: 'Search scanned documents...',
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.teal),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // PDF File List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Scanned PDFs ($totalCount)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.teal),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _scanPdfFiles();
                },
              ),
            ],
          ),
          const SizedBox(height: 4),

          // PDF File List (Paginated Infinite Scroll)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : _filteredFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, color: Colors.grey[400], size: 52),
                            const SizedBox(height: 12),
                            const Text(
                              'Tap "Choose PDF from Phone" above to pick any PDF file.',
                              style: TextStyle(color: Colors.black54, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        itemCount: renderCount < totalCount ? renderCount + 1 : renderCount,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == renderCount) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Loading more PDFs...',
                                      style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final file = _filteredFiles[index] as File;
                          final fileName = file.path.split(Platform.pathSeparator).last;
                          final stats = _getFileStats(file);
                          final sizeBytes = stats['size'] as int? ?? 0;
                          final modified = stats['modified'] as DateTime?;

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
                            ),
                            title: Text(
                              fileName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${_formatBytes(sizeBytes)} ${modified != null ? "• ${modified.day}/${modified.month}/${modified.year}" : ""}',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                            onTap: () => _selectLocalFile(file),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
