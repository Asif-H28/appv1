import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

const Color _accent = Colors.teal;

class StudentMainScreen extends StatefulWidget {
  final int initialTab;
  const StudentMainScreen({this.initialTab = 0});

  @override
  _StudentMainScreenState createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  late int _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  final List<Widget> _pages = [
    StudentHomePage(),
    StudentClassPage(),
    StudentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: IndexedStack(index: _currentTab, children: _pages),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _navItem(1, Icons.class_rounded, Icons.class_outlined, 'Class'),
                _navItem(2, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final isActive = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentTab = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? active : inactive,
                color: isActive ? _accent : AppColors.textSecondary,
                size: 22),
            SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  color: isActive ? _accent : AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Placeholder pages (replace with real pages later) ──

class StudentHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Home', style: TextStyle(color: AppColors.textPrimary)),
    );
  }
}

class StudentClassPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Class', style: TextStyle(color: AppColors.textPrimary)),
    );
  }
}

class StudentProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Profile', style: TextStyle(color: AppColors.textPrimary)),
    );
  }
}
