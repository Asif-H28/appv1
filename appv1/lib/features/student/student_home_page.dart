import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_classroom_screen.dart';
import 'student_attendance_screen.dart';
import 'student_notice_screen.dart';

const Color _accent = Colors.teal;

class StudentHomePage extends StatefulWidget {
  @override
  _StudentHomePageState createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String _studentName = '';
  String _orgName = '';
  String _className = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _studentName = prefs.getString('studentName') ?? 'Student';
      _orgName = prefs.getString('tempOrgName') ?? '';
      _className = prefs.getString('className') ?? '';
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 20),
              _buildBanner(),
              SizedBox(height: 24),
              Text(
                'Quick Access',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              _buildNavCard(
                icon: Icons.class_rounded,
                color: _accent,
                title: 'Visit Classroom',
                subtitle: _className.isNotEmpty
                    ? _className
                    : 'View lessons, materials and more',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentClassroomScreen()),
                ),
              ),
              SizedBox(height: 10),
              _buildNavCard(
                icon: Icons.fact_check_rounded,
                color: _accent,
                title: 'My Attendance',
                subtitle: 'Track your daily attendance record',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentAttendanceScreen()),
                ),
              ),
              SizedBox(height: 10),
              _buildNavCard(
                icon: Icons.campaign_rounded,
                color: _accent,
                title: 'Notice Board',
                subtitle: 'Announcements from your teacher',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentNoticeScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Hi, $_studentName',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_orgName.isNotEmpty) ...[
                SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 11,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 3),
                    Text(
                      _orgName,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [_accent, _accent.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              _studentName.isNotEmpty ? _studentName[0].toUpperCase() : 'S',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Banner ────────────────────────────────────────────

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, _accent.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay on track',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Check your attendance and\nkeep up with class notices.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _bannerChip(Icons.calendar_today_rounded, 'Today'),
                    SizedBox(width: 14),
                    _bannerChip(Icons.check_circle_outline_rounded, 'Present'),
                    SizedBox(width: 14),
                    _bannerChip(Icons.notifications_outlined, 'Notices'),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(Icons.school_rounded, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }

  Widget _bannerChip(IconData icon, String label) => Row(
    children: [
      Icon(icon, color: Colors.white.withOpacity(0.9), size: 13),
      SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  // ── Nav card ─────────────────────────────────────────

  Widget _buildNavCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
