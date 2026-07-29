import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/storage_access_service.dart';
import 'in_app_media_picker_sheet.dart';

/// One PDF found on the device. Plain data so it can be sent back from the
/// scanning isolate.
class _PdfEntry {
  final String path;
  final int size;
  final int modifiedMs;

  const _PdfEntry(this.path, this.size, this.modifiedMs);

  String get name => path.split(Platform.pathSeparator).last;
}

/// Directory names we never descend into — app sandboxes, caches and thumbnail
/// stores hold thousands of files and no user-visible documents.
const Set<String> _skipDirNames = {
  'Android',
  '.thumbnails',
  '.trash',
  '.trashed',
  'cache',
  'Cache',
  'LOST.DIR',
};

/// Recursively walks [roots] looking for PDFs. Runs inside an isolate — a full
/// sweep of shared storage takes long enough to drop frames on the UI thread.
List<_PdfEntry> _scanRootsSync(List<String> roots) {
  final found = <String, _PdfEntry>{};
  final queue = <Directory>[];
  final visited = <String>{};

  for (final r in roots) {
    final d = Directory(r);
    if (d.existsSync()) queue.add(d);
  }

  // Bounded so a symlink cycle or an enormous tree can't spin forever.
  var dirsWalked = 0;
  const maxDirs = 4000;

  while (queue.isNotEmpty && dirsWalked < maxDirs) {
    final dir = queue.removeAt(0);

    String resolved;
    try {
      resolved = dir.resolveSymbolicLinksSync();
    } catch (_) {
      continue;
    }
    if (!visited.add(resolved)) continue;
    dirsWalked++;

    List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } catch (_) {
      // Unreadable directory (no permission / vanished) — skip it, keep going.
      continue;
    }

    for (final entity in entries) {
      final name = entity.path.split(Platform.pathSeparator).last;
      if (name.startsWith('.')) continue;

      if (entity is Directory) {
        if (_skipDirNames.contains(name)) continue;
        queue.add(entity);
      } else if (entity is File && name.toLowerCase().endsWith('.pdf')) {
        if (found.containsKey(entity.path)) continue;
        try {
          final stat = entity.statSync();
          found[entity.path] = _PdfEntry(
            entity.path,
            stat.size,
            stat.modified.millisecondsSinceEpoch,
          );
        } catch (_) {
          found[entity.path] = _PdfEntry(entity.path, 0, 0);
        }
      }
    }
  }

  final list = found.values.toList();
  // Newest first — the document a teacher just received is the one they want.
  list.sort((a, b) => b.modifiedMs.compareTo(a.modifiedMs));
  return list;
}

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
  bool _needsPermission = false;
  List<_PdfEntry> _pdfFiles = [];
  List<_PdfEntry> _filteredFiles = [];
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Pagination ──
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  int _displayedCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (_displayedCount < _filteredFiles.length) {
        setState(() {
          _displayedCount =
              (_displayedCount + _pageSize).clamp(0, _filteredFiles.length);
        });
      }
    }
  }

  Future<void> _requestStorageAccess() async {
    await StorageAccessService.request();
    await _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _needsPermission = false;
      });
    }

    if (kIsWeb) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (!await StorageAccessService.hasAccess()) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _needsPermission = true;
        });
      }
      return;
    }

    final roots = await _collectRoots();
    final pdfs = await Isolate.run(() => _scanRootsSync(roots));

    if (mounted) {
      setState(() {
        _pdfFiles = pdfs;
        _filteredFiles = pdfs;
        _displayedCount = _pageSize.clamp(0, pdfs.length);
        _isLoading = false;
      });
    }
  }

  /// Where to start walking from. On Android with all-files access the whole
  /// shared volume is readable, so one root covers Downloads, Documents,
  /// WhatsApp, Telegram and anywhere else a PDF might land.
  Future<List<String>> _collectRoots() async {
    final roots = <String>[];

    if (Platform.isAndroid) {
      const sharedRoot = '/storage/emulated/0';
      if (Directory(sharedRoot).existsSync()) {
        roots.add(sharedRoot);
      }
      // WhatsApp moved its media under Android/media, which the shared-root
      // walk deliberately skips — add the document folder back explicitly.
      const whatsApp =
          '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents';
      if (Directory(whatsApp).existsSync()) roots.add(whatsApp);
    }

    // Always include our own sandbox — files the app itself downloaded.
    try {
      roots.add((await getApplicationDocumentsDirectory()).path);
    } catch (_) {}
    try {
      final d = await getDownloadsDirectory();
      if (d != null) roots.add(d.path);
    } catch (_) {}

    return roots;
  }

  void _filterFiles(String query) {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _pdfFiles
        : _pdfFiles.where((f) => f.name.toLowerCase().contains(q)).toList();
    setState(() {
      _filteredFiles = filtered;
      _displayedCount = _pageSize.clamp(0, filtered.length);
    });
  }

  /// Fallback only — this launches the external file manager, which is what
  /// caused the app to be killed and relaunched mid-session. Reachable just
  /// when all-files access is refused.
  Future<void> _selectSystemFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty || !mounted) return;

      final file = result.files.single;
      List<int>? bytes = file.bytes;
      if (bytes == null && !kIsWeb && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (!mounted) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectLocalFile(_PdfEntry entry) async {
    try {
      final bytes = await File(entry.path).readAsBytes();
      if (mounted) {
        Navigator.pop(
          context,
          PickedMediaFile(
            path: entry.path,
            name: entry.name,
            bytes: bytes,
            isPdf: true,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _folderLabel(String path) {
    final parts = path.split(Platform.pathSeparator);
    if (parts.length < 2) return '';
    return parts[parts.length - 2];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select PDF Document',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
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

          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_needsPermission) return _buildPermissionPrompt();
    if (_isLoading) return _buildScanning();

    final totalCount = _filteredFiles.length;
    final renderCount = _displayedCount.clamp(0, totalCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        TextField(
          controller: _searchCtrl,
          onChanged: _filterFiles,
          decoration: InputDecoration(
            hintText: 'Search your documents...',
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.teal),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Documents on this device ($totalCount)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700]),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  size: 20, color: Colors.teal),
              onPressed: _load,
            ),
          ],
        ),
        const SizedBox(height: 4),

        Expanded(
          child: _filteredFiles.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  controller: _scrollController,
                  itemCount:
                      renderCount < totalCount ? renderCount + 1 : renderCount,
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
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.teal),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading more PDFs...',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.teal,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final entry = _filteredFiles[index];
                    final modified = entry.modifiedMs > 0
                        ? DateTime.fromMillisecondsSinceEpoch(entry.modifiedMs)
                        : null;
                    final folder = _folderLabel(entry.path);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.red, size: 24),
                      ),
                      title: Text(
                        entry.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_formatBytes(entry.size)}'
                        '${folder.isNotEmpty ? " • $folder" : ""}'
                        '${modified != null ? " • ${modified.day}/${modified.month}/${modified.year}" : ""}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: Colors.grey),
                      onTap: () => _selectLocalFile(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScanning() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.teal),
          SizedBox(height: 16),
          Text(
            'Finding documents on your device...',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_outlined, color: Colors.grey[400], size: 52),
          const SizedBox(height: 12),
          const Text(
            'No PDF files found on this device.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _selectSystemFilePicker,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: const Text('Browse with file manager'),
            style: TextButton.styleFrom(foregroundColor: Colors.teal),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_shared_rounded,
                  color: Colors.teal, size: 34),
            ),
            const SizedBox(height: 18),
            const Text(
              'Allow access to your documents',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Grant file access so you can pick homework PDFs right here, '
              'without leaving the app and losing your session.',
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requestStorageAccess,
                icon: const Icon(Icons.lock_open_rounded, size: 20),
                label: const Text(
                  'Allow file access',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _selectSystemFilePicker,
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              child: const Text('Use system file manager instead'),
            ),
          ],
        ),
      ),
    );
  }
}
