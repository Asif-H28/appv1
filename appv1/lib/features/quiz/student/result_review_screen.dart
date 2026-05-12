import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import 'dart:convert';
import '../../../core/constants/api_constants.dart';

class ResultReviewScreen extends StatefulWidget {
  final Map<String, dynamic>? reviewData;
  final String quizId;
  final String studentId;

  const ResultReviewScreen({
    Key? key,
    this.reviewData,
    required this.quizId,
    required this.studentId,
  }) : super(key: key);

  @override
  _ResultReviewScreenState createState() => _ResultReviewScreenState();
}

class _ResultReviewScreenState extends State<ResultReviewScreen> {
  Map<String, dynamic>? _review;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.reviewData != null) {
      _review = widget.reviewData;
    } else {
      _fetchReview();
    }
  }

  Future<void> _fetchReview() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(
        '${ApiConstants.apiBaseUrl}/quiz/result/${widget.quizId}/student/${widget.studentId}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _review = data['result'] ?? data['data'] ?? data;
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Quiz Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _review == null
              ? const Center(child: Text('Review not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
                  child: Column(
                    children: [
                      _buildScoreHeader(),
                      const SizedBox(height: 16),
                      ...((_review!['review'] as List?) ?? []).map((item) => _buildQuestionReviewCard(item)).toList(),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                          ),
                          child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildScoreHeader() {
    final double percentage = (_review!['percentage'] as num).toDouble();
    Color scoreColor = Colors.red;
    if (percentage >= 80) scoreColor = Colors.green;
    else if (percentage >= 50) scoreColor = Colors.orange;

    final int time = _review!['timeTakenSeconds'] ?? 0;
    final int mins = time ~/ 60;
    final int secs = time % 60;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (percentage >= 80)
              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 60),
            const SizedBox(height: 10),
            Text(
              "${percentage.toStringAsFixed(0)}%",
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: scoreColor),
            ),
            Text(
              "Score: ${_review!['score']}/${_review!['totalQuestions']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text("Time taken: ${mins}m ${secs}s", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionReviewCard(dynamic item) {
    final options = (item['options'] as List?) ?? [];
    final String selected = item['selectedAnswer'] ?? '';
    final String correct = item['correctAnswer'] ?? '';
    final bool isCorrect = item['isCorrect'] ?? false;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item['questionText'] ?? 'Question',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...options.map((opt) {
              Color bgColor = Colors.white;
              Color borderColor = Colors.grey[300]!;
              Widget? trailing;

              if (opt == correct) {
                bgColor = Colors.green.withOpacity(0.1);
                borderColor = Colors.green;
                trailing = const Icon(Icons.check, color: Colors.green, size: 16);
              } else if (opt == selected && !isCorrect) {
                bgColor = Colors.red.withOpacity(0.1);
                borderColor = Colors.red;
                trailing = const Icon(Icons.close, color: Colors.red, size: 16);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(opt ?? '', style: TextStyle(color: (opt == correct || (opt == selected && !isCorrect)) ? Colors.black : Colors.grey[700]))),
                    if (trailing != null) trailing,
                  ],
                ),
              );
            }).toList(),
            if (item['explanation'] != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.teal.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.teal, size: 14),
                        SizedBox(width: 4),
                        Text("Explanation", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item['explanation'], style: TextStyle(fontSize: 13, color: Colors.teal[800])),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
