import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'home_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _orgId = '', _orgName = '', _adminEmail = '';
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
    _orgName = prefs.getString('userOrg') ?? '';
    _adminEmail = prefs.getString('adminEmail') ?? '';
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
      color: Colors.teal,
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              color: Colors.teal.withOpacity(0.5),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull down to retry',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _fetchAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.teal,
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
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Teal hero banner ──────────────────────
        _buildHeroBanner(),

        // ── White/bg content below ────────────────
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('OVERVIEW'),
              const SizedBox(height: 12),
              _buildKpiGrid(),
              const SizedBox(height: 22),
              _label('QUICK ACTIONS'),
              const SizedBox(height: 12),
              _buildQuickActions(),
              const SizedBox(height: 22),
              if (_achievements.isNotEmpty) ...[
                _buildRowHeader(
                  'Recent Achievements',
                  '${_achievements.length} posts',
                  Icons.emoji_events_rounded,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _achievements.length > 5
                        ? 5
                        : _achievements.length,
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

  Widget _buildHeroBanner() {
    final initial = _orgName.isNotEmpty ? _orgName[0].toUpperCase() : 'A';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF009688), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _orgName.isNotEmpty ? _orgName : 'Your Organisation',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _adminEmail,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          // Wrap prevents overflow on small screens
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _heroPill(Icons.class_rounded, '$_totalClasses Classes'),
              _heroPill(Icons.groups_rounded, '$_totalStudents Students'),
              _heroPill(Icons.school_rounded, '$_totalTeachers Teachers'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: [
        KpiCard(
          label: 'Classes',
          value: '$_totalClasses',
          icon: Icons.class_rounded,
          color: Colors.teal,
        ),
        KpiCard(
          label: 'Students',
          value: '$_totalStudents',
          icon: Icons.groups_rounded,
          color: Colors.teal,
        ),
        KpiCard(
          label: 'Teachers',
          value: '$_totalTeachers',
          icon: Icons.school_rounded,
          color: Colors.teal,
        ),
        KpiCard(
          label: 'Achievements',
          value: '$_totalAchievements',
          icon: Icons.emoji_events_rounded,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final items = [
      _QA('Classes', Icons.class_rounded),
      _QA('Achievements', Icons.emoji_events_rounded),
      _QA('Notifs', Icons.notifications_rounded),
      _QA('Settings', Icons.settings_rounded),
    ];
    return Row(
      children: items.map((q) => Expanded(child: QuickBtn(item: q))).toList(),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );

  Widget _buildRowHeader(String title, String sub, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.10),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(icon, color: Colors.teal, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                sub,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QA {
  final String label;
  final IconData icon;
  VoidCallback? get onTap => null;
  const _QA(this.label, this.icon);
}
