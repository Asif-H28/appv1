import 'package:flutter/material.dart';

const Color _accent = Colors.teal;

class TeacherDashboardStats extends StatelessWidget {
  final bool loading;
  final int studentCount;
  final int testCount;
  final int noticeCount;
  final int notesCount;

  const TeacherDashboardStats({
    super.key,
    required this.loading,
    required this.studentCount,
    required this.testCount,
    required this.noticeCount,
    required this.notesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 10),
        loading
            ? _buildSkeletonRow()
            : Row(
                children: [
                  _statCard(
                    icon: Icons.people_rounded,
                    label: 'Students',
                    value: studentCount,
                  ),
                  const SizedBox(width: 8),
                  _statCard(
                    icon: Icons.quiz_rounded,
                    label: 'Tests',
                    value: testCount,
                  ),
                  const SizedBox(width: 8),
                  _statCard(
                    icon: Icons.campaign_rounded,
                    label: 'Notices',
                    value: noticeCount,
                  ),
                  const SizedBox(width: 8),
                  _statCard(
                    icon: Icons.menu_book_rounded,
                    label: 'Notes',
                    value: notesCount,
                  ),
                ],
              ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required int value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(icon, color: _accent, size: 17),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonRow() {
    return Row(
      children: List.generate(
        4,
        (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
