import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class TeacherOrganizationPage extends StatefulWidget {
  @override
  _TeacherOrganizationPageState createState() =>
      _TeacherOrganizationPageState();
}

class _TeacherOrganizationPageState extends State<TeacherOrganizationPage> {
  String _orgName = '';
  String _orgId = '';
  final Color _accent = Colors.teal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orgName = prefs.getString('userOrg') ?? 'Organization';
      _orgId = prefs.getString('orgId') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Gradient Header ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organization',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your school details',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  children: [
                    // ── Org identity card ──
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _accent.withOpacity(0.08),
                            _accent.withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accent.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_accent, _accent.withOpacity(0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _orgName.isNotEmpty
                                    ? _orgName[0].toUpperCase()
                                    : 'O',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 14),
                          Text(
                            _orgName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _accent.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tag_rounded,
                                  color: _accent,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _orgId,
                                  style: TextStyle(
                                    color: _accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Active Organization',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // ── Info tiles ──
                    _sectionTitle('Details'),
                    SizedBox(height: 12),
                    _infoCard([
                      _infoTile(
                        Icons.domain_rounded,
                        'Organization Name',
                        _orgName,
                      ),
                      _divider(),
                      _infoTile(
                        Icons.badge_outlined,
                        'Organization ID',
                        _orgId,
                      ),
                      _divider(),
                      _infoTile(
                        Icons.verified_user_outlined,
                        'Your Role',
                        'Teacher',
                      ),
                    ]),
                    SizedBox(height: 24),

                    // ── Stats ──
                    _sectionTitle('Overview'),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        _overviewCard(
                          Icons.people_rounded,
                          'Total Staff',
                          '24',
                          _accent,
                        ),
                        SizedBox(width: 12),
                        _overviewCard(
                          Icons.school_rounded,
                          'Classrooms',
                          '12',
                          Colors.indigo,
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        _overviewCard(
                          Icons.person_rounded,
                          'Students',
                          '480',
                          Colors.orange,
                        ),
                        SizedBox(width: 12),
                        _overviewCard(
                          Icons.menu_book_rounded,
                          'Subjects',
                          '8',
                          Colors.purple,
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // ── Contact section ──
                    _sectionTitle('Contact & Location'),
                    SizedBox(height: 12),
                    _infoCard([
                      _infoTile(Icons.phone_outlined, 'Phone', 'Not available'),
                      _divider(),
                      _infoTile(
                        Icons.location_on_outlined,
                        'City',
                        'Not available',
                      ),
                      _divider(),
                      _infoTile(
                        Icons.email_outlined,
                        'Admin Email',
                        'Not available',
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _infoCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _infoTile(IconData icon, String label, String value) => ListTile(
    leading: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: _accent, size: 18),
    ),
    title: Text(
      label,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    subtitle: Text(
      value,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _divider() =>
      Divider(height: 1, indent: 68, endIndent: 16, color: Colors.grey[200]);

  Widget _overviewCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
