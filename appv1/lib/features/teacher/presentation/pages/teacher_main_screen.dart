import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../main_app/pages/notification_service.dart';
import 'teacher_home_page.dart';
import 'teacher_classroom_page.dart';
import 'teacher_dashboard_page.dart';
import 'teacher_settings_page.dart';
import 'teacher_achievements_page.dart';

const Color _accent = Colors.teal;

class TeacherMainScreen extends StatefulWidget {
  final int initialTab;
  const TeacherMainScreen({this.initialTab = 0});

  @override
  _TeacherMainScreenState createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  late int _currentTab;
  String _teacherId = '';
  String _authToken = '';

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _loadAndFetch();
    teacherNotifCountNotifier.addListener(_onNotifReceived);
  }

  @override
  void dispose() {
    teacherNotifCountNotifier.removeListener(_onNotifReceived);
    super.dispose();
  }

  void _onNotifReceived() {
    // Only fetch if the value was incremented as a signal (e.g. from FCM)
    // To avoid infinite loop if we update the value here, we should be careful.
    // However, usually listeners don't trigger when value is set to same thing.
    _fetchCount();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _teacherId = prefs.getString('teacherId') ?? '';
    _authToken = prefs.getString('authToken') ?? '';
    _fetchCount();
  }

  Future<void> _fetchCount() async {
    if (_teacherId.isEmpty || _authToken.isEmpty) return;
    final count = await NotificationService.getTeacherNotificationCount(
      teacherId: _teacherId,
      token: _authToken,
    );
    if (mounted) {
      // Use teacherNotifCountNotifier to store the real count
      teacherNotifCountNotifier.value = count;
    }
  }

  final List<Widget> _pages = [
    TeacherHomePage(),
    TeacherClassroomPage(),
    TeacherAchievementsPage(),
    TeacherDashboardPage(),
    TeacherSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: IndexedStack(index: _currentTab, children: _pages),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
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
              _navItem(
                1,
                Icons.class_rounded,
                Icons.class_outlined,
                'Classroom',
              ),
              _navItem(
                2,
                Icons.emoji_events_rounded,
                Icons.emoji_events_outlined,
                'Achieve',
              ),
              _navItem(
                3,
                Icons.dashboard_rounded,
                Icons.dashboard_outlined,
                'Dashboard',
              ),
              _navItem(
                4,
                Icons.settings_rounded,
                Icons.settings_outlined,
                'Settings',
              ),
            ],
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
            Icon(
              isActive ? active : inactive,
              color: isActive ? _accent : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _accent : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
