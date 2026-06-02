import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/teacher_drawer.dart';
import 'teacher_basic_details_page.dart';
import 'teacher_additional_details_page.dart';
import 'teacher_leave_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import 'package:appv1/features/main_app/pages/manage_vehicles_page.dart';

class TeacherSettingsPage extends StatefulWidget {
  @override
  _TeacherSettingsPageState createState() => _TeacherSettingsPageState();
}

class _TeacherSettingsPageState extends State<TeacherSettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isCoordinator = false;
  String _orgId = '';
  String _teacherId = '';
  String _teacherName = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _teacherId = prefs.getString('teacherId') ?? '';
    if (_teacherId.isEmpty) return;
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/teacher/$_teacherId/profile'),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final t = (jsonDecode(res.body) as Map)['teacher'] as Map;
        setState(() {
          _isCoordinator = t['isTransportCoordinator'] ?? false;
          _orgId = t['orgId'] ?? '';
          _teacherName = t['name'] ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: const TeacherDrawer(currentRoute: TeacherDrawerRoute.settings),
      appBar: _buildAppBar(),
      body: _buildMainMenu(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.teal,
      elevation: 1,
      centerTitle: false,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Teacher Portal',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupTitle('PROFILE SETTINGS'),
          _buildMenuGroup([
            {
              'icon': Icons.person_outline_rounded,
              'label': 'Basic Details',
              'color': Colors.blue[600]!,
              'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherBasicDetailsPage())),
            },
            {
              'icon': Icons.more_horiz_rounded,
              'label': 'Additional Details',
              'color': Colors.purple[600]!,
              'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherAdditionalDetailsPage())),
            },
          ]),
          const SizedBox(height: 24),
          _buildGroupTitle('LEAVE MANAGEMENT'),
          _buildMenuGroup([
            {
              'icon': Icons.event_busy_rounded,
              'label': 'Leaves',
              'color': Colors.orange[600]!,
              'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherLeavePage())),
            },
            if (_isCoordinator)
              {
                'icon': Icons.directions_bus_rounded,
                'label': 'Manage Vehicles',
                'color': Colors.teal[600]!,
                'onTap': () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageVehiclesPage(
                          orgId: _orgId,
                          coordinatorId: _teacherId,
                          coordinatorName: _teacherName,
                        ),
                      ),
                    ),
              },
          ]),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;

          return Column(
            children: [
              _buildMenuItem(
                icon: item['icon'] as IconData,
                label: item['label'] as String,
                color: item['color'] as Color,
                onTap: item['onTap'] as VoidCallback,
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Divider(height: 1, color: Colors.grey[100]),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[300],
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
