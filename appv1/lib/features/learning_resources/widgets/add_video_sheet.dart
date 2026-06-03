import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:appv1/features/learning_resources/services/lesson_video_service.dart';

class AddVideoSheet extends StatefulWidget {
  final Map<String, dynamic> classData;
  final VoidCallback onSuccess;
  final String teacherId;
  final String teacherName;
  final String orgId;

  const AddVideoSheet({
    super.key,
    required this.classData,
    required this.onSuccess,
    required this.teacherId,
    required this.teacherName,
    required this.orgId,
  });

  @override
  State<AddVideoSheet> createState() => _AddVideoSheetState();
}

class _AddVideoSheetState extends State<AddVideoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();

  String _videoType = 'lesson'; // 'lesson' or 'general'
  String? _selectedSubjectId;
  String? _selectedLessonId;
  String? _thumbnailPreviewUrl;
  bool _isLoading = false;

  List<dynamic> _subjects = [];
  List<dynamic> _lessons = [];

  @override
  void initState() {
    super.initState();
    _subjects = widget.classData['subjects'] as List<dynamic>? ?? [];
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final url = _urlController.text;
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      setState(() {
        _thumbnailPreviewUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      });
    } else {
      setState(() {
        _thumbnailPreviewUrl = null;
      });
    }
  }

  void _onSubjectChanged(String? subjectId) {
    setState(() {
      _selectedSubjectId = subjectId;
      _selectedLessonId = null;
      _lessons = [];

      if (subjectId != null) {
        final subject = _subjects.firstWhere(
          (s) => s['_id'] == subjectId || s['id'] == subjectId,
          orElse: () => null,
        );
        if (subject != null) {
          _lessons = subject['lessons'] as List<dynamic>? ?? [];
        }
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_videoType == 'lesson') {
      if (_selectedSubjectId == null || _selectedLessonId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both Subject and Lesson.')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final response = await LessonVideoService.addVideo(
      url: _urlController.text,
      videoType: _videoType,
      classId: widget.classData['classId'],
      subjectId: _selectedSubjectId,
      lessonId: _selectedLessonId,
      teacherId: widget.teacherId,
      teacherName: widget.teacherName,
      orgId: widget.orgId,
      title: _titleController.text,
    );

    setState(() => _isLoading = false);

    if (response['success']) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video shared successfully!'),
          backgroundColor: Color(0xFF009688),
        ),
      );
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to share video.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Video Resource',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Video Title',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF009688)),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'YouTube URL',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF009688)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'URL is required';
                  if (YoutubePlayer.convertUrlToId(val) == null) {
                    return 'Invalid YouTube URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              if (_thumbnailPreviewUrl != null) ...[
                const Text('Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _thumbnailPreviewUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              const Text('Video Type:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Radio<String>(
                    value: 'lesson',
                    groupValue: _videoType,
                    activeColor: const Color(0xFF009688),
                    onChanged: (val) => setState(() => _videoType = val!),
                  ),
                  const Text('Lesson Video'),
                  Radio<String>(
                    value: 'general',
                    groupValue: _videoType,
                    activeColor: const Color(0xFF009688),
                    onChanged: (val) => setState(() => _videoType = val!),
                  ),
                  const Text('General Video'),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_videoType == 'lesson') ...[
                DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Select Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: _subjects.map((s) {
                    return DropdownMenuItem<String>(
                      value: s['_id'] ?? s['id'],
                      child: Text(s['name'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: _onSubjectChanged,
                  validator: (val) =>
                      val == null ? 'Subject is required for lesson videos' : null,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _selectedLessonId,
                  decoration: const InputDecoration(
                    labelText: 'Select Lesson',
                    border: OutlineInputBorder(),
                  ),
                  items: _lessons.map((l) {
                    return DropdownMenuItem<String>(
                      value: l['_id'] ?? l['id'],
                      child: Text(l['name'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedLessonId = val),
                  validator: (val) =>
                      val == null ? 'Lesson is required for lesson videos' : null,
                ),
                const SizedBox(height: 16),
              ],
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Share Video',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
