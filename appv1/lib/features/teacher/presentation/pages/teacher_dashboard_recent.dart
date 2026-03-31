import 'package:flutter/material.dart';

const Color _accent = Colors.teal;

class TeacherDashboardRecent extends StatelessWidget {
  final bool loading;
  final List<Map<String, dynamic>> recentTests;
  final List<Map<String, dynamic>> recentNotices;
  final List<Map<String, dynamic>> recentNotes;

  const TeacherDashboardRecent({
    super.key,
    required this.loading,
    required this.recentTests,
    required this.recentNotices,
    required this.recentNotes,
  });

  String _timeAgo(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recentTests.isNotEmpty) ...[
          _sectionHeader(Icons.quiz_rounded, 'Recent Tests'),
          const SizedBox(height: 8),
          ...recentTests.map((t) => _testCard(t)),
          const SizedBox(height: 16),
        ],

        if (recentNotices.isNotEmpty) ...[
          _sectionHeader(Icons.campaign_rounded, 'Recent Notices'),
          const SizedBox(height: 8),
          ...recentNotices.map(
            (n) => _simpleCard(
              icon: Icons.campaign_rounded,
              title: n['title']?.toString() ?? '',
              sub: n['content']?.toString() ?? n['body']?.toString() ?? '',
              time: _timeAgo(n['createdAt']?.toString()),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (recentNotes.isNotEmpty) ...[
          _sectionHeader(Icons.menu_book_rounded, 'Recent Notes'),
          const SizedBox(height: 8),
          ...recentNotes.map(
            (n) => _simpleCard(
              icon: Icons.menu_book_rounded,
              title: n['title']?.toString() ?? '',
              sub:
                  n['subject']?.toString() ??
                  n['description']?.toString() ??
                  '',
              time: _timeAgo(n['createdAt']?.toString()),
            ),
          ),
        ],

        if (recentTests.isEmpty && recentNotices.isEmpty && recentNotes.isEmpty)
          _buildEmpty(),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 16),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _testCard(Map<String, dynamic> test) {
    final title = test['title']?.toString() ?? 'Untitled Test';
    final subject = test['subject']?.toString() ?? '';
    final time = _timeAgo(test['createdAt']?.toString());
    final maxMarks = test['maxMarks']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Icon(Icons.quiz_rounded, color: _accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (subject.isNotEmpty) ...[
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                    ],
                    if (maxMarks.isNotEmpty)
                      Text(
                        '$maxMarks marks',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _simpleCard({
    required IconData icon,
    required String title,
    required String sub,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(icon, color: _accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, color: _accent, size: 28),
          SizedBox(height: 10),
          Text(
            'No recent activity',
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tests, notices and notes will appear here',
            style: TextStyle(color: Color(0xFF888888), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
