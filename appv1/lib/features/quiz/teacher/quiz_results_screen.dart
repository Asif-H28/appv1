import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../student/result_review_screen.dart';

class QuizResultsScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const QuizResultsScreen({Key? key, required this.quizId, required this.quizTitle}) : super(key: key);

  @override
  _QuizResultsScreenState createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  Map<String, dynamic>? _results;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/quiz/results/${widget.quizId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _results = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Quiz Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _results == null || (_results!['attempts'] as List).isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No students have attempted this quiz yet', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text('Student Attempts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (_results!['attempts'] as List).length,
                        itemBuilder: (context, index) {
                          final attempt = _results!['attempts'][index];
                          return _buildStudentResultCard(attempt);
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.quizTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Total Attempts', _results!['totalAttempts'].toString()),
                _statItem('Average Score', '${_results!['averageScore']}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildStudentResultCard(dynamic attempt) {
    final double percentage = (attempt['percentage'] as num).toDouble();
    Color scoreColor = Colors.red;
    if (percentage >= 80) {
      scoreColor = Colors.green;
    } else if (percentage >= 50) {
      scoreColor = Colors.orange;
    }

    final int time = attempt['timeTakenSeconds'] ?? 0;
    final int mins = time ~/ 60;
    final int secs = time % 60;
    final String timeStr = "${mins}m ${secs}s";

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(attempt['studentName'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Time taken: $timeStr", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("${attempt['score']}/${attempt['totalQuestions']}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scoreColor)),
            Text("${percentage.toStringAsFixed(0)}%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: scoreColor)),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultReviewScreen(
                quizId: widget.quizId,
                studentId: attempt['studentId'],
              ),
            ),
          );
        },
      ),
    );
  }
}
