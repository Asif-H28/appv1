import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import '../../../../core/constants/app_colors.dart';

class AdminTeacherAdditionalDetailsPage extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const AdminTeacherAdditionalDetailsPage({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<AdminTeacherAdditionalDetailsPage> createState() => _AdminTeacherAdditionalDetailsPageState();
}

class _AdminTeacherAdditionalDetailsPageState extends State<AdminTeacherAdditionalDetailsPage> {
  bool _loading = true;
  List<Map<String, String>> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/teacher-additional-record/${widget.teacherId}'),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final data = body['data'] as Map?;
        final rawRecords = (data != null ? data['records'] as List? : []) ?? [];
        setState(() {
          _records = rawRecords.map((r) {
            final map = r as Map<String, dynamic>;
            return map.map((k, v) => MapEntry(k, v.toString()));
          }).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.teacherName,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2),
            )
          : _buildViewBody(),
    );
  }

  Widget _buildViewBody() {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No additional details found.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        final title = index == 0 ? 'Education Details' : 'Education Details #${index + 1}';
        final isLast = index == _records.length - 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
              padding: const EdgeInsets.only(left: 24, bottom: 20, top: 12),
              decoration: BoxDecoration(
                border: !isLast
                    ? Border(left: BorderSide(color: Colors.grey[300]!, width: 2))
                    : null,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: record.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.value.isEmpty ? 'N/A' : e.value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
