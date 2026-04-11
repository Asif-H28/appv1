import 'package:appv1/features/main_app/pages/fee_config_page.dart';
import 'package:appv1/features/main_app/pages/roles_page.dart';
import 'package:appv1/features/main_app/pages/school_setup_page.dart';
import 'package:appv1/features/main_app/pages/view_school_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'module_drawer.dart';

class SchoolPage extends StatefulWidget {
  const SchoolPage({super.key});
  @override
  State<SchoolPage> createState() => _SchoolPageState();
}

class _SchoolPageState extends State<SchoolPage> {
  static const _teal = Color(0xFF00796B);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textGrey = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  String _orgName = 'My School';

  @override
  void initState() {
    super.initState();
    _loadOrg();
  }

  Future<void> _loadOrg() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _orgName = prefs.getString('userOrg') ?? 'My School');
    }
  }

  void _openModule(ModuleItem module) {
    // School Setup → goes directly to its own page
    if (module.tag == 'school_setup') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SchoolSetupPage()));
      return;
    }

    if (module.tag == 'fee_config') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FeeConfigPage()));
      return;
    }

    if (module.tag == 'dynamic_roles') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RolesPage()));
      return;
    }

    if (module.tag == 'view_school') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ViewSchoolPage()));
      return;
    }

    // All other modules → Coming Soon drawer
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => ModuleDrawer(module: module),
        transitionsBuilder: (_, anim, __, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return SlideTransition(position: slide, child: child);
        },
        transitionDuration: const Duration(milliseconds: 340),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navBottom = MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + navBottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 8),
                      ...modules.asMap().entries.map(
                        (e) => _buildModuleCard(e.key, e.value),
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

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: _textDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Org name
          Expanded(
            child: Text(
              _orgName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: _textDark,
              ),
            ),
          ),
          // Settings
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: _textGrey,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INSTITUTIONAL MANAGEMENT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _teal,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ── Module card ────────────────────────────────────────
  Widget _buildModuleCard(int index, ModuleItem module) {
    return GestureDetector(
      onTap: () => _openModule(module),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              // Vector background — fills naturally behind content
              Positioned.fill(
                child: CustomPaint(painter: _cardPainters[index]),
              ),
              // White gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.97),
                        Colors.white.withOpacity(0.72),
                      ],
                    ),
                  ),
                ),
              ),
              // Content — intrinsic height, no Expanded
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // ← key fix
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _teal.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: _teal.withOpacity(0.20)),
                          ),
                          child: Icon(module.icon, color: _teal, size: 22),
                        ),
                        Text(
                          'MODULE ${(index + 1).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _textGrey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      module.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ── Description: full text, no maxLines ──
                    Text(
                      module.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textGrey,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _teal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: _teal.withOpacity(0.18)),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: _teal,
                          size: 16,
                        ),
                      ),
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

  static final List<CustomPainter> _cardPainters = [
    _SchoolSetupPainter(),
    _FeeConfigPainter(),
    _DynamicRolesPainter(),
    _ViewSchoolPainter(),
  ];
}

// ── Module data ────────────────────────────────────────────

class ModuleItem {
  final String title;
  final String description;
  final IconData icon;
  final String tag;

  const ModuleItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.tag,
  });
}

const List<ModuleItem> modules = [
  ModuleItem(
    title: 'School Setup',
    description:
        'Define institutional parameters, campus locations, and academic sessions.',
    icon: Icons.account_balance_rounded,
    tag: 'school_setup',
  ),
  ModuleItem(
    title: 'Fee Configuration',
    description:
        'Manage tuition structures, scholarship tiers, and automated billing cycles.',
    icon: Icons.payments_rounded,
    tag: 'fee_config',
  ),
  ModuleItem(
    title: 'Dynamic Roles',
    description:
        'Assign granular permissions for faculty, staff, and department heads.',
    icon: Icons.manage_accounts_rounded,
    tag: 'dynamic_roles',
  ),
  ModuleItem(
    title: 'View School',
    description: 'Access the public-facing portal and institution directory.',
    icon: Icons.visibility_rounded,
    tag: 'view_school',
  ),
];

