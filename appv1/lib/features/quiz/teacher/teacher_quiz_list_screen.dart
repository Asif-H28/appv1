import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../widgets/difficulty_badge.dart';
import 'create_quiz_screen.dart';
import 'quiz_results_screen.dart';

class TeacherQuizListScreen extends StatefulWidget {
  final String? classId;
  final String? className;
  final List<dynamic>? subjects;

  const TeacherQuizListScreen({
    Key? key,
    this.classId,
    this.className,
    this.subjects,
  }) : super(key: key);

  @override
  _TeacherQuizListScreenState createState() => _TeacherQuizListScreenState();
}

class _TeacherQuizListScreenState extends State<TeacherQuizListScreen> {
  List _quizzes = [];
  bool _isLoading = true;
  String _teacherId = '';

  @override
  void initState() {
    super.initState();
    _loadTeacherId();
  }

  Future<void> _loadTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teacherId = prefs.getString('teacherId') ?? '';
    });
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    if (_teacherId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final url = widget.classId != null
          ? '${ApiConstants.apiBaseUrl}/quiz/class/${widget.classId}'
          : '${ApiConstants.apiBaseUrl}/quiz/teacher/$_teacherId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _quizzes = data['quizzes'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching quizzes: $e')));
    }
  }

  Future<void> _deleteQuiz(String quizId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: const Text('Are you sure you want to delete this quiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('${ApiConstants.apiBaseUrl}/quiz/$quizId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'teacherId': _teacherId}),
        );
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz deleted successfully')),
          );
          _fetchQuizzes();
        } else {
          final error =
              jsonDecode(response.body)['message'] ?? 'Failed to delete quiz';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: _fetchQuizzes,
              color: Colors.teal,
              child: _quizzes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quizzes created yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateQuizScreen(
                                  preSelectedClassId: widget.classId,
                                  preSelectedClassName: widget.className,
                                  subjects: widget.subjects,
                                ),
                              ),
                            ).then((_) => _fetchQuizzes()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child: const Text(
                              'Create your first quiz',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                      itemCount: _quizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = _quizzes[index];
                        final createdAt = DateTime.parse(
                          quiz['createdAt'],
                        ).toLocal();
                        final dateStr =
                            "${createdAt.day}/${createdAt.month}/${createdAt.year}";

                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.2),
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            quiz['title'] ?? 'Untitled Quiz',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF2D3436),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${quiz['subject']} • ${quiz['lessonName']}',
                                            style: TextStyle(
                                              color: Colors.blueGrey[400],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFE74C3C),
                                        size: 28,
                                      ),
                                      onPressed: () => _deleteQuiz(quiz['_id']),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    DifficultyBadge(
                                      difficulty:
                                          quiz['difficulty'] ?? 'medium',
                                    ),
                                    Text(
                                      '${quiz['totalQuestions']} Qs',
                                      style: TextStyle(
                                        color: Colors.blueGrey[600],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 18,
                                          color: Colors.blueGrey[300],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            color: Colors.blueGrey[600],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => QuizResultsScreen(
                                          quizId: quiz['_id'],
                                          quizTitle: quiz['title'],
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'View Results',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateQuizScreen(
              preSelectedClassId: widget.classId,
              preSelectedClassName: widget.className,
              subjects: widget.subjects,
            ),
          ),
        ).then((_) => _fetchQuizzes()),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
