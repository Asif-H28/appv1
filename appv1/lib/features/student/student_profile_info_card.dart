import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

const Color _accent = Colors.teal;

class StudentProfileInfoCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final bool showPersonal;

  const StudentProfileInfoCard({
    required this.student,
    this.showPersonal = false,
  });

  String _val(String key) {
    final v = student[key]?.toString() ?? '';
    return v.isNotEmpty ? v : '—';
  }

  @override
  Widget build(BuildContext context) {
    return _card(
      title: 'Personal Info',
      icon: Icons.person_outline_rounded,
      children: [
        _row(Icons.person_rounded, 'Full Name', _val('name')),
        _divider(),
        _row(Icons.email_rounded, 'Email', _val('email')),
        _divider(),
        _row(Icons.phone_rounded, 'Phone', _val('phone')),
        _divider(),
        _row(Icons.wc_rounded, 'Gender', _val('gender')),
        _divider(),
        _row(
          Icons.location_on_rounded,
          'Address',
          _val('address'),
          multiLine: true,
        ),
        _divider(),
        _copyRow(context, Icons.badge_rounded, 'Student ID', _val('studentId')),
      ],
    );
  }

  // ── Card shell ────────────────────────────────────────

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    Icon(icon, size: 15, color: _accent),
                    SizedBox(width: 5),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info row ──────────────────────────────────────────

  Widget _row(
    IconData icon,
    String label,
    String value, {
    bool multiLine = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: multiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(icon, size: 15, color: _accent),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Copy row ──────────────────────────────────────────

  Widget _copyRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(icon, size: 15, color: _accent),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (value != '—')
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$label copied',
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: _accent,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                    margin: EdgeInsets.all(14),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Icon(Icons.copy_rounded, size: 13, color: _accent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey[100]);
}