// ════════════════════════════════════════════════════════════
// CARD PAINTERS
// ════════════════════════════════════════════════════════════

class _SchoolSetupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()..color = const Color(0xFF00796B).withOpacity(0.07);

    // Grid lines
    for (double x = w * 0.50; x < w; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), p);
    }
    for (double y = 0; y < h; y += 22) {
      canvas.drawLine(Offset(w * 0.50, y), Offset(w, y), p);
    }

    // Building
    final bp = Paint()..color = const Color(0xFF00796B).withOpacity(0.09);
    canvas.drawRect(Rect.fromLTWH(w * 0.52, h * 0.18, w * 0.40, h * 0.64), bp);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.50, h * 0.18)
        ..lineTo(w * 0.72, h * 0.04)
        ..lineTo(w * 0.94, h * 0.18)
        ..close(),
      bp,
    );
    // Windows
    final wp = Paint()..color = const Color(0xFF00796B).withOpacity(0.13);
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 3; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              w * 0.55 + c * w * 0.12,
              h * 0.28 + r * h * 0.22,
              w * 0.08,
              h * 0.14,
            ),
            const Radius.circular(2),
          ),
          wp,
        );
      }
    }
    // Door
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.69, h * 0.60, w * 0.07, h * 0.22),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      wp,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FeeConfigPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()..color = const Color(0xFF00796B).withOpacity(0.08);
    final ps = Paint()
      ..color = const Color(0xFF00796B).withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Coins
    for (final c in [
      Offset(w * 0.68, h * 0.28),
      Offset(w * 0.82, h * 0.20),
      Offset(w * 0.92, h * 0.38),
      Offset(w * 0.76, h * 0.52),
      Offset(w * 0.90, h * 0.60),
    ]) {
      canvas.drawCircle(c, 18, p);
      canvas.drawCircle(c, 18, ps);
      canvas.drawCircle(c, 12, ps);
      canvas.drawLine(Offset(c.dx, c.dy - 6), Offset(c.dx, c.dy + 6), ps);
    }

    // Bar chart
    final bars = [0.40, 0.65, 0.50, 0.80, 0.55];
    for (int i = 0; i < bars.length; i++) {
      final bx = w * 0.54 + i * w * 0.09;
      final bh = h * 0.55 * bars[i];
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(bx, h * 0.82 - bh, w * 0.06, bh),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF00796B).withOpacity(0.09),
      );
    }
    canvas.drawLine(
      Offset(w * 0.52, h * 0.82),
      Offset(w, h * 0.82),
      Paint()
        ..color = const Color(0xFF00796B).withOpacity(0.08)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _DynamicRolesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final nodePaint = Paint()
      ..color = const Color(0xFF00796B).withOpacity(0.09);
    final linePaint = Paint()
      ..color = const Color(0xFF00796B).withOpacity(0.10)
      ..strokeWidth = 1.5;
    final strokePaint = Paint()
      ..color = const Color(0xFF00796B).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final root = Offset(w * 0.75, h * 0.18);
    canvas.drawCircle(root, 16, nodePaint);
    canvas.drawCircle(root, 16, strokePaint);
    _person(canvas, root, 0.11);

    final l2 = [Offset(w * 0.62, h * 0.48), Offset(w * 0.88, h * 0.48)];
    for (final n in l2) {
      canvas.drawLine(root, n, linePaint);
      canvas.drawCircle(n, 13, nodePaint);
      canvas.drawCircle(n, 13, strokePaint);
      _person(canvas, n, 0.09);
    }

    final l3 = [
      Offset(w * 0.56, h * 0.76),
      Offset(w * 0.70, h * 0.76),
      Offset(w * 0.84, h * 0.76),
    ];
    final parents = [l2[0], l2[0], l2[1]];
    for (int i = 0; i < l3.length; i++) {
      canvas.drawLine(parents[i], l3[i], linePaint);
      canvas.drawCircle(l3[i], 10, nodePaint);
      canvas.drawCircle(l3[i], 10, strokePaint);
    }

    // Shield
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.90, h * 0.08)
        ..lineTo(w * 0.98, h * 0.14)
        ..lineTo(w * 0.98, h * 0.26)
        ..quadraticBezierTo(w * 0.98, h * 0.36, w * 0.90, h * 0.40)
        ..quadraticBezierTo(w * 0.82, h * 0.36, w * 0.82, h * 0.26)
        ..lineTo(w * 0.82, h * 0.14)
        ..close(),
      Paint()..color = const Color(0xFF00796B).withOpacity(0.07),
    );
  }

  void _person(Canvas canvas, Offset c, double op) {
    final p = Paint()..color = const Color(0xFF00796B).withOpacity(op);
    canvas.drawCircle(Offset(c.dx, c.dy - 4), 4, p);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + 5), width: 10, height: 6),
      p,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ViewSchoolPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()..color = const Color(0xFF00796B).withOpacity(0.07);
    final ps = Paint()
      ..color = const Color(0xFF00796B).withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Ground
    canvas.drawLine(
      Offset(w * 0.50, h * 0.80),
      Offset(w, h * 0.80),
      Paint()
        ..color = const Color(0xFF00796B).withOpacity(0.08)
        ..strokeWidth = 1.5,
    );

    // Building
    canvas.drawRect(Rect.fromLTWH(w * 0.55, h * 0.24, w * 0.38, h * 0.56), p);
    final roof = Path()
      ..moveTo(w * 0.53, h * 0.24)
      ..lineTo(w * 0.74, h * 0.08)
      ..lineTo(w * 0.95, h * 0.24)
      ..close();
    canvas.drawPath(roof, p);
    canvas.drawPath(roof, ps);

    // Flag
    canvas.drawLine(
      Offset(w * 0.74, h * 0.08),
      Offset(w * 0.74, h * 0.01),
      Paint()
        ..color = const Color(0xFF00796B).withOpacity(0.10)
        ..strokeWidth = 1.2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.74, h * 0.01)
        ..lineTo(w * 0.82, h * 0.05)
        ..lineTo(w * 0.74, h * 0.09)
        ..close(),
      Paint()..color = const Color(0xFF00796B).withOpacity(0.10),
    );

    // Windows
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 3; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              w * 0.58 + c * w * 0.11,
              h * 0.30 + r * h * 0.22,
              w * 0.07,
              h * 0.14,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF00796B).withOpacity(0.11),
        );
      }
    }

    // Door
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.71, h * 0.58, w * 0.06, h * 0.22),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF00796B).withOpacity(0.11),
    );

    // Trees
    void tree(double cx, double gy, double s) {
      canvas.drawRect(
        Rect.fromLTWH(cx - 2 * s, gy - 12 * s, 4 * s, 12 * s),
        Paint()..color = const Color(0xFF00796B).withOpacity(0.09),
      );
      for (int t = 0; t < 3; t++) {
        final ty = gy - 12 * s - t * 8 * s;
        final tw2 = (16 - t * 3) * s;
        canvas.drawPath(
          Path()
            ..moveTo(cx, ty - 12 * s)
            ..lineTo(cx - tw2, ty)
            ..lineTo(cx + tw2, ty)
            ..close(),
          Paint()..color = const Color(0xFF00796B).withOpacity(0.09),
        );
      }
    }

    tree(w * 0.58, h * 0.80, 0.9);
    tree(w * 0.92, h * 0.80, 0.9);

    // Sun
    canvas.drawCircle(
      Offset(w * 0.90, h * 0.10),
      11,
      Paint()..color = const Color(0xFF00796B).withOpacity(0.07),
    );
    canvas.drawCircle(Offset(w * 0.90, h * 0.10), 11, ps);
  }

  @override
  bool shouldRepaint(_) => false;
}
