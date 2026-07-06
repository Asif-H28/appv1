import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_theme_manager.dart';
import 'student_class_notices_tab.dart';
import 'student_school_notices_tab.dart';


class StudentNoticeScreen extends StatefulWidget {
  @override
  _StudentNoticeScreenState createState() => _StudentNoticeScreenState();
}

class _StudentNoticeScreenState extends State<StudentNoticeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, _) {
        return Scaffold(
          backgroundColor: theme.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [StudentClassNoticesTab(), StudentSchoolNoticesTab()],
              ),
            ),
          ],
        ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(StudentThemeConfig theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 16, 12),
              child: Row(
                children: [
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
                  Container(
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notice Board',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Stay updated with announcements',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab bar ──
            Container(
              margin: EdgeInsets.fromLTRB(14, 0, 14, 12),
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: theme.primary,
                unselectedLabelColor: Colors.white.withOpacity(0.85),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                padding: EdgeInsets.all(3),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.class_rounded, size: 13),
                        SizedBox(width: 5),
                        Text('Classroom'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_rounded, size: 13),
                        SizedBox(width: 5),
                        Text('School'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
