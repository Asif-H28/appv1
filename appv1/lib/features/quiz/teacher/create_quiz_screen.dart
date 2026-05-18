import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class CreateQuizScreen extends StatefulWidget {
  final String? preSelectedClassId;
  final String? preSelectedClassName;
  final List<dynamic>? subjects;

  const CreateQuizScreen({
    Key? key,
    this.preSelectedClassId,
    this.preSelectedClassName,
    this.subjects,
  }) : super(key: key);

  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  String? _selectedSubject;
  String? _selectedLessonName;
  String? _selectedLessonId;
  List<Map<String, dynamic>> _availableLessons = [];

  int _totalQuestions = 10;
  String _difficulty = 'medium';
  int _durationMinutes = 15;

  String _orgId = '';
  String _classId = '';
  String _teacherId = '';
  String _teacherName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (widget.preSelectedClassId != null) {
      _classId = widget.preSelectedClassId!;
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orgId = prefs.getString('orgId') ?? '';
      if (_classId.isEmpty) {
        _classId = prefs.getString('classId') ?? '';
      }
      _teacherId = prefs.getString('teacherId') ?? '';
      _teacherName = prefs.getString('teacherName') ?? '';
    });
  }

  void _onSubjectChanged(String? value) {
    setState(() {
      _selectedSubject = value;
      _selectedLessonName = null;
      _selectedLessonId = null;
      _availableLessons = [];
      if (value != null && widget.subjects != null) {
        final subjectData = widget.subjects!.firstWhere(
          (s) => s['name'] == value,
          orElse: () => null,
        );
        if (subjectData != null && subjectData['lessons'] != null) {
          _availableLessons = (subjectData['lessons'] as List)
              .map((l) => {
                    'name': l['name'].toString(),
                    'id': l['_id']?.toString() ?? '',
                  })
              .toList();
        }
      }
    });
  }

  Future<void> _submitQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null || _selectedLessonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject and lesson')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.teal),
            const SizedBox(width: 20),
            const Expanded(child: Text("Generating questions with AI...")),
          ],
        ),
      ),
    );

    try {
      final body = {
        'orgId': _orgId,
        'classId': _classId,
        'teacherId': _teacherId,
        'teacherName': _teacherName,
        'subject': _selectedSubject,
        'lessonName': _selectedLessonName,
        'lessonId': _selectedLessonId,
        'title': _titleController.text,
        'totalQuestions': _totalQuestions,
        'difficulty': _difficulty.toLowerCase(),
        'durationMinutes': _durationMinutes,
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/quiz/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz created successfully!'), backgroundColor: Colors.teal),
        );
        Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);
        final errorMessage = data['error'] ?? data['message'] ?? 'Failed to create quiz';

        if (errorMessage.toString().contains("Limit reached")) {
          _showLimitReachedDialog(errorMessage.toString());
        } else if (errorMessage == "Lesson has not been marked as completed yet") {
          _showErrorBanner(errorMessage);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showLimitReachedDialog(String message) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Limit reached', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showErrorBanner(String message) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectsList = widget.subjects ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Create New Quiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.preSelectedClassName != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.class_rounded, color: Colors.teal, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Class: ${widget.preSelectedClassName}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                ),
              _buildLabel('Quiz Title'),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Enter quiz title (e.g. Weekly Maths Test)'),
                validator: (v) => v!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              _buildLabel('Subject'),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedSubject,
                hint: const Text('Select Subject'),
                items: subjectsList.map((s) => DropdownMenuItem<String>(
                  value: s['name'].toString(),
                  child: Text(s['name'].toString()),
                )).toList(),
                onChanged: _onSubjectChanged,
                decoration: _inputDecoration(''),
                validator: (v) => v == null ? 'Subject is required' : null,
              ),
              const SizedBox(height: 16),
              _buildLabel('Lesson Name'),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedLessonId,
                hint: const Text('Select Lesson'),
                items: _availableLessons.map((l) => DropdownMenuItem<String>(
                  value: l['id'].toString(),
                  child: Text(
                    l['name'].toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedLessonId = v;
                    _selectedLessonName = _availableLessons.firstWhere((l) => l['id'] == v)['name'];
                  });
                },
                decoration: _inputDecoration(''),
                validator: (v) => v == null ? 'Lesson is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Total Questions'),
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _totalQuestions,
                          items: [5, 10, 15, 20].map((e) => DropdownMenuItem(value: e, child: Text('$e Questions'))).toList(),
                          onChanged: (v) => setState(() => _totalQuestions = v!),
                          decoration: _inputDecoration(''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Difficulty'),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _difficulty,
                          items: ['Easy', 'Medium', 'Hard'].map((e) => DropdownMenuItem(value: e.toLowerCase(), child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _difficulty = v!),
                          decoration: _inputDecoration(''),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLabel('Duration (Minutes)'),
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: _durationMinutes,
                items: [10, 15, 20, 30].map((e) => DropdownMenuItem(value: e, child: Text('$e Minutes'))).toList(),
                onChanged: (v) => setState(() => _durationMinutes = v!),
                decoration: _inputDecoration(''),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    elevation: 0,
                  ),
                  child: const Text('Generate Quiz with AI', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: const BorderSide(color: Colors.teal, width: 1.5)),
    );
  }
}
