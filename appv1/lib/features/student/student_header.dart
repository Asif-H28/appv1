import 'package:flutter/material.dart';

Widget buildStudentHeader({
  required BuildContext context,
  required Color color,
  required IconData icon,
  required String title,
  required String subtitle,
  bool showBack = true,
}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color, color.withOpacity(0.75)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 16, 18),
        child: Row(
          children: [
            if (showBack) ...[
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
              SizedBox(width: 10),
            ],
            Container(
              padding: EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
