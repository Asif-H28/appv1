import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'teacher_class_dashboard.dart';
import 'teacher_student_roster.dart';

const Color _accent = Colors.teal;
const String _base = 'https://appv1backend.onrender.com';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage>
    with SingleTickerProviderStateMixin {
  String _orgId = '';
  String _teacherId = '';
  String _teacherName = '';

  List<Map<String, dynamic>> _classes = [];
  String _selectedId = '';
  String _selectedName = '';
  bool _classesLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    _teacherId = prefs.getString('teacherId') ?? '';
    _teacherName = prefs.getString('teacherName') ?? 'Teacher';
    debugPrint('[Dashboard] orgId="$_orgId" teacherId="$_teacherId"');
    await _loadClasses();
  }

  Future<void> _loadClasses() async {
    if (_orgId.isEmpty) {
      setState(() => _classesLoading = false);
      return;
    }
    try {
      final url = '$_base/api/classroom/org/$_orgId';
      debugPrint('[Dashboard] Loading: $url');

      final res = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      debugPrint('[Dashboard] status=${res.statusCode} body=${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['classrooms'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        if (list.isNotEmpty) {
          final firstId = _extractClassId(list[0]);
          final firstName = _extractClassName(list[0]);
          setState(() {
            _classes = list;
            _selectedId = firstId;
            _selectedName = firstName;
          });
          debugPrint('[Dashboard] Auto-selected "$firstId" / "$firstName"');
        } else {
          setState(() => _classes = []);
        }
      }
    } catch (e) {
      debugPrint('[Dashboard] error: $e');
    }
    if (mounted) setState(() => _classesLoading = false);
  }

  String _extractClassId(Map<String, dynamic> cls) =>
      (cls['classId'] ?? cls['class_id'] ?? cls['_id'] ?? cls['id'] ?? '')
          .toString()
          .trim();

  String _extractClassName(Map<String, dynamic> cls) =>
      (cls['className'] ?? cls['class_name'] ?? cls['name'] ?? 'Class')
          .toString()
          .trim();

  void _onClassChanged(Map<String, dynamic> cls) {
    final id = _extractClassId(cls);
    final name = _extractClassName(cls);
    if (id.isEmpty) return;
    debugPrint('[Dashboard] switched → "$id" / "$name"');
    setState(() {
      _selectedId = id;
      _selectedName = name;
    });
    _tabController.animateTo(0);
  }

  // ── Searchable class dropdown ──────────────────────
  void _showClassDropdown(BuildContext context) {
    final List<Map<String, dynamic>> filtered = List.from(_classes);
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Class',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        autofocus: true,
                        style: const TextStyle(fontSize: 12.5),
                        onChanged: (q) {
                          setModal(() {
                            filtered
                              ..clear()
                              ..addAll(
                                _classes.where(
                                  (c) => _extractClassName(
                                    c,
                                  ).toLowerCase().contains(q.toLowerCase()),
                                ),
                              );
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search class...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12.5,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Class list
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No classes found',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF888888),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (_, i) {
                              final cls = filtered[i];
                              final id = _extractClassId(cls);
                              final name = _extractClassName(cls);
                              final isActive = id == _selectedId;
                              final count = cls['studentCount'] as int? ?? 0;

                              return GestureDetector(
                                onTap: () {
                                  _onClassChanged(cls);
                                  Navigator.pop(ctx);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? _accent.withOpacity(0.06)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: isActive
                                          ? _accent.withOpacity(0.3)
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? _accent
                                              : _accent.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.class_rounded,
                                          color: isActive
                                              ? Colors.white
                                              : _accent,
                                          size: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontWeight: isActive
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                fontSize: 12.5,
                                                color: const Color(0xFF1A1A1A),
                                              ),
                                            ),
                                            if (count > 0) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                '$count students',
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  color: Color(0xFF888888),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (isActive)
                                        const Icon(
                                          Icons.check_rounded,
                                          color: _accent,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_classesLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(
          child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
        ),
      );
    }

    if (_classes.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.class_outlined,
                  color: _accent,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No classes found',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Create a class to get started',
                style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                TeacherClassDashboard(
                  key: ValueKey('class_$_selectedId'),
                  classId: _selectedId,
                  className: _selectedName,
                ),
                TeacherStudentRoster(
                  key: ValueKey('roster_$_selectedId'),
                  classId: _selectedId,
                  className: _selectedName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(
            children: [
              // Logo icon
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.sync_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),

              // Title + subtitle
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SchoolSync',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Teacher Portal',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),

              // Class dropdown trigger
              GestureDetector(
                onTap: () => _showClassDropdown(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.class_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          _selectedName.isNotEmpty
                              ? _selectedName
                              : 'Select Class',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicator: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _accent, width: 2.5)),
        ),
        labelColor: _accent,
        unselectedLabelColor: const Color(0xFF888888),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12.5,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dashboard_rounded, size: 14),
                SizedBox(width: 6),
                Text('Class'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_rounded, size: 14),
                SizedBox(width: 6),
                Text('Students'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
