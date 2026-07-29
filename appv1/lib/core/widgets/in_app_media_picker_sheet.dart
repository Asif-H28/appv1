import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PickedMediaFile {
  final String? path;
  final String name;
  final List<int>? bytes;
  final bool isPdf;

  PickedMediaFile({
    this.path,
    required this.name,
    this.bytes,
    required this.isPdf,
  });
}

enum MediaPickerMode { camera, gallery, document }

class InAppMediaPickerSheet extends StatelessWidget {
  final List<String> allowedExtensions;

  const InAppMediaPickerSheet({
    Key? key,
    this.allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
  }) : super(key: key);

  static Future<PickedMediaFile?> show(
    BuildContext context, {
    List<String> allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
  }) async {
    return showModalBottomSheet<PickedMediaFile?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => InAppMediaPickerSheet(allowedExtensions: allowedExtensions),
    );
  }

  Future<void> _handleGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image == null || !context.mounted) return;

      final bytes = await image.readAsBytes();
      Navigator.pop(
        context,
        PickedMediaFile(
          path: image.path,
          name: image.name,
          bytes: bytes,
          isPdf: false,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Opens the system file manager (SAF). This needs no storage permission and
  /// reaches cloud providers too. It does hand control to another Activity —
  /// safe because MainActivity now keeps its FlutterEngine cached, so coming
  /// back reattaches to the running isolate instead of restarting the app.
  Future<void> _handleDocument(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty || !context.mounted) return;

      final file = result.files.single;
      List<int>? bytes = file.bytes;
      if (bytes == null && !kIsWeb && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (!context.mounted) return;

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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.attach_file_rounded, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attach Attachment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      'Choose photo or document to attach',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Option 1: Gallery Photos
            _buildOptionTile(
              context,
              icon: Icons.photo_library_rounded,
              color: Colors.blue,
              title: 'Photos & Gallery',
              subtitle: 'Select an existing image from photo library',
              onTap: () => _handleGallery(context),
            ),
            const SizedBox(height: 12),

            // Option 3: PDF / Documents
            _buildOptionTile(
              context,
              icon: Icons.picture_as_pdf_rounded,
              color: Colors.deepOrange,
              title: 'PDF & Documents',
              subtitle: 'Upload PDF files or study materials',
              onTap: () => _handleDocument(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
