import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/pages/landing_page.dart';
import 'core/constants/app_colors.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Admin',
      theme: appTheme(),
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          // Status bar (top)
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Dark icons on light bg
          // System navigation bar (bottom) - WHITE background
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark, // Dark nav icons
          systemNavigationBarDividerColor:
              Colors.transparent, // No divider line
        ),
        child: LandingPage(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
