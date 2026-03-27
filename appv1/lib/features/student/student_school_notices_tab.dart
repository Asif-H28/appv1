import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

const Color _accent = Colors.teal;

class StudentSchoolNoticesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.07),
                border: Border.all(color: _accent.withOpacity(0.15), width: 2),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                color: _accent,
                size: 36,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'School Notices',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _accent.withOpacity(0.2)),
              ),
              child: Text(
                'Coming Soon',
                style: TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'School-wide announcements will\nappear here once available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
