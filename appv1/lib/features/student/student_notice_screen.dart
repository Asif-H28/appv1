import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_header.dart';

const Color _accent = Colors.teal;

class StudentNoticeScreen extends StatelessWidget {
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
              icon: Icons.campaign_rounded,
              title: 'Notice Board',
              subtitle: 'Announcements from your teacher',
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Notices coming soon',
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
