import 'package:flutter/material.dart';
import 'package:appv1/features/student/student_theme_manager.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../widgets/difficulty_badge.dart';
import 'quiz_attempt_screen.dart';
import 'result_review_screen.dart';

import '../../../core/services/api_service.dart';

class StudentQuizListScreen extends StatefulWidget {
  const StudentQuizListScreen({Key? key}) : super(key: key);

  @override
  _StudentQuizListScreenState createState() => _StudentQuizListScreenState();
}

class _StudentQuizListScreenState extends State<StudentQuizListScreen> {
  StudentThemeConfig get theme => StudentThemeManager.themeNotifier.value;
  List _quizzes = [];
  List _attemptedQuizIds = [];
  bool _isLoading = true;
  String _classId = '';
  String _studentId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _classId = prefs.getString('classId') ?? '';
      _studentId = prefs.getString('studentId') ?? '';
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_classId.isEmpty || _studentId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final quizRes = await ApiService.get('${ApiConstants.apiBaseUrl}/quiz/class/$_classId');
      final attemptRes = await ApiService.get('${ApiConstants.apiBaseUrl}/quiz/result/student/$_studentId');

      if (quizRes.statusCode == 200) {
        final data = jsonDecode(quizRes.body);
        final quizzes = data['quizzes'] ?? [];
        
        List attemptedIds = [];
        if (attemptRes.statusCode == 200) {
          final attemptData = jsonDecode(attemptRes.body);
          final attempts = attemptData['results'] ?? attemptData['data'] ?? attemptData;
          if (attempts is List) {
            attemptedIds = attempts.map((a) => a['quizId'].toString()).toList();
          }
        }
        
        setState(() {
          _quizzes = quizzes;
          _attemptedQuizIds = attemptedIds;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,

      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: theme.primary,
              child: _quizzes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text('No quizzes available yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                      itemCount: _quizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = _quizzes[index];
                        final isAttempted = _attemptedQuizIds.contains(quiz['_id']);

                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quiz['title'] ?? 'Untitled Quiz',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text('${quiz['subject']} • ${quiz['lessonName']}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    DifficultyBadge(difficulty: quiz['difficulty'] ?? 'medium'),
                                    SizedBox(width: 8),
                                    _infoChip(Icons.timer_outlined, '${quiz['durationMinutes']} mins'),
                                    SizedBox(width: 8),
                                    _infoChip(Icons.help_outline, '${quiz['totalQuestions']} Qs'),
                                  ],
                                ),
                                Divider(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: isAttempted
                                    ? Column(
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ResultReviewScreen(
                                                      quizId: quiz['_id'],
                                                      studentId: _studentId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(color: theme.primary),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                              ),
                                              child: Text('View Result', style: TextStyle(color: theme.primary)),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: null, // Disabled
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.grey[300],
                                                foregroundColor: Colors.grey[600],
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                              ),
                                              child: Text('Already Attempted'),
                                            ),
                                          ),
                                        ],
                                      )
                                    : SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => QuizAttemptScreen(quizId: quiz['_id']),
                                              ),
                                            ).then((_) => _fetchData());
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.primary,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                          ),
                                          child: Text('Start Quiz'),
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
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
