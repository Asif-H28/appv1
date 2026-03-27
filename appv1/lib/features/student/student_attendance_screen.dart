import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_header.dart';

const Color _accent = Colors.teal;

class StudentAttendanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            buildStudentHeader(
              context: context,
              color: _accent,
              icon: Icons.fact_check_rounded,
              title: 'My Attendance',
              subtitle: 'Your daily attendance record',
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Attendance coming soon',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
