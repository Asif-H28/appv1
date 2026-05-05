import 'package:flutter/material.dart';

class TeacherDashboardActions extends StatelessWidget {
  final VoidCallback onMarkAttendance;
  final VoidCallback onAddTest;
  final VoidCallback onPostNotice;
  final VoidCallback onShareNotes;

  const TeacherDashboardActions({
    super.key,
    required this.onMarkAttendance,
    required this.onAddTest,
    required this.onPostNotice,
    required this.onShareNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionBtn(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Attendance',
              color: Colors.blue,
              onTap: onMarkAttendance,
            ),
            const SizedBox(width: 8),
            _actionBtn(
              icon: Icons.add_task_rounded,
              label: 'Add Test',
              color: Colors.orange,
              onTap: onAddTest,
            ),
            const SizedBox(width: 8),
            _actionBtn(
              icon: Icons.campaign_rounded,
              label: 'Post Notice',
              color: Colors.purple,
              onTap: onPostNotice,
            ),
            const SizedBox(width: 8),
            _actionBtn(
              icon: Icons.note_add_rounded,
              label: 'Share Notes',
              color: Colors.teal,
              onTap: onShareNotes,
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color.withDarkness(0.2),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color withDarkness(double factor) {
    assert(factor >= 0 && factor <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - factor).clamp(0.0, 1.0)).toColor();
  }
}
