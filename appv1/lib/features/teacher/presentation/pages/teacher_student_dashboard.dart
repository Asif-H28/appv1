import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;

const Color _accent = Colors.teal;
const String _base = '${ApiConstants.baseUrl}';

class TeacherStudentDashboard extends StatefulWidget {
  final Map<String, dynamic> student;
  final String classId;
  final String className;

  const TeacherStudentDashboard({
    super.key,
    required this.student,
    required this.classId,
    required this.className,
  });

  @override
  State<TeacherStudentDashboard> createState() =>
      _TeacherStudentDashboardState();
}

class _TeacherStudentDashboardState extends State<TeacherStudentDashboard> {
  bool _loading = true;

  // ── Attendance — from API direct fields ────────────
  int _totalDays = 0;
  int _totalPresent = 0;
  int _totalAbsent = 0;
  double _attPct = 0;
  List<Map<String, dynamic>> _attRecords = [];

  // ── Results ────────────────────────────────────────
  List<Map<String, dynamic>> _results = [];
  double _avgPct = 0;
  int _passCount = 0;
  int _failCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ── studentId from passed student map ─────────────
  String get _studentId => widget.student['studentId']?.toString() ?? '';

  String get _studentName => widget.student['name']?.toString() ?? 'Student';

  String get _studentEmail => widget.student['email']?.toString() ?? '';

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_fetchAtt(), _fetchResults()]);
    if (mounted) setState(() => _loading = false);
  }

  // ── Attendance ─────────────────────────────────────
  Future<void> _fetchAtt() async {
    if (_studentId.isEmpty) {
      debugPrint('[StudentAtt] ⚠️ studentId is empty — skipping');
      return;
    }

    // ✅ Correct endpoint
    final url = '$_base/api/attendance/summary/${widget.classId}/$_studentId';

    debugPrint('[StudentAtt] URL = "$url"');

    try {
      final res = await http
          .get(Uri.parse(url), headers: await ApiService.getHeaders())
          .timeout(const Duration(seconds: 15));

      debugPrint('[StudentAtt] status: ${res.statusCode}');
      debugPrint('[StudentAtt] body: ${res.body}');

      if (res.statusCode == 200) {
        final b = jsonDecode(res.body) as Map<String, dynamic>;

        _totalDays = (b['totalDays'] as int?) ?? 0;
        _totalPresent = (b['totalPresent'] as int?) ?? 0;
        _totalAbsent = (b['totalAbsent'] as int?) ?? 0;

        // Handles both "92.00%" string and numeric
        final raw = b['attendancePercentage'];
        if (raw is num) {
          _attPct = raw.toDouble();
        } else if (raw is String) {
          _attPct = double.tryParse(raw.replaceAll('%', '').trim()) ?? 0;
        }

        _attRecords = (b['records'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        debugPrint(
          '[StudentAtt] ✅ days=$_totalDays '
          'present=$_totalPresent absent=$_totalAbsent pct=$_attPct',
        );
      }
    } catch (e) {
      debugPrint('[StudentAtt] ❌ Exception: $e');
    }
  }

  // ── Results ────────────────────────────────────────
  Future<void> _fetchResults() async {
    if (_studentId.isEmpty) return;
    try {
      final url = '$_base/api/result/student/$_studentId';
      debugPrint('[StudentResults] URL: $url');
      final res = await http.get(
        Uri.parse(url),
        headers: await ApiService.getHeaders(),
      );
      debugPrint('[StudentResults] status: ${res.statusCode}');
      debugPrint(
        '[StudentResults] body: ${res.body.substring(0, res.body.length.clamp(0, 300))}',
      );

      if (res.statusCode == 200) {
        final b = jsonDecode(res.body) as Map<String, dynamic>;
        // ✅ Key is "results"
        final list = (b['results'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        // Sort newest first by publishedAt
        list.sort(
          (a, b) => (b['publishedAt']?.toString() ?? '').compareTo(
            a['publishedAt']?.toString() ?? '',
          ),
        );

        double sum = 0;
        int pass = 0, fail = 0;
        for (final r in list) {
          // ✅ percentage is a direct num field
          final pct = (r['percentage'] as num?)?.toDouble() ?? 0;
          sum += pct;
          // ✅ overallStatus is "pass" or "fail"
          final status = r['overallStatus']?.toString().toLowerCase() ?? '';
          if (status == 'pass')
            pass++;
          else if (status == 'fail')
            fail++;
        }

        _results = list;
        _avgPct = list.isNotEmpty ? sum / list.length : 0;
        _passCount = pass;
        _failCount = fail;
      }
    } catch (e) {
      debugPrint('[StudentResults] error: $e');
    }
  }

  Color _gradeColor(double pct) {
    if (pct >= 75) return Colors.green;
    if (pct >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _timeAgo(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return _formatDate(raw);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                      strokeWidth: 2.5,
                    ),
                  )
                : RefreshIndicator(
                    color: _accent,
                    onRefresh: _loadAll,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _buildAttCard(),
                          const SizedBox(height: 12),
                          _buildResultsCard(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final joinStatus = widget.student['joinStatus']?.toString() ?? '';
    final isApproved = joinStatus == 'approved';

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
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    _initials(_studentName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + class + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _studentName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? Colors.green.withOpacity(0.25)
                                : Colors.orange.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            isApproved ? 'Active' : 'Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _studentEmail.isNotEmpty
                          ? _studentEmail
                          : widget.className,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // ── Attendance card ────────────────────────────────
  Widget _buildAttCard() {
    final attColor = _attPct >= 75 ? Colors.green : Colors.orange;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.how_to_reg_rounded, 'Attendance'),
          const SizedBox(height: 12),

          // Big % + progress + mini stat boxes
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_attPct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: attColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _progressBar(
                      value: (_attPct / 100).clamp(0.0, 1.0),
                      color: attColor,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$_totalDays total school days',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _miniStatBox(
                      label: 'Present',
                      value: _totalPresent,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _miniStatBox(
                      label: 'Absent',
                      value: _totalAbsent,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Recent attendance records
          if (_attRecords.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),
            const Text(
              'Recent Records',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 8),
            // Show last 5 records
            ...(_attRecords.take(5).map((r) {
              final date = _formatDate(r['date']?.toString());
              final status = r['attendance']?.toString() ?? '';
              final isPresent = status.toLowerCase() == 'present';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPresent ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        date,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isPresent ? Colors.green : Colors.red)
                            .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: (isPresent ? Colors.green : Colors.red)
                              .withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isPresent ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })),
          ],
        ],
      ),
    );
  }

  // ── Results card ───────────────────────────────────
  Widget _buildResultsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + avg badge
          Row(
            children: [
              Expanded(
                child: _cardHeader(Icons.bar_chart_rounded, 'Test Results'),
              ),
              if (_results.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _gradeColor(_avgPct).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: _gradeColor(_avgPct).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Avg ${_avgPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _gradeColor(_avgPct),
                    ),
                  ),
                ),
            ],
          ),

          // Pass / Fail summary chips
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _miniChip('$_passCount Pass', Colors.green),
                const SizedBox(width: 6),
                _miniChip('$_failCount Fail', Colors.red),
                const SizedBox(width: 6),
                _miniChip('${_results.length} Tests', _accent),
              ],
            ),
          ],

          const SizedBox(height: 12),

          if (_results.isEmpty)
            _emptyBox(
              Icons.bar_chart_rounded,
              'No results yet',
              'Results will appear once tests are graded',
            )
          else
            ..._results.map((r) => _resultRow(r)),
        ],
      ),
    );
  }

  Widget _resultRow(Map<String, dynamic> r) {
    // ✅ Use exact field names from API response
    final title = r['testModule']?.toString() ?? 'Test';
    final pct = (r['percentage'] as num?)?.toDouble() ?? 0;
    final scored = (r['totalScoredMarks'] as num?)?.toDouble() ?? 0;
    final max = (r['totalMaximumMarks'] as num?)?.toDouble() ?? 0;
    final grade = r['grade']?.toString() ?? '';
    final status = r['overallStatus']?.toString() ?? '';
    final time = _timeAgo(r['publishedAt']?.toString());
    final color = _gradeColor(pct);

    // Subject results for inline chips
    final subjects = (r['subjectResults'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Grade badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text(
                    grade.isNotEmpty ? grade : '—',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title + marks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${scored.toStringAsFixed(0)} / ${max.toStringAsFixed(0)} marks',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),

              // Pct + status + time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (status == 'pass' ? Colors.green : Colors.red)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      status == 'pass' ? '✓ Pass' : '✗ Fail',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: status == 'pass' ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Subject breakdown chips
          if (subjects.isNotEmpty) ...[
            const SizedBox(height: 9),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: subjects.map((s) {
                final sub = s['subjectName']?.toString() ?? '';
                final scored = (s['scoredMarks'] as num?)?.toDouble() ?? 0;
                final max = (s['maximumScore'] as num?)?.toDouble() ?? 0;
                final sPct = max > 0 ? (scored / max) * 100 : 0.0;
                final sColor = _gradeColor(sPct);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: sColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    '$sub: ${scored.toStringAsFixed(0)}/${max.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: sColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: child,
  );

  Widget _cardHeader(IconData icon, String title) => Row(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Icon(icon, color: _accent, size: 14),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
          color: Color(0xFF1A1A1A),
        ),
      ),
    ],
  );

  Widget _miniStatBox({
    required String label,
    required int value,
    required Color color,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
        ),
      ],
    ),
  );

  Widget _miniChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
    ),
  );

  Widget _progressBar({required double value, required Color color}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: Colors.grey.shade100,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 5,
        ),
      );

  Widget _emptyBox(IconData icon, String title, String sub) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      color: _accent.withOpacity(0.04),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: _accent.withOpacity(0.12)),
    ),
    child: Column(
      children: [
        Icon(icon, color: _accent, size: 22),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          sub,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF888888)),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

