import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'features/main_app/pages/login_page.dart';
import 'features/main_app/main_app_screen.dart';
import 'features/student/student_main_screen.dart';
import 'features/student/student_join_org_page.dart';
import 'features/student/student_pending_screen.dart';
import 'features/student/student_rejected_screen.dart';
import 'features/teacher/presentation/pages/teacher_main_screen.dart';
import 'features/teacher/presentation/pages/teacher_pending_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        child: _StartupRouter(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─── Decides which screen to show on app launch ───────────

class _StartupRouter extends StatefulWidget {
  @override
  __StartupRouterState createState() => __StartupRouterState();
}

class __StartupRouterState extends State<_StartupRouter> {
  bool _isChecking = true;
  Widget _startScreen = SizedBox();

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userRole = prefs.getString('userRole') ?? '';

    Widget screen;

    if (!isLoggedIn || userRole.isEmpty) {
      // Not logged in — clear any stale data
      await prefs.clear();
      screen = LoginPage();
    } else if (userRole == 'admin') {
      // ── Admin ──────────────────────────────────────────
      screen = MainAppScreen(initialTab: 0);
    } else if (userRole == 'teacher') {
      // ── Teacher ────────────────────────────────────────
      final isVerified = prefs.getBool('teacherVerified') ?? false;
      final teacherName = prefs.getString('teacherName') ?? 'Teacher';
      final orgId = prefs.getString('orgId') ?? '';

      if (isVerified) {
        screen = TeacherMainScreen();
      } else {
        screen = TeacherPendingScreen(teacherName: teacherName, orgId: orgId);
      }
    } else if (userRole == 'student') {
      // ── Student ────────────────────────────────────────
      final joinStatus = prefs.getString('joinStatus') ?? 'none';
      final classId = prefs.getString('classId') ?? '';
      final studentName = prefs.getString('studentName') ?? 'Student';

      switch (joinStatus) {
        case 'approved':
          screen = classId.isNotEmpty
              ? StudentMainScreen()
              : StudentJoinOrgPage();
          break;
        case 'pending':
          screen = StudentPendingScreen(studentName: studentName);
          break;
        case 'rejected':
          screen = StudentRejectedScreen(studentName: studentName);
          break;
        default:
          screen = StudentJoinOrgPage();
      }
    } else {
      // Unknown role — reset
      await prefs.clear();
      screen = LoginPage();
    }

    setState(() {
      _startScreen = screen;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.sync_alt, color: Colors.white, size: 48),
              ),
              SizedBox(height: 20),
              Text(
                'SchoolSync',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ],
          ),
        ),
      );
    }

    return _startScreen;
  }
}
