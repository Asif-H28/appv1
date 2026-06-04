import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class ActivityFilePicker extends StatefulWidget {
  final String label;
  final Function(List<String> paths) onFilesChanged;

  const ActivityFilePicker({
    Key? key,
    required this.label,
    required this.onFilesChanged,
  }) : super(key: key);

  @override
  State<ActivityFilePicker> createState() => _ActivityFilePickerState();
}

class _ActivityFilePickerState extends State<ActivityFilePicker> {
  final List<String> _filePaths = [];
  final ImagePicker _picker = ImagePicker();

  void _pickFiles() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF009688)),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() => _filePaths.add(picked.path));
                    widget.onFilesChanged(_filePaths);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF009688)),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickMultiImage();
                  if (picked.isNotEmpty) {
                    setState(() => _filePaths.addAll(picked.map((e) => e.path)));
                    widget.onFilesChanged(_filePaths);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Color(0xFF009688)),
                title: const Text('Choose Files (PDF)'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
                  );
                  if (result != null) {
                    setState(() {
                      _filePaths.addAll(result.paths.whereType<String>());
                    });
                    widget.onFilesChanged(_filePaths);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeFile(int index) {
    setState(() {
      _filePaths.removeAt(index);
    });
    widget.onFilesChanged(_filePaths);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            TextButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.attach_file, size: 16, color: Color(0xFF009688)),
              label: const Text('Add File', style: TextStyle(color: Color(0xFF009688))),
            )
          ],
        ),
        if (_filePaths.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(3),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filePaths.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final path = _filePaths[index];
                final isImage = ['jpg', 'jpeg', 'png'].contains(p.extension(path).toLowerCase().replaceAll('.', ''));
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: isImage
                      ? Image.file(File(path), width: 40, height: 40, fit: BoxFit.cover)
                      : const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 40),
                  title: Text(p.basename(path), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _removeFile(index),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
