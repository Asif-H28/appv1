import 'package:appv1/features/teacher/presentation/pages/assessment_results_page.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'teacher_notification_screen.dart';
import '../../../main_app/pages/notification_service.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  String _orgId = '';
  List<dynamic> _classrooms = [];
  Map<String, dynamic>? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  
  bool _isLoadingClasses = true;
  bool _isLoadingAttendance = false;
  bool _isLoadingAssessments = false;
  
  int _presentCount = 0;
  int _absentCount = 0;
  double _attendancePercentage = 0.0;
  List<dynamic> _assessments = [];
  List<dynamic> _filteredAssessments = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredAssessments = _assessments.where((a) {
        final title = a['title']?.toString().toLowerCase() ?? '';
        return title.contains(_searchController.text.toLowerCase());
      }).toList();
    });
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    if (_orgId.isNotEmpty) {
      await _fetchClassrooms();
    } else {
      setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _fetchClassrooms() async {
    setState(() => _isLoadingClasses = true);
    final result = await ApiService.fetchClassroomsByOrg(_orgId);
    if (mounted) {
      setState(() {
        _classrooms = result['classrooms'] ?? [];
        if (_classrooms.isNotEmpty) {
          _selectedClass = _classrooms[0];
          _fetchDashboardData();
        }
        _isLoadingClasses = false;
      });
    }
  }

  void _fetchDashboardData() {
    _fetchAttendance();
    _fetchAssessments();
  }

  Future<void> _fetchAttendance() async {
    if (_selectedClass == null) return;
    
    setState(() => _isLoadingAttendance = true);
    
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final result = await ApiService.fetchAttendanceByClass(
      _selectedClass!['classId'],
      dateStr,
    );

    if (mounted) {
      if (result['success']) {
        final data = result['data'];
        final attendance = data['attendance'];
        
        setState(() {
          if (attendance != null) {
            _presentCount = attendance['totalPresent'] ?? 0;
            _absentCount = attendance['totalAbsent'] ?? 0;
          } else {
            _presentCount = 0;
            _absentCount = 0;
          }
          final total = _presentCount + _absentCount;
          _attendancePercentage = total > 0 ? (_presentCount / total) * 100 : 0.0;
          _isLoadingAttendance = false;
        });
      } else {
        setState(() {
          _presentCount = 0;
          _absentCount = 0;
          _attendancePercentage = 0.0;
          _isLoadingAttendance = false;
        });
      }
    }
  }

  Future<void> _fetchAssessments() async {
    if (_selectedClass == null) return;
    setState(() => _isLoadingAssessments = true);
    final result = await ApiService.fetchAssessmentsByClass(_selectedClass!['classId']);
    if (mounted) {
      setState(() {
        _assessments = result['data']?['assessments'] ?? [];
        _filteredAssessments = _assessments;
        _isLoadingAssessments = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.teal[900]!,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final className = _selectedClass?['className'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoadingClasses
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: _fetchClassrooms,
              color: Colors.teal,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Class Selection Dropdown
                          _buildClassDropdown(),
                          const SizedBox(height: 20),
                          
                          // Attendance Summary Card
                          _buildAttendanceCard(),
                          
                          const SizedBox(height: 32),
                          
                          // Assessments Section Header
                          Text(
                            'Assessments for $className',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Search Bar
                          _buildSearchBar(),
                          const SizedBox(height: 16),

                          // Assessments List
                          if (_isLoadingAssessments)
                            const Center(child: CircularProgressIndicator(color: Colors.teal))
                          else if (_filteredAssessments.isEmpty)
                            _buildEmptyAssessments()
                          else
                            ..._filteredAssessments.map((a) => _buildAssessmentCard(a)).toList(),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Manage classes & assessments',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeacherNotificationScreen()),
                  ).then((_) {
                    // Trigger re-fetch in TeacherMainScreen
                    teacherNotifCountNotifier.value++;
                  });
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: teacherNotifCountNotifier,
                      builder: (context, count, _) {
                        if (count <= 0) return const SizedBox.shrink();
                        return Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search assessments...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.teal, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.teal.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedClass,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.teal, size: 20),
          style: const TextStyle(
            color: Colors.teal,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(3),
          items: _classrooms.map((cls) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: cls as Map<String, dynamic>,
              child: Text(cls['className'] ?? 'Unknown Class'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedClass = val;
              _searchController.clear();
            });
            _fetchDashboardData();
          },
        ),
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1FDFB),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.teal.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}",
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.teal),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Circular Progress
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 75,
                      height: 75,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 7,
                        color: Colors.teal.withOpacity(0.05),
                      ),
                    ),
                    SizedBox(
                      width: 75,
                      height: 75,
                      child: CircularProgressIndicator(
                        value: _attendancePercentage / 100,
                        strokeWidth: 7,
                        color: Colors.teal,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${_attendancePercentage.toInt()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Column(
                  children: [
                    _buildStatRow('Present', _presentCount, const Color(0xFFE8F5E9), Colors.green[700]!),
                    const SizedBox(height: 10),
                    _buildStatRow('Absent', _absentCount, const Color(0xFFFFEBEE), Colors.red[700]!),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> assessment) {
    final date = assessment['createdAt'] != null 
        ? DateTime.parse(assessment['createdAt']).toLocal() 
        : DateTime.now();
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = "${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assessment['title'] ?? 'Untitled Assessment',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: Colors.teal),
              const SizedBox(width: 8),
              Text(
                'Created by: ${assessment['teacherName'] ?? 'Unknown'}',
                style: const TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.teal),
              const SizedBox(width: 8),
              Text(
                'Created on: $dateStr',
                style: const TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssessmentResultsPage(
                      assessmentId: assessment['assessmentId'] ?? '',
                      assessmentTitle: assessment['title'] ?? 'Assessment Results',
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.teal, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Results',
                    style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.teal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAssessments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No assessments found',
            style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

