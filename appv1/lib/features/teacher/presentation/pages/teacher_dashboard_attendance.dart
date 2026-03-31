import 'package:flutter/material.dart';

const Color _accent = Colors.teal;

class TeacherDashboardAttendance extends StatelessWidget {
  final bool loading;
  final bool isEmpty;
  final int? present;
  final int? absent;
  final int? leave;

  const TeacherDashboardAttendance({
    super.key,
    required this.loading,
    required this.isEmpty,
    required this.present,
    required this.absent,
    required this.leave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.today_rounded,
                  color: _accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Today's Attendance",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (loading)
            _buildSkeleton()
          else if (isEmpty)
            _buildNotMarked()
          else
            _buildAttRow(),
        ],
      ),
    );
  }

  Widget _buildAttRow() {
    final total = (present ?? 0) + (absent ?? 0) + (leave ?? 0);
    return Column(
      children: [
        Row(
          children: [
            _attChip(
              color: Colors.green,
              icon: Icons.check_circle_rounded,
              label: 'Present',
              value: present ?? 0,
            ),
            const SizedBox(width: 8),
            _attChip(
              color: Colors.red,
              icon: Icons.cancel_rounded,
              label: 'Absent',
              value: absent ?? 0,
            ),
            const SizedBox(width: 8),
            _attChip(
              color: Colors.orange,
              icon: Icons.watch_later_rounded,
              label: 'Leave',
              value: leave ?? 0,
            ),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total > 0 ? (present ?? 0) / total : 0,
              backgroundColor: Colors.red.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${total > 0 ? ((present ?? 0) * 100 ~/ total) : 0}% attendance today',
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
        ],
      ],
    );
  }

  Widget _attChip({
    required Color color,
    required IconData icon,
    required String label,
    required int value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 5),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotMarked() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.teal.withOpacity(0.15)),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_rounded, color: _accent, size: 24),
          SizedBox(height: 8),
          Text(
            'Attendance not marked yet',
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
            height: 72,
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
