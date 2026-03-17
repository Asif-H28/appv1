import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'features/main_app/pages/login_page.dart';
import 'features/main_app/main_app_screen.dart';

void main() async {
  // Required before any async work in main
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

// ─── Decides which screen to show on app launch ───
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

    if (isLoggedIn && userRole == 'admin') {
      // Already logged in → go straight to home
      screen = MainAppScreen(initialTab: 0);
    } else {
      // Not logged in → show login page
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
      // Splash-style loader while checking prefs
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
