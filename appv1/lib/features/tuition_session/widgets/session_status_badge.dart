import 'package:flutter/material.dart';

class SessionStatusBadge extends StatelessWidget {
  final String status;
  final bool forcedCheckIn;

  const SessionStatusBadge({
    Key? key,
    required this.status,
    this.forcedCheckIn = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor = Colors.white;
    String displayStatus = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'ongoing':
        bgColor = const Color(0xFF009688); // Teal
        break;
      case 'completed':
        bgColor = Colors.blueGrey;
        break;
      case 'missed':
        bgColor = Colors.redAccent;
        break;
      case 'pending':
      default:
        bgColor = Colors.orangeAccent;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            displayStatus,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (forcedCheckIn) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.red, width: 0.5),
            ),
            child: const Text(
              'FORCED',
              style: TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ]
      ],
    );
  }
}
