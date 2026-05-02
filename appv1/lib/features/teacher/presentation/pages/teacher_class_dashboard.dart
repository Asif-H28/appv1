import 'package:appv1/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color _accent = Colors.teal;
const String _base = '${ApiConstants.baseUrl}';

class TeacherClassDashboard extends StatefulWidget {
  final String classId;
  final String className;

  const TeacherClassDashboard({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TeacherClassDashboard> createState() => _TeacherClassDashboardState();
}

class _TeacherClassDashboardState extends State<TeacherClassDashboard> {
  bool _loading = true;

  // Today attendance â€” from attendance.totalPresent / totalAbsent
  int? _todayPresent;
  int? _todayAbsent;
  bool _attNotMarked = false;

  // Overall attendance â€” sum(totalPresent) / sum(totalPresent+totalAbsent)
  double _overallAttPct = 0;
  int _totalDaysMarked = 0;

  // Results
  double _avgPct = 0;
  int _passCount = 0;
  int _failCount = 0;
  List<Map<String, dynamic>> _topPerformers = [];

  // Tests
  int _publishedTests = 0;
  int _pendingTests = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([
      _fetchTodayAtt(),
      _fetchHistoryAtt(),
      _fetchResults(),
      _fetchTests(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  // â”€â”€ Today: attendance is a single object â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _fetchTodayAtt() async {
    try {
      final res = await http.get(
        Uri.parse(
          '$_base/api/attendance/class/${widget.classId}/date/${_todayStr()}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final b = jsonDecode(res.body) as Map<String, dynamic>;
        // attendance is a single object, not a list
        final att = b['attendance'] as Map<String, dynamic>?;
        if (att == null) {
          _attNotMarked = true;
          return;
        }
        _todayPresent = att['totalPresent'] as int? ?? 0;
        _todayAbsent = att['totalAbsent'] as int? ?? 0;
      } else {
        _attNotMarked = true;
      }
    } catch (e) {
      debugPrint('[TodayAtt] $e');
      _attNotMarked = true;
    }
  }

  // â”€â”€ History: attendances is a list of objects â”€â”€â”€â”€â”€
  Future<void> _fetchHistoryAtt() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/attendance/class/${widget.classId}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final b = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (b['attendances'] as List? ?? []);
        if (list.isEmpty) return;

        int sumPresent = 0, sumTotal = 0;
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          final p = (m['totalPresent'] as int?) ?? 0;
          final a = (m['totalAbsent'] as int?) ?? 0;
          sumPresent += p;
          sumTotal += p + a;
        }
        _overallAttPct = sumTotal > 0 ? (sumPresent / sumTotal) * 100 : 0;
        _totalDaysMarked = list.length;
      }
    } catch (e) {
      debugPrint('[HistoryAtt] $e');
    }
  }

  // â”€â”€ Results â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _fetchResults() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/result/class/${widget.classId}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final b = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (b['results'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (results.isEmpty) return;

        double sumPct = 0;
        int pass = 0, fail = 0;
        for (final r in results) {
          // percentage field is directly available
          final pct = (r['percentage'] as num?)?.toDouble() ?? 0;
          sumPct += pct;
          final status = r['overallStatus']?.toString().toLowerCase() ?? '';
          if (status == 'pass')
            pass++;
          else if (status == 'fail')
            fail++;
        }

        // Top 3 performers
        final sorted = List<Map<String, dynamic>>.from(results)
          ..sort(
            (a, b) => ((b['percentage'] as num?) ?? 0).compareTo(
              (a['percentage'] as num?) ?? 0,
            ),
          );

        _avgPct = results.isNotEmpty ? sumPct / results.length : 0;
        _passCount = pass;
        _failCount = fail;
        _topPerformers = sorted.take(3).toList();
      }
    } catch (e) {
      debugPrint('[Results] $e');
    }
  }

  // â”€â”€ Tests cross-reference with results â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _fetchTests() async {
    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse('$_base/api/test/class/${widget.classId}'),
          headers: {'Content-Type': 'application/json'},
        ),
        http.get(
          Uri.parse('$_base/api/result/class/${widget.classId}'),
          headers: {'Content-Type': 'application/json'},
        ),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final tests = (jsonDecode(responses[0].body)['tests'] as List? ?? []);
        final results =
            (jsonDecode(responses[1].body)['results'] as List? ?? []);

        // Collect all testIds that have at least one result
        final publishedIds = results
            .map((r) => (r as Map)['testId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();

        int published = 0, pending = 0;
        for (final t in tests) {
          final id = (t as Map)['testId']?.toString() ?? '';
          if (publishedIds.contains(id))
            published++;
          else
            pending++;
        }
        _publishedTests = published;
        _pendingTests = pending;
      }
    } catch (e) {
      debugPrint('[Tests] $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodayAttendance(),
            const SizedBox(height: 12),
            _buildOverallRow(),
            const SizedBox(height: 12),
            _buildTestsCard(),
            const SizedBox(height: 12),
            if (_topPerformers.isNotEmpty) _buildTopPerformers(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Today attendance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTodayAttendance() {
    final total = (_todayPresent ?? 0) + (_todayAbsent ?? 0);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.today_rounded, "Today's Attendance"),
          const SizedBox(height: 12),
          if (_attNotMarked)
            _emptyBox(
              Icons.event_busy_rounded,
              'Not marked yet',
              'Attendance has not been taken today',
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    _attBox(
                      color: Colors.green,
                      icon: Icons.check_circle_rounded,
                      label: 'Present',
                      value: _todayPresent ?? 0,
                    ),
                    const SizedBox(width: 8),
                    _attBox(
                      color: Colors.red,
                      icon: Icons.cancel_rounded,
                      label: 'Absent',
                      value: _todayAbsent ?? 0,
                    ),
                    const SizedBox(width: 8),
                    _attBox(
                      color: Colors.blue.shade400,
                      icon: Icons.people_rounded,
                      label: 'Total',
                      value: total,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _progressBar(
                  value: total > 0 ? (_todayPresent ?? 0) / total : 0,
                  color: Colors.green,
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    total > 0
                        ? '${((_todayPresent ?? 0) * 100 ~/ total)}% present today'
                        : '',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // â”€â”€ Overall attendance + results â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildOverallRow() {
    final attColor = _overallAttPct >= 75 ? Colors.green : Colors.orange;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(Icons.how_to_reg_rounded, 'Attendance'),
                const SizedBox(height: 12),
                Text(
                  '${_overallAttPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: attColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_totalDaysMarked days marked',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 8),
                _progressBar(
                  value: (_overallAttPct / 100).clamp(0.0, 1.0),
                  color: attColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(Icons.bar_chart_rounded, 'Results'),
                const SizedBox(height: 12),
                Text(
                  '${_avgPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _gradeColor(_avgPct),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'class average',
                  style: TextStyle(fontSize: 10, color: Color(0xFF888888)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniChip('$_passCount Pass', Colors.green),
                    const SizedBox(width: 5),
                    _miniChip('$_failCount Fail', Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // â”€â”€ Tests â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTestsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.quiz_rounded, 'Tests Overview'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statusBox(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Published',
                  value: _publishedTests,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statusBox(
                  icon: Icons.hourglass_bottom_rounded,
                  label: 'Pending',
                  value: _pendingTests,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statusBox(
                  icon: Icons.quiz_rounded,
                  label: 'Total',
                  value: _publishedTests + _pendingTests,
                  color: _accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // â”€â”€ Top performers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTopPerformers() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.emoji_events_rounded, 'Top Performers'),
          const SizedBox(height: 12),
          ..._topPerformers.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final name = r['studentName']?.toString() ?? 'Student';
            final pct = (r['percentage'] as num?)?.toDouble() ?? 0;
            final grade = r['grade']?.toString() ?? '';
            final medals = ['ðŸ¥‡', 'ðŸ¥ˆ', 'ðŸ¥‰'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Text(medals[i], style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (grade.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _gradeColor(pct).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: _gradeColor(pct).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        grade,
                        style: TextStyle(
                          color: _gradeColor(pct),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: _gradeColor(pct),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // â”€â”€ Shared widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  Widget _attBox({
    required Color color,
    required IconData icon,
    required String label,
    required int value,
  }) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 5),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF888888)),
          ),
        ],
      ),
    ),
  );

  Widget _statusBox({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: Color(0xFF888888)),
        ),
      ],
    ),
  );

  Widget _miniChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
      ),
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

  Color _gradeColor(double pct) {
    if (pct >= 75) return Colors.green;
    if (pct >= 50) return Colors.orange;
    return Colors.red;
  }
}

