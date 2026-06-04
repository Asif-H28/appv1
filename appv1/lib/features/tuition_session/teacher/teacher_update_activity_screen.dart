import 'package:flutter/material.dart';
import 'package:appv1/features/tuition_session/services/tuition_session_service.dart';
import 'package:appv1/features/tuition_session/widgets/activity_file_picker.dart';

class TeacherUpdateActivityScreen extends StatefulWidget {
  final String sessionId;

  const TeacherUpdateActivityScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<TeacherUpdateActivityScreen> createState() => _TeacherUpdateActivityScreenState();
}

class _TeacherUpdateActivityScreenState extends State<TeacherUpdateActivityScreen> {
  final _descriptionController = TextEditingController();
  
  bool _homeworkProvided = false;
  bool _studentCompletedHomework = false;
  bool _testGiven = false;

  List<String> _homeworkProvidedFiles = [];
  List<String> _studentCompletedHomeworkFiles = [];
  List<String> _testGivenFiles = [];
  List<String> _additionalFiles = [];

  bool _isSaving = false;

  void _saveActivity() async {
    setState(() => _isSaving = true);
    final res = await TuitionSessionService.updateActivity(
      sessionId: widget.sessionId,
      description: _descriptionController.text.trim(),
      homeworkProvided: _homeworkProvided,
      studentCompletedHomework: _studentCompletedHomework,
      testGiven: _testGiven,
      homeworkProvidedFiles: _homeworkProvidedFiles.isNotEmpty ? _homeworkProvidedFiles : null,
      studentCompletedHomeworkFiles: _studentCompletedHomeworkFiles.isNotEmpty ? _studentCompletedHomeworkFiles : null,
      testGivenFiles: _testGivenFiles.isNotEmpty ? _testGivenFiles : null,
      additionalFiles: _additionalFiles.isNotEmpty ? _additionalFiles : null,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity updated successfully!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Activity', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF009688),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Session Description / Notes',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF009688)),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Homework Provided', style: TextStyle(fontWeight: FontWeight.bold)),
              value: _homeworkProvided,
              activeColor: const Color(0xFF009688),
              onChanged: (val) => setState(() => _homeworkProvided = val),
            ),
            if (_homeworkProvided)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: ActivityFilePicker(
                  label: 'Homework Files',
                  onFilesChanged: (paths) => setState(() => _homeworkProvidedFiles = paths),
                ),
              ),
            const Divider(),
            SwitchListTile(
              title: const Text('Student Completed Previous Homework', style: TextStyle(fontWeight: FontWeight.bold)),
              value: _studentCompletedHomework,
              activeColor: const Color(0xFF009688),
              onChanged: (val) => setState(() => _studentCompletedHomework = val),
            ),
            if (_studentCompletedHomework)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: ActivityFilePicker(
                  label: 'Completed Homework Files',
                  onFilesChanged: (paths) => setState(() => _studentCompletedHomeworkFiles = paths),
                ),
              ),
            const Divider(),
            SwitchListTile(
              title: const Text('Test Given', style: TextStyle(fontWeight: FontWeight.bold)),
              value: _testGiven,
              activeColor: const Color(0xFF009688),
              onChanged: (val) => setState(() => _testGiven = val),
            ),
            if (_testGiven)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: ActivityFilePicker(
                  label: 'Test Files',
                  onFilesChanged: (paths) => setState(() => _testGivenFiles = paths),
                ),
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ActivityFilePicker(
                label: 'Additional Attachments',
                onFilesChanged: (paths) => setState(() => _additionalFiles = paths),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              ),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Activity', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
