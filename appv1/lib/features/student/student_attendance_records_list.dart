import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

const Color _accent = Colors.teal;

class StudentAttendanceRecordsList extends StatefulWidget {
  final List<Map<String, dynamic>> records;
  const StudentAttendanceRecordsList({required this.records});

  @override
  _StudentAttendanceRecordsListState createState() =>
      _StudentAttendanceRecordsListState();
}

class _StudentAttendanceRecordsListState
    extends State<StudentAttendanceRecordsList> {
  String _statusFilter = 'All'; // All | Present | Absent

  // ── Active filter state ───────────────────────────────
  DateTime? _selectedDate; // exact date filter
  String? _selectedMonth; // "Mar 2026" format

  // ── Filter mode ───────────────────────────────────────
  _FilterMode _filterMode = _FilterMode.none;

  // ── Filtered list ─────────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    return widget.records.where((r) {
      // status filter
      if (_statusFilter != 'All') {
        final att = r['attendance']?.toString() ?? '';
        if (att.toLowerCase() != _statusFilter.toLowerCase()) return false;
      }

      final dt = DateTime.tryParse(r['date']?.toString() ?? '');
      if (dt == null) return true;

      // exact date filter
      if (_filterMode == _FilterMode.date && _selectedDate != null) {
        final d = _selectedDate!;
        return dt.year == d.year && dt.month == d.month && dt.day == d.day;
      }

      // month filter
      if (_filterMode == _FilterMode.month && _selectedMonth != null) {
        return _monthKey(dt) == _selectedMonth;
      }

      return true;
    }).toList();
  }

  // ── Helpers ───────────────────────────────────────────

  String _monthKey(DateTime dt) {
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[dt.month]} ${dt.year}';
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[dt.weekday]}, ${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _dayInitial(String raw) {
    try {
      return '${DateTime.parse(raw).toLocal().day}';
    } catch (_) {
      return '?';
    }
  }

  String _monthShort(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const m = [
        '',
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      return m[dt.month];
    } catch (_) {
      return '';
    }
  }

  // ── Active filter description for chip ───────────────
  String get _activeFilterLabel {
    if (_filterMode == _FilterMode.date && _selectedDate != null) {
      final dt = _selectedDate!;
      const m = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${m[dt.month]} ${dt.year}';
    }
    if (_filterMode == _FilterMode.month && _selectedMonth != null) {
      return _selectedMonth!;
    }
    return '';
  }

  bool get _hasActiveFilter => _filterMode != _FilterMode.none;

  // ── Show filter bottom sheet ──────────────────────────
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterBottomSheet(
        currentMode: _filterMode,
        selectedDate: _selectedDate,
        selectedMonth: _selectedMonth,
        records: widget.records,
        onApply: (mode, date, month) {
          setState(() {
            _filterMode = mode;
            _selectedDate = date;
            _selectedMonth = month;
          });
        },
        onClear: () {
          setState(() {
            _filterMode = _FilterMode.none;
            _selectedDate = null;
            _selectedMonth = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.list_alt_rounded, size: 15, color: _accent),
            SizedBox(width: 5),
            Text(
              'Daily Records',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            Spacer(),
            Text(
              '${filtered.length} records',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            SizedBox(width: 10),

            // ── Filter icon button ──
            GestureDetector(
              onTap: _showFilterSheet,
              child: Container(
                padding: EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _hasActiveFilter ? _accent : Colors.grey[100],
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: _hasActiveFilter ? _accent : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 15,
                      color: _hasActiveFilter
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    if (_hasActiveFilter) ...[
                      SizedBox(width: 4),
                      Text(
                        'Filtered',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),

        // ── Status filter chips ──
        Row(
          children: ['All', 'Present', 'Absent'].map((f) {
            final isSelected = _statusFilter == f;
            Color chipColor = _accent;
            if (f == 'Present') chipColor = Colors.green[600]!;
            if (f == 'Absent') chipColor = Colors.red[600]!;
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _statusFilter = f),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? chipColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isSelected ? chipColor : Colors.grey[200]!,
                    ),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // ── Active filter chip (date/month) ──
        if (_hasActiveFilter) ...[
          SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _accent.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _filterMode == _FilterMode.date
                          ? Icons.today_rounded
                          : Icons.calendar_month_rounded,
                      size: 12,
                      color: _accent,
                    ),
                    SizedBox(width: 5),
                    Text(
                      _filterMode == _FilterMode.date
                          ? 'Date: $_activeFilterLabel'
                          : 'Month: $_activeFilterLabel',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() {
                        _filterMode = _FilterMode.none;
                        _selectedDate = null;
                        _selectedMonth = null;
                      }),
                      child: Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        SizedBox(height: 10),

        // ── Records ──
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  color: Colors.grey[400],
                  size: 32,
                ),
                SizedBox(height: 10),
                Text(
                  'No records found',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (_hasActiveFilter) ...[
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _filterMode = _FilterMode.none;
                      _selectedDate = null;
                      _selectedMonth = null;
                    }),
                    child: Text(
                      'Clear filter',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          ...filtered.map((r) {
            final att = r['attendance']?.toString() ?? '';
            final isPresent = att.toLowerCase() == 'present';
            final statusColor = isPresent
                ? Colors.green[600]!
                : Colors.red[600]!;
            final dateRaw = r['date']?.toString() ?? '';

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isPresent
                      ? Colors.green.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ── Left color strip ──
                  Container(
                    width: 4,
                    height: 62,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(3),
                        bottomLeft: Radius.circular(3),
                      ),
                    ),
                  ),

                  // ── Date box ──
                  Container(
                    width: 52,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Text(
                          _dayInitial(dateRaw),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _monthShort(dateRaw),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(width: 1, height: 36, color: Colors.grey[200]),
                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      _formatDate(dateRaw),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // ── Status badge ──
                  Container(
                    margin: EdgeInsets.only(right: 12),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPresent
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 12,
                          color: statusColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          att,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// FILTER MODE ENUM
// ─────────────────────────────────────────────────────────

enum _FilterMode { none, date, month }

// ─────────────────────────────────────────────────────────
// FILTER BOTTOM SHEET
// ─────────────────────────────────────────────────────────

class _FilterBottomSheet extends StatefulWidget {
  final _FilterMode currentMode;
  final DateTime? selectedDate;
  final String? selectedMonth;
  final List<Map<String, dynamic>> records;
  final void Function(_FilterMode, DateTime?, String?) onApply;
  final VoidCallback onClear;

  const _FilterBottomSheet({
    required this.currentMode,
    required this.selectedDate,
    required this.selectedMonth,
    required this.records,
    required this.onApply,
    required this.onClear,
  });

  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  DateTime? _pickedDate;
  String? _pickedMonth;

  // ── Unique months from records ────────────────────────
  List<String> get _availableMonths {
    final seen = <String>{};
    final list = <String>[];
    for (final r in widget.records) {
      final dt = DateTime.tryParse(r['date']?.toString() ?? '');
      if (dt == null) continue;
      final key = _monthKey(dt);
      if (seen.add(key)) list.add(key);
    }
    return list;
  }

  // ── Dates that have records ───────────────────────────
  Set<String> get _availableDates {
    return widget.records
        .map((r) {
          final dt = DateTime.tryParse(r['date']?.toString() ?? '');
          if (dt == null) return '';
          return '${dt.year}-${dt.month}-${dt.day}';
        })
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  String _monthKey(DateTime dt) {
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[dt.month]} ${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    final initTab = widget.currentMode == _FilterMode.month ? 1 : 0;
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: initTab);
    _pickedDate = widget.selectedDate;
    _pickedMonth = widget.selectedMonth;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Open native date picker ───────────────────────────
  Future<void> _pickDate() async {
    // find date range from records
    final dates = widget.records
        .map((r) => DateTime.tryParse(r['date']?.toString() ?? ''))
        .where((d) => d != null)
        .cast<DateTime>()
        .toList();

    final first = dates.isNotEmpty
        ? dates.reduce((a, b) => a.isBefore(b) ? a : b)
        : DateTime(2024);
    final last = dates.isNotEmpty
        ? dates.reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? last,
      firstDate: first,
      lastDate: last,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: _accent,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
      // Only enable dates that have records
      selectableDayPredicate: (day) {
        final key = '${day.year}-${day.month}-${day.day}';
        return _availableDates.contains(key);
      },
    );

    if (picked != null) {
      setState(() => _pickedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = _availableMonths;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 16),

          // ── Title + clear ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Filter Records',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),

          // ── Tab bar ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(3),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                padding: EdgeInsets.all(3),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.today_rounded, size: 13),
                        SizedBox(width: 5),
                        Text('By Date'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 13),
                        SizedBox(width: 5),
                        Text('By Month'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // ── Tab content ──
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Date picker tab ──
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a specific date to view attendance',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 14),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _pickedDate != null
                                ? _accent.withOpacity(0.05)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: _pickedDate != null
                                  ? _accent.withOpacity(0.3)
                                  : Colors.grey[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Icon(
                                  Icons.today_rounded,
                                  color: _accent,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pickedDate != null
                                          ? _formatDate(
                                              _pickedDate!.toIso8601String(),
                                            )
                                          : 'Tap to pick a date',
                                      style: TextStyle(
                                        fontWeight: _pickedDate != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                        color: _pickedDate != null
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    if (_pickedDate == null)
                                      Text(
                                        'Only dates with records are selectable',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_pickedDate != null) ...[
                        SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _pickedDate = null),
                          child: Row(
                            children: [
                              Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: Colors.red[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Clear date',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Month picker tab ──
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a month to view all records',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: months.isEmpty
                            ? Center(
                                child: Text(
                                  'No months available',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : GridView.count(
                                crossAxisCount: 3,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                children: months.map((m) {
                                  final isSelected = _pickedMonth == m;
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _pickedMonth = isSelected ? null : m;
                                    }),
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 180),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? _accent
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: isSelected
                                              ? _accent
                                              : Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          m,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                            fontSize: 11.5,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Apply button ──
          Padding(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  final tab = _tabCtrl.index;
                  if (tab == 0 && _pickedDate != null) {
                    widget.onApply(_FilterMode.date, _pickedDate, null);
                  } else if (tab == 1 && _pickedMonth != null) {
                    widget.onApply(_FilterMode.month, null, _pickedMonth);
                  } else {
                    widget.onClear();
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                child: Text(
                  'Apply Filter',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[dt.weekday]}, ${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
