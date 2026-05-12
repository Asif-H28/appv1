import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import 'result_review_screen.dart';

class QuizAttemptScreen extends StatefulWidget {
  final String quizId;

  const QuizAttemptScreen({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizAttemptScreenState createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> {
  Map<String, dynamic>? _quiz;
  bool _isLoading = true;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  
  List<Map<String, dynamic>> _answers = [];
  String? _selectedOption;
  bool _isAnswered = false;

  Timer? _timer;
  int _secondsRemaining = 0;
  int _totalDurationSeconds = 0;

  String _studentId = '';
  String _studentName = '';
  String _classId = '';
  String _orgId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentId = prefs.getString('studentId') ?? '';
      _studentName = prefs.getString('studentName') ?? '';
      _classId = prefs.getString('classId') ?? '';
      _orgId = prefs.getString('orgId') ?? '';
    });
  }

  Future<void> _fetchQuiz() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConstants.apiBaseUrl}/quiz/${widget.quizId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final quizData = data['quiz'] ?? data['data'] ?? data;
        setState(() {
          _quiz = quizData;
          _isLoading = false;
          _secondsRemaining = (quizData['durationMinutes'] ?? 15) * 60;
          _totalDurationSeconds = _secondsRemaining;
        });
        _startTimer();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _submitQuiz(autoSubmit: true);
      }
    });
  }

  String _formatTime(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onOptionSelected(String option) {
    if (_isAnswered) return;
    setState(() {
      _selectedOption = option;
      _isAnswered = true;
    });
  }

  void _nextQuestion() {
    _answers.add({
      'questionIndex': _currentIndex,
      'selectedAnswer': _selectedOption,
    });

    if (_currentIndex < (_quiz!['questions'] as List).length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswered = false;
      });
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _showSubmitConfirmation();
    }
  }

  Future<void> _showSubmitConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: const Text('Are you sure you want to submit your answers?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Review')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz({bool autoSubmit = false}) async {
    // If auto-submit and we haven't added the current answer
    if (autoSubmit && _answers.length <= _currentIndex) {
      _answers.add({
        'questionIndex': _currentIndex,
        'selectedAnswer': _selectedOption,
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.teal)),
    );

    try {
      final timeTakenSeconds = _totalDurationSeconds - _secondsRemaining;
      final body = {
        'quizId': widget.quizId,
        'studentId': _studentId,
        'studentName': _studentName,
        'classId': _classId,
        'orgId': _orgId,
        'answers': _answers,
        'timeTakenSeconds': timeTakenSeconds,
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/quiz/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultReviewScreen(
              reviewData: result,
              quizId: widget.quizId,
              studentId: _studentId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit quiz')));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.teal)));
    }

    final questions = (_quiz!['questions'] as List?) ?? [];
    if (questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('No questions found for this quiz')));
    }
    final question = questions[_currentIndex];
    final options = (question['options'] as List?) ?? [];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot go back during quiz')),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_quiz!['title'] ?? 'Quiz', style: const TextStyle(color: Colors.white, fontSize: 16)),
          backgroundColor: Colors.teal,
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _secondsRemaining < 30 ? Colors.red : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / questions.length,
              backgroundColor: Colors.grey[200],
              color: Colors.teal,
              minHeight: 6,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    "Question ${_currentIndex + 1} of ${questions.length}",
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          question['questionText'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                        ),
                        const SizedBox(height: 40),
                        ...options.map((opt) => _buildOptionButton(opt)).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_isAnswered)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                      child: Text(
                        _currentIndex == questions.length - 1 ? "Submit Quiz" : "Next Question",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option) {
    final bool isSelected = _selectedOption == option;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _onOptionSelected(option),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isSelected ? Colors.teal : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? Colors.teal : Colors.grey[400]!, width: 2),
                  color: isSelected ? Colors.teal : Colors.transparent,
                ),
                child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected ? Colors.teal : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
