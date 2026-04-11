// view_school_page.dart
// View My School

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'view_school_data.dart';

// ── Palette ───────────────────────────────────────────
const _teal = Color(0xFF00796B);
const _tealDark = Color(0xFF004D40);
const _tealLight = Color(0xFFE0F2F1);
const _textDark = Color(0xFF1A1A1A);
const _textGrey = Color(0xFF6B7280);
const _textLight = Color(0xFF9CA3AF);
const _bgPage = Color(0xFFF2F4F3);
const _bgCard = Colors.white;
const _bgTable = Color(0xFFF5F5F5);
const _border = Color(0xFFE5E7EB);
const _orange = Color(0xFFE65100);

class ViewSchoolPage extends StatefulWidget {
  const ViewSchoolPage({super.key});

  @override
  State<ViewSchoolPage> createState() => _ViewSchoolPageState();
}

class _ViewSchoolPageState extends State<ViewSchoolPage> {
  String _orgId = '';
  String _orgName = '';
  bool _loading = true;
  bool _showAllRoles = false;

  SchoolViewModel? _data;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    _orgName = prefs.getString('userOrg') ?? 'My School';
    await _load();
  }

  Future<void> _load() async {
    if (_orgId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final vm = await ViewSchoolService.loadAll(_orgId);
      if (mounted)
        setState(() {
          _data = vm;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bgPage,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _teal, strokeWidth: 2),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildBasicCard(),
                        const SizedBox(height: 16),
                        _buildManagementCard(),
                        const SizedBox(height: 16),
                        _buildFeeCard(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Sliver hero ───────────────────────────────────────
  Widget _buildSliverAppBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxNameWidth = screenWidth - 32;

    final schoolName = _data?.basic.schoolName.isNotEmpty == true
        ? _data!.basic.schoolName
        : (_orgName.isNotEmpty ? _orgName : 'Our Institution');

    return SliverAppBar(
      expandedHeight: 220,
      pinned: false,
      floating: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // School building image
            Image.asset(
              'assets/images/school_building.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00695C), Color(0xFF004D40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.account_balance_rounded,
                    size: 64,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
            // Dark gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xCC004D40),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            // Welcome text
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'WELCOME TO',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxNameWidth),
                    child: Text(
                      schoolName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Basic Info card ───────────────────────────────────
  Widget _buildBasicCard() {
    final b = _data?.basic;
    final name = b?.schoolName ?? _orgName;
    final address = b?.campusAddress ?? '';

    return _card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Affiliated tag
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 14, color: _teal),
              const SizedBox(width: 5),
              const Text(
                'AFFILIATED ACADEMY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _teal,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // School name
          Text(
            name.isNotEmpty ? name : 'School Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _textDark,
              height: 1.2,
            ),
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: _textLight,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _textGrey,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _textLight,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _textDark,
          ),
        ),
      ],
    ),
  );

  Widget _dividerV() => Container(
    width: 1,
    height: 40,
    color: _border,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  // ── Management Team card ──────────────────────────────
  Widget _buildManagementCard() {
    final allRoles = (_data?.roles ?? []).reversed.toList();
    final visibleRoles = _showAllRoles ? allRoles : allRoles.take(2).toList();
    final hasMore = allRoles.length > 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _tealDark,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with member count badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MANAGEMENT TEAM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white60,
                  letterSpacing: 1.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${allRoles.length} '
                  'member${allRoles.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Colors.white60,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Role rows
          if (allRoles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No roles configured yet.',
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
            )
          else
            ...visibleRoles.map((r) => _roleRow(r)),

          // Show more / Show less
          if (hasMore) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _showAllRoles = !_showAllRoles),
              child: Container(
                width: double.infinity,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAllRoles
                          ? 'SHOW LESS'
                          : 'SHOW MORE  '
                                '(${allRoles.length - 2} more)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _showAllRoles
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _roleRow(RoleItem r) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white70,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.position.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white54,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                r.assignedTo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Fee Structure card ────────────────────────────────
  Widget _buildFeeCard() {
    final fees = _data?.fees ?? [];

    return _card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Structure Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Academic Year 2024-2025',
            style: TextStyle(fontSize: 12.5, color: _textGrey),
          ),
          const SizedBox(height: 12),
          // Admission badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _orange.withOpacity(0.25), width: 1),
            ),
            child: const Text(
              'NEW ADMISSIONS OPEN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _orange,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (fees.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No fee structures configured.',
                style: TextStyle(fontSize: 13, color: _textGrey),
              ),
            )
          else
            ...fees.map((f) => _feeItem(f)),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 14),

          // Footer info + download
        ],
      ),
    );
  }

  Widget _feeItem(FeeItem f) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: _bgTable,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          f.structureName.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: _textLight,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Grade ${f.gradeFrom} - Grade ${f.gradeTo}',
          style: const TextStyle(
            fontSize: 12.5,
            color: _textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              '₹ ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            Text(
              f.formattedFee,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '/ annum',
              style: TextStyle(
                fontSize: 12,
                color: _textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // ── White card wrapper ────────────────────────────────
  Widget _card({required Widget child, EdgeInsetsGeometry? margin}) =>
      Container(
        margin: margin,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}
