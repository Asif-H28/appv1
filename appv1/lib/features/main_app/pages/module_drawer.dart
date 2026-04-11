import 'package:flutter/material.dart';
import 'school_page.dart';

class ModuleDrawer extends StatelessWidget {
  final ModuleItem module;
  const ModuleDrawer({super.key, required this.module});

  static const _teal = Color(0xFF00796B);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textGrey = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  static const _details = {
    'school_setup': _ModuleDetail(
      icon: Icons.account_balance_rounded,
      number: '01',
      features: [
        'Campus location management',
        'Academic session configuration',
        'Institutional parameters & branding',
        'Grade structure & divisions',
      ],
      progress: 30,
    ),
    'fee_config': _ModuleDetail(
      icon: Icons.payments_rounded,
      number: '02',
      features: [
        'Tuition structure builder',
        'Scholarship tier management',
        'Automated billing cycles',
        'Payment gateway integration',
      ],
      progress: 55,
    ),
    'dynamic_roles': _ModuleDetail(
      icon: Icons.manage_accounts_rounded,
      number: '03',
      features: [
        'Granular permission control',
        'Faculty role assignment',
        'Department head configuration',
        'Staff access management',
      ],
      progress: 20,
    ),
    'view_school': _ModuleDetail(
      icon: Icons.visibility_rounded,
      number: '04',
      features: [
        'Public-facing school portal',
        'Institution directory',
        'Parent & visitor access',
        'School profile & announcements',
      ],
      progress: 45,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final detail = _details[module.tag]!;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: _teal.withOpacity(0.18)),
                    ),
                    child: Icon(detail.icon, color: _teal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MODULE ${detail.number}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: _teal,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          module.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          module.description,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _textGrey,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: _textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildComingSoonBanner(),
                    const SizedBox(height: 28),
                    if (detail.features.isNotEmpty) ...[
                      _sectionLabel('UPCOMING FEATURES'),
                      const SizedBox(height: 14),
                      ...detail.features.map(_featureRow),
                      const SizedBox(height: 28),
                    ],
                    _buildProgress(detail.progress),
                    const SizedBox(height: 32),
                    _buildNotifyButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Coming soon banner ─────────────────────────────────
  Widget _buildComingSoonBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF00796B), Color(0xFF004D40)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Icon(
            Icons.rocket_launch_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'This module is under active\ndevelopment and will be available soon.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Feature row ────────────────────────────────────────
  Widget _featureRow(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 7,
          height: 7,
          decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: _textDark, height: 1.5),
          ),
        ),
      ],
    ),
  );

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w800,
      color: _textGrey,
      letterSpacing: 1.3,
    ),
  );

  // ── Progress ───────────────────────────────────────────
  Widget _buildProgress(int progress) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('DEVELOPMENT PROGRESS'),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Module completion',
            style: TextStyle(
              fontSize: 13,
              color: _textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$progress%',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _teal,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: const Color(0xFFE0F2F1),
          color: _teal,
          minHeight: 8,
        ),
      ),
    ],
  );

  // ── Notify button ──────────────────────────────────────
  Widget _buildNotifyButton(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(
        Icons.notifications_active_rounded,
        size: 17,
        color: Colors.white,
      ),
      label: const Text(
        'Notify Me When Ready',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _teal,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    ),
  );
}

// ── Module detail data ─────────────────────────────────────

class _ModuleDetail {
  final IconData icon;
  final String number;
  final List<String> features;
  final int progress;

  const _ModuleDetail({
    required this.icon,
    required this.number,
    required this.features,
    required this.progress,
  });
}
