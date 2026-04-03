import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_widgets.dart';
import 'classrooms_page.dart';
import 'leave_request_page.dart';
import 'notice_page.dart';
import 'school_page.dart';

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
  List<Map<String, dynamic>> _classrooms = [], _achievements = [];

  @override
  void initState() {
    super.initState();
    _init();
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
      _achievements = achList;
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
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
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
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF009688).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          color: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('OVERVIEW'),
              const SizedBox(height: 8),
              _buildKpiGrid(),
              const SizedBox(height: 26),
              _sectionLabel('QUICK ACTIONS'),
              const SizedBox(height: 8),
              _buildQuickActions(),
              if (_achievements.isNotEmpty) ...[
                const SizedBox(height: 26),
                _buildRowHeader(
                  'Recent Achievements',
                  '${_achievements.length} posts',
                  Icons.emoji_events_rounded,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 232,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        _achievements.length > 5 ? 5 : _achievements.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) =>
                        AchievementHCard(post: _achievements[i]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildKpiGrid() {
    final kpis = [
      _KpiData('Classes', '$_totalClasses', Icons.class_rounded,
          const Color(0xFF009688), const Color(0xFFE0F2F1)),
      _KpiData('Students', '$_totalStudents', Icons.groups_rounded,
          const Color(0xFF00897B), const Color(0xFFE0F2F1)),
      _KpiData('Teachers', '$_totalTeachers', Icons.school_rounded,
          const Color(0xFF00796B), const Color(0xFFE0F2F1)),
      _KpiData('Achievements', '$_totalAchievements',
          Icons.emoji_events_rounded, const Color(0xFF00695C),
          const Color(0xFFE0F2F1)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.65,
      children: kpis.map((d) => KpiCard(data: d)).toList(),
    );
  }

  Widget _buildQuickActions() {
    final items = [
      _QA('Classrooms', Icons.class_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassroomsPage()));
      }),
      _QA('Leave Request', Icons.event_busy_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRequestPage()));
      }),
      _QA('Notice', Icons.campaign_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticePage()));
      }),
      _QA('School', Icons.business_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolPage()));
      }),
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

  Widget _buildRowHeader(String title, String sub, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF009688).withOpacity(0.10),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(icon, color: const Color(0xFF009688), size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF009688).withOpacity(0.08),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text(
            'View All',
            style: TextStyle(
              color: Color(0xFF009688),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Data model for KPI ─────────────────────────────────
class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color bg;
  const _KpiData(this.label, this.value, this.icon, this.accent, this.bg);
}

// ─── Quick Action data model ─────────────────────────────
class _QA {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QA(this.label, this.icon, this.onTap);
}
