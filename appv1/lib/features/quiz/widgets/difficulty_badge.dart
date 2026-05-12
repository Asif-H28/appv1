import 'package:flutter/material.dart';

class DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const DifficultyBadge({Key? key, required this.difficulty}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = Colors.green[700]!;
        bgColor = Colors.green[50]!;
        break;
      case 'medium':
        color = const Color(0xFFE65100); // Deep Orange 900
        bgColor = const Color(0xFFFFF3E0); // Orange 50
        break;
      case 'hard':
        color = Colors.red[700]!;
        bgColor = Colors.red[50]!;
        break;
      default:
        color = Colors.grey[700]!;
        bgColor = Colors.grey[50]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
