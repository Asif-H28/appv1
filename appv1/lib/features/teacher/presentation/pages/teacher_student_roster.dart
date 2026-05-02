import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'teacher_student_dashboard.dart';

const Color _accent = Colors.teal;
const String _base = '${ApiConstants.baseUrl}';

class TeacherStudentRoster extends StatefulWidget {
  final String classId;
  final String className;

  const TeacherStudentRoster({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TeacherStudentRoster> createState() => _TeacherStudentRosterState();
}

class _TeacherStudentRosterState extends State<TeacherStudentRoster>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _error = '';
  String _search = '';

  final _searchCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint('[Roster] initState â€” classId="${widget.classId}"');
    _fetchStudents();
  }

  @override
  void didUpdateWidget(TeacherStudentRoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    // âœ… Re-fetch if classId changes
    if (oldWidget.classId != widget.classId) {
      debugPrint(
        '[Roster] classId changed from '
        '"${oldWidget.classId}" â†’ "${widget.classId}"',
      );
      _searchCtrl.clear();
      _search = '';
      _fetchStudents();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = '';
      _students = [];
      _filtered = [];
    });

    // âœ… Use classId directly from widget â€” dynamically set by dashboard
    final classId = widget.classId.trim();

    debugPrint('[Roster] classId: "$classId"');
    debugPrint('[Roster] classId length: ${classId.length}');

    if (classId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No class selected';
      });
      return;
    }

    // âœ… Build URL from dynamic classId
    final uri = Uri.parse('$_base/api/student/class/$classId');
    debugPrint('[Roster] Fetching: $uri');

    try {
      final res = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      debugPrint('[Roster] Status: ${res.statusCode}');
      debugPrint('[Roster] Body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final b = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = b['students'] as List? ?? [];

        debugPrint('[Roster] students count: ${raw.length}');

        final list = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        // Sort alphabetically
        list.sort(
          (a, b) => (a['name']?.toString() ?? '').compareTo(
            b['name']?.toString() ?? '',
          ),
        );

        debugPrint(
          '[Roster] âœ… Loaded ${list.length} students '
          'for class "$classId"',
        );

        setState(() {
          _students = list;
          _filtered = list;
          _loading = false;
          _error = '';
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Error ${res.statusCode}: ${res.body}';
        });
      }
    } catch (e) {
      debugPrint('[Roster] Exception: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Network error: $e';
        });
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _search = query;
      _filtered = query.isEmpty
          ? List.from(_students)
          : _students.where((s) {
              final name = s['name']?.toString().toLowerCase() ?? '';
              final email = s['email']?.toString().toLowerCase() ?? '';
              return name.contains(query.toLowerCase()) ||
                  email.contains(query.toLowerCase());
            }).toList();
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // â”€â”€ Search bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
                suffixIcon: _search.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade400,
                          size: 16,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),

        // â”€â”€ Count + refresh row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: Row(
            children: [
              if (!_loading)
                Text(
                  _error.isNotEmpty
                      ? _error
                      : '${_filtered.length} student'
                            '${_filtered.length == 1 ? '' : 's'}'
                            ' Â· ${widget.className}',
                  style: TextStyle(
                    fontSize: 11,
                    color: _error.isNotEmpty
                        ? Colors.red
                        : const Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const Spacer(),
              // âœ… Always-visible refresh button
              GestureDetector(
                onTap: _fetchStudents,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _accent.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.refresh_rounded, color: _accent, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // â”€â”€ Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Expanded(
          child: _loading
              ? _buildLoading()
              : _error.isNotEmpty && _filtered.isEmpty
              ? _buildErrorState()
              : _filtered.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: _accent,
                  onRefresh: _fetchStudents,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 32),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _studentCard(_filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  // â”€â”€ Loading â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
          const SizedBox(height: 12),
          Text(
            'Loading students...',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Error state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Failed to load students',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error,
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _fetchStudents,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildEmpty() {
    return Center(
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
              Icons.people_outline_rounded,
              color: _accent,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _search.isNotEmpty ? 'No students found' : 'No students yet',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _search.isNotEmpty
                ? 'Try a different name or email'
                : 'Students will appear once they join',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF888888)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // â”€â”€ Student card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _studentCard(Map<String, dynamic> student) {
    final name = student['name']?.toString() ?? 'Unknown';
    final email = student['email']?.toString() ?? '';
    final phone = student['phone']?.toString() ?? '';
    final joinStatus = student['joinStatus']?.toString() ?? '';
    final isApproved = joinStatus == 'approved';

    return GestureDetector(
      onTap: () {
        // âœ… Pass dynamic classId from widget â€” not hardcoded
        debugPrint(
          '[Roster] Tapped student: '
          '${student['studentId']} â€” ${student['name']}',
        );
        debugPrint('[Roster] Navigating with classId: "${widget.classId}"');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherStudentDashboard(
              student: student,
              classId: widget.classId, // âœ… Dynamic â€” from selected class
              className: widget.className,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _accent.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + email + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 10,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Status badge + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? Colors.green.withOpacity(0.08)
                        : Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isApproved
                          ? Colors.green.withOpacity(0.25)
                          : Colors.orange.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    isApproved ? 'Active' : 'Pending',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isApproved ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

