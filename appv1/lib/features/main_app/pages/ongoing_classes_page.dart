import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';

enum ClassStatus { free, live, upcoming, completed }

class OngoingClassesPage extends StatefulWidget {
  const OngoingClassesPage({super.key});

  @override
  State<OngoingClassesPage> createState() => _OngoingClassesPageState();
}

class _OngoingClassesPageState extends State<OngoingClassesPage> with SingleTickerProviderStateMixin {
  String _orgId = '';
  String _selectedDay = '';
  String _selectedTime = '';
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _allClasses = [];
  List<dynamic> _filteredClasses = [];
  final TextEditingController _searchCtrl = TextEditingController();
  
  late AnimationController _pulseController;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _initDateTime();
    
    // Set up pulsing animation for the "LIVE" indicator dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _searchCtrl.addListener(_onSearchChanged);
    _loadOrgAndFetch();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initDateTime() {
    final now = DateTime.now();
    // Get weekday name
    _selectedDay = _daysOfWeek[now.weekday - 1];
    // Format hour and minute
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    _selectedTime = '$hour:$minute';
  }

  Future<void> _loadOrgAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    _fetchOngoingClasses();
  }

  Future<void> _fetchOngoingClasses() async {
    if (_orgId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Organization ID is not set. Please log in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final endpoint = '/timetable/org/$_orgId/ongoing?day=$_selectedDay&time=$_selectedTime';
      final response = await ApiService.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _allClasses = data['classrooms'] ?? data['classes'] ?? [];
            _filteredClasses = List.from(_allClasses);
            _isLoading = false;
          });
          // Trigger local filtering in case search text already exists
          _onSearchChanged();
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load ongoing classes.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: Failed to fetch schedule.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredClasses = List.from(_allClasses);
      } else {
        _filteredClasses = _allClasses.where((c) {
          final className = (c['className'] ?? '').toString().toLowerCase();
          final ongoing = c['ongoingPeriod'] ?? {};
          final subject = (ongoing['subjectName'] ?? '').toString().toLowerCase();
          final teacher = (ongoing['teacherName'] ?? '').toString().toLowerCase();
          final message = (c['message'] ?? '').toString().toLowerCase();

          return className.contains(query) ||
              subject.contains(query) ||
              teacher.contains(query) ||
              message.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final timeParts = _selectedTime.split(':');
    final initialHour = int.tryParse(timeParts[0]) ?? 8;
    final initialMinute = int.tryParse(timeParts[1]) ?? 30;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minStr = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _selectedTime = '$hourStr:$minStr';
      });
      _fetchOngoingClasses();
    }
  }

  String _formatTime12Hour(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$formattedHour:$minute $ampm';
    } catch (_) {
      return time24;
    }
  }

  int _compareTimeStrings(String timeA, String timeB) {
    try {
      final partsA = timeA.split(':');
      final partsB = timeB.split(':');
      final hourA = int.parse(partsA[0]);
      final minA = int.parse(partsA[1]);
      final hourB = int.parse(partsB[0]);
      final minB = int.parse(partsB[1]);
      
      if (hourA != hourB) {
        return hourA.compareTo(hourB);
      }
      return minA.compareTo(minB);
    } catch (_) {
      return 0;
    }
  }

  bool _isFiltered() {
    final now = DateTime.now();
    final currentDay = _daysOfWeek[now.weekday - 1];
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final currentTime = '$hour:$minute';
    return _selectedDay != currentDay || _selectedTime != currentTime;
  }

  ClassStatus _determineClassStatus(Map<String, dynamic>? ongoingPeriod) {
    if (ongoingPeriod == null) return ClassStatus.free;

    final startTime = ongoingPeriod['startTime'] ?? '';
    final endTime = ongoingPeriod['endTime'] ?? '';
    if (startTime.isEmpty || endTime.isEmpty) {
      return ClassStatus.live;
    }

    final now = DateTime.now();
    final currentDay = _daysOfWeek[now.weekday - 1];

    final selectedDayIdx = _daysOfWeek.indexOf(_selectedDay);
    final currentDayIdx = _daysOfWeek.indexOf(currentDay);

    if (selectedDayIdx < currentDayIdx) {
      return ClassStatus.completed;
    } else if (selectedDayIdx > currentDayIdx) {
      return ClassStatus.upcoming;
    } else {
      // Today. Compare class start/end times with the current real-world time.
      final curHour = now.hour.toString().padLeft(2, '0');
      final curMin = now.minute.toString().padLeft(2, '0');
      final currentTimeStr = '$curHour:$curMin';

      final startDiff = _compareTimeStrings(currentTimeStr, startTime);
      final endDiff = _compareTimeStrings(currentTimeStr, endTime);

      if (startDiff < 0) {
        return ClassStatus.upcoming;
      } else if (endDiff > 0) {
        return ClassStatus.completed;
      } else {
        return ClassStatus.live;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ongoing Classes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_rounded, color: Colors.white),
            tooltip: 'Reset to current time',
            onPressed: () {
              setState(() {
                _initDateTime();
              });
              _fetchOngoingClasses();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Panel: Day & Time Picker
          _buildFilterPanel(),
          
          // Search Box
          _buildSearchBox(),

          // Main Content List
          Expanded(
            child: RefreshIndicator(
              color: Colors.teal,
              onRefresh: _fetchOngoingClasses,
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Days Horizontal Scrolling Pill List
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _daysOfWeek.length,
              itemBuilder: (context, index) {
                final day = _daysOfWeek[index];
                final isSelected = day == _selectedDay;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                    });
                    _fetchOngoingClasses();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.teal.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.teal : Colors.teal.withOpacity(0.15),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.teal[800],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Time Picker Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, color: Colors.teal, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Time:',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (_isFiltered()) ...[
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            _initDateTime();
                          });
                          _fetchOngoingClasses();
                        },
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text(
                          'Reset',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    GestureDetector(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal[300]!, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              _formatTime12Hour(_selectedTime),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit_calendar_rounded, color: Colors.teal, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search by class, subject, or teacher...',
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.teal, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    FocusScope.of(context).unfocus();
                  },
                  child: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.teal, width: 1.5),
          ),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      );
    }

    if (_errorMessage != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to Load Timetable',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchOngoingClasses,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredClasses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_empty_rounded, color: Colors.teal, size: 48),
                ),
                const SizedBox(height: 18),
                Text(
                  _searchCtrl.text.isNotEmpty ? 'No Matching Classes' : 'No Classes Scheduled',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchCtrl.text.isNotEmpty
                      ? 'Try modifying your search query to find the desired class.'
                      : 'There are no active classes or periods registered for $_selectedDay at ${_formatTime12Hour(_selectedTime)}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _filteredClasses.length,
      itemBuilder: (context, index) {
        final c = _filteredClasses[index];
        
        final ongoingPeriod = c['ongoingPeriod'];
        final ClassStatus status = _determineClassStatus(ongoingPeriod);

        final bool isLive = status == ClassStatus.live;
        final bool isUpcoming = status == ClassStatus.upcoming;
        final bool isCompleted = status == ClassStatus.completed;
        final bool isFree = status == ClassStatus.free;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLive 
                  ? Colors.teal.withOpacity(0.35) 
                  : isUpcoming 
                      ? Colors.indigo.withOpacity(0.30)
                      : const Color(0xFFE2E8F0),
              width: (isLive || isUpcoming) ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isLive 
                    ? Colors.teal.withOpacity(0.06) 
                    : isUpcoming 
                        ? Colors.indigo.withOpacity(0.04)
                        : Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Top-right light gradient blob for active or upcoming classes
                if (isLive || isUpcoming)
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLive 
                            ? Colors.teal.withOpacity(0.06)
                            : Colors.indigo.withOpacity(0.05),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Class Name & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isLive 
                                      ? const Color(0xFFE6F2F1) 
                                      : isUpcoming 
                                          ? const Color(0xFFEEF2FF)
                                          : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.class_rounded,
                                  color: isLive 
                                      ? Colors.teal 
                                      : isUpcoming 
                                          ? Colors.indigo
                                          : const Color(0xFF64748B),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c['className'] ?? 'Unknown Class',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Details Section
                      if (!isFree) ...[
                        _buildLivePeriodDetails(c['ongoingPeriod'] ?? {}, status),
                      ] else ...[
                        _buildFreePeriodDetails(c['message'] ?? 'Free Period / Break'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ClassStatus status) {
    switch (status) {
      case ClassStatus.live:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _pulseController.value,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 5),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      case ClassStatus.upcoming:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'UPCOMING',
            style: TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        );
      case ClassStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'COMPLETED',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        );
      case ClassStatus.free:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'FREE',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        );
    }
  }

  Widget _buildLivePeriodDetails(Map<String, dynamic> op, ClassStatus status) {
    final startTime = op['startTime'] != null ? _formatTime12Hour(op['startTime']) : '';
    final endTime = op['endTime'] != null ? _formatTime12Hour(op['endTime']) : '';
    final periodNum = op['periodNumber'] ?? '';

    final Color themeColor = status == ClassStatus.live
        ? Colors.teal
        : status == ClassStatus.upcoming
            ? Colors.indigo
            : const Color(0xFF475569);

    final Color lightBgColor = status == ClassStatus.live
        ? Colors.teal.withOpacity(0.1)
        : status == ClassStatus.upcoming
            ? Colors.indigo.withOpacity(0.1)
            : const Color(0xFFF1F5F9);

    final Color pillBorderColor = status == ClassStatus.live
        ? Colors.teal[200]!
        : status == ClassStatus.upcoming
            ? Colors.indigo[200]!
            : const Color(0xFFCBD5E1);

    final Color pillTextColor = status == ClassStatus.live
        ? Colors.teal[800]!
        : status == ClassStatus.upcoming
            ? Colors.indigo[800]!
            : const Color(0xFF475569);

    return Column(
      children: [
        // Subject Title
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                op['subjectName'] ?? 'No Subject',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: themeColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (periodNum.toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: pillBorderColor, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Period $periodNum',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: pillTextColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 12),
        // Teacher & Timings Rows
        Row(
          children: [
            // Teacher Info
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: lightBgColor,
                    child: Text(
                      (op['teacherName'] ?? 'T').toString().isNotEmpty 
                          ? (op['teacherName'] ?? 'T')[0].toUpperCase() 
                          : 'T',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: themeColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      op['teacherName'] ?? 'No Teacher Assigned',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Timing Info
            if (startTime.isNotEmpty && endTime.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: Color(0xFF64748B), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$startTime - $endTime',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFreePeriodDetails(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.coffee_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
