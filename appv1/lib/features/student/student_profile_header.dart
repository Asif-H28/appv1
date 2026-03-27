import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

const Color _accent = Colors.teal;

class StudentProfileHeader extends StatelessWidget {
  final Map<String, dynamic> student;
  final bool isEditing;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onEditToggle;
  final VoidCallback onLogout;

  const StudentProfileHeader({
    required this.student,
    required this.isEditing,
    required this.isLoading,
    required this.hasError,
    required this.onEditToggle,
    required this.onLogout,
  });

  String get _initials {
    final name = student['name']?.toString() ?? '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  String get _joinStatus => student['joinStatus']?.toString() ?? '';
  String get _orgName => student['orgName']?.toString() ?? '';
  String get _className => student['className']?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent.withOpacity(0.95), _accent.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Account & settings',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLoading && !hasError) ...[
                    // Edit / Cancel
                    GestureDetector(
                      onTap: onEditToggle,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isEditing
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEditing
                                  ? Icons.close_rounded
                                  : Icons.edit_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              isEditing ? 'Cancel' : 'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    // Logout icon btn
                    // Logout icon btn
                    GestureDetector(
                      onTap: onLogout,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[500],
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.red[300]!,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Avatar + info section ──
            if (!isLoading && !hasError) ...[
              SizedBox(height: 22),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAvatar(),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + verified badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  student['name']?.toString() ?? '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_joinStatus == 'approved') ...[
                                SizedBox(width: 7),
                                _verifiedBadge(),
                              ],
                            ],
                          ),
                          SizedBox(height: 5),

                          // Email
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 11,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  student['email']?.toString() ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 11.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),

                          // Pills row
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (_orgName.isNotEmpty)
                                _infoPill(
                                  icon: Icons.domain_rounded,
                                  label: _orgName,
                                ),
                              if (_className.isNotEmpty)
                                _infoPill(
                                  icon: Icons.class_rounded,
                                  label: _className,
                                ),
                              if (_joinStatus != 'approved' &&
                                  _joinStatus.isNotEmpty)
                                _statusPill(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 22),

              // Rounded bottom curve into body
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
            ] else
              SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Avatar with status dot ────────────────────────────

  Widget _buildAvatar() {
    final isVerified = _joinStatus == 'approved';
    return Stack(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
            border: Border.all(
              color: Colors.white.withOpacity(isVerified ? 1.0 : 0.4),
              width: isVerified ? 2.5 : 2,
            ),
          ),
          child: Center(
            child: Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 1,
          right: 1,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
              ],
            ),
            child: Center(
              child: Icon(
                isVerified
                    ? Icons.verified_rounded
                    : _joinStatus == 'pending'
                    ? Icons.hourglass_top_rounded
                    : Icons.help_outline_rounded,
                size: 13,
                color: isVerified
                    ? Colors.blue[600]
                    : _joinStatus == 'pending'
                    ? Colors.orange[400]
                    : Colors.grey[400],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Verified badge: white bg + blue icon & text ───────

  Widget _verifiedBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 12, color: Colors.blue[600]),
          SizedBox(width: 3),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Info pill (org, class) ────────────────────────────

  Widget _infoPill({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Non-verified status pill ──────────────────────────

  Widget _statusPill() {
    Color color;
    IconData icon;
    String label;

    switch (_joinStatus) {
      case 'pending':
        color = Colors.orange[300]!;
        icon = Icons.hourglass_top_rounded;
        label = 'Pending';
        break;
      case 'rejected':
        color = Colors.red[300]!;
        icon = Icons.cancel_rounded;
        label = 'Rejected';
        break;
      default:
        color = Colors.grey[300]!;
        icon = Icons.help_outline_rounded;
        label = 'Not Applied';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
