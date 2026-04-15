import 'dart:convert';
import 'package:appv1/features/main_app/pages/home_widgets2.dart';
import 'package:appv1/features/main_app/pages/school_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_widgets.dart';
import 'classrooms_page.dart';
import 'leave_request_page.dart';
import 'notice_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _orgId = '';
  bool _loading = true, _error = false;
  int _totalClasses = 0,
      _totalStudents = 0,
      _totalTeachers = 0,
      _totalAchievements = 0;
  List<Map<String, dynamic>> _classrooms = [];
  final PageController _kpiCtrl = PageController(viewportFraction: 0.78);
  int _kpiPage = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _kpiCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    await _fetchAll();
  }

  Future<void> _fetchAll() async {
    if (_orgId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = false;
    });

    final classRes = await _safeGet('classroom/org/$_orgId');
    final achRes = await _safeGet('achievement/org/$_orgId');
    final countRes = await _safeGet('org/$_orgId/count');

    final classList = (classRes?['classrooms'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final studentTotal = classList.fold<int>(
      0,
      (s, c) => s + ((c['studentIds'] as List?)?.length ?? 0),
    );
    final achList = (achRes?['achievements'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (!mounted) return;
    setState(() {
      _classrooms = classList;
      _totalClasses = classList.length;
      _totalStudents = studentTotal;
      _totalTeachers = countRes?['totalTeachers'] as int? ?? 0;
      _totalAchievements = achList.length;
      _loading = false;
    });
  }

  Future<Map<String, dynamic>?> _safeGet(String path) async {
    try {
      final res = await http.get(
        Uri.parse('https://appv1backend.onrender.com/api/$path'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200)
        return jsonDecode(res.body) as Map<String, dynamic>;
      debugPrint('[HomePage] HTTP ${res.statusCode} → $path');
      return null;
    } catch (e) {
      debugPrint('[HomePage] error → $path : $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF009688),
      backgroundColor: Colors.white,
      displacement: 20,
      onRefresh: _fetchAll,
      child: _loading
          ? const HomeShimmer()
          : _error
          ? _buildError()
          : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF009688).withOpacity(0.08),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: const Color(0xFF009688).withOpacity(0.18),
              ),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              color: const Color(0xFF009688).withOpacity(0.5),
              size: 44,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Could not load dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pull down to retry',
            style: TextStyle(color: Color(0xFF718096), fontSize: 12),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _fetchAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00796B), Color(0xFF26A69A)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final kpiCards = [
      KpiCarouselCard(
        label: 'Classrooms',
        value: '$_totalClasses',
        subtitle: 'Active this semester',
        gradientColors: const [Color(0xFF00897B), Color(0xFF4DB6AC)],
        clayColor: const Color(0xFFB2DFDB),
        illustration: const ClassroomIllustration(),
      ),
      KpiCarouselCard(
        label: 'Students',
        value: '$_totalStudents',
        subtitle: 'Enrolled & active',
        gradientColors: const [Color(0xFF00695C), Color(0xFF009688)],
        clayColor: const Color(0xFFA5D6D0),
        illustration: const StudentsIllustration(),
      ),
      KpiCarouselCard(
        label: 'Teachers',
        value: '$_totalTeachers',
        subtitle: 'Faculty members',
        gradientColors: const [Color(0xFF004D40), Color(0xFF00796B)],
        clayColor: const Color(0xFF80CBC4),
        illustration: const TeacherIllustration(),
      ),
      KpiCarouselCard(
        label: 'Achievements',
        value: '$_totalAchievements',
        subtitle: 'Posts published',
        gradientColors: const [Color(0xFF26A69A), Color(0xFF80DEEA)],
        clayColor: const Color(0xFFB2EBF2),
        illustration: const AchievementIllustration(),
      ),
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          color: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _sectionLabel('OVERVIEW'),
              ),
              const SizedBox(height: 14),

              // KPI carousel
              SizedBox(
                height: 158,
                child: PageView.builder(
                  controller: _kpiCtrl,
                  itemCount: kpiCards.length,
                  onPageChanged: (i) => setState(() => _kpiPage = i),
                  itemBuilder: (_, i) => AnimatedScale(
                    scale: _kpiPage == i ? 1.0 : 0.93,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: kpiCards[i],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Dot indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(kpiCards.length, (i) {
                  final active = _kpiPage == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: active
                          ? const Color(0xFF009688)
                          : const Color(0xFF009688).withOpacity(0.25),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 26),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _sectionLabel('QUICK ACTIONS'),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildQuickActions(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final items = [
      _QA(
        'Classrooms',
        Icons.class_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClassroomsPage()),
        ),
      ),
      _QA(
        'Leaves',
        Icons.event_busy_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaveRequestPage()),
        ),
      ),
      _QA(
        'Notice',
        Icons.campaign_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoticePage()),
        ),
      ),
      _QA(
        'School',
        Icons.business_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SchoolPage()),
        ),
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((q) => Expanded(child: QuickBtn(item: q))).toList(),
    );
  }

  Widget _sectionLabel(String t) => Row(
    children: [
      Container(
        width: 4,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF009688),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        t,
        style: const TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}

class _QA {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QA(this.label, this.icon, this.onTap);
}
