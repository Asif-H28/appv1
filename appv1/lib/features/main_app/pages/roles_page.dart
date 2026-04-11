// roles_page.dart
// School Management Profiles — 100% match to design image

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'role_model.dart';

// ── Palette ───────────────────────────────────────────────
const _teal = Color(0xFF00796B);
const _tealLight = Color(0xFFE0F2F1);
const _tealDark = Color(0xFF004D40);
const _textDark = Color(0xFF1A1A1A);
const _textGrey = Color(0xFF6B7280);
const _textLight = Color(0xFF9CA3AF);
const _bgPage = Color(0xFFF2F4F3);
const _bgCard = Colors.white;
const _bgField = Color(0xFFEEEEEE);
const _borderCol = Color(0xFFE0E0E0);
const _labelColor = Color(0xFF5C6B6A);

// ════════════════════════════════════════════════════════
class RolesPage extends StatefulWidget {
  const RolesPage({super.key});

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  String _orgId = '';
  String _orgName = '';

  bool _listLoading = true;
  List<SchoolRole> _roles = [];

  bool _showForm = false;
  SchoolRole? _editTarget;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    _orgName = prefs.getString('userOrg') ?? 'My School';
    await _loadRoles();
  }

  // ── GET ────────────────────────────────────────────────
  Future<void> _loadRoles() async {
    if (_orgId.isEmpty) {
      setState(() => _listLoading = false);
      return;
    }
    try {
      final list = await RoleService.getAll(_orgId);
      if (mounted)
        setState(() {
          _roles = list;
          _listLoading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _listLoading = false);
        _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  // ── DELETE ─────────────────────────────────────────────
  Future<void> _deleteRole(SchoolRole role) async {
    final ok = await _confirmDelete(role.position);
    if (!ok) return;
    try {
      await RoleService.delete(role.id, _orgId);
      if (mounted) {
        setState(() => _roles.removeWhere((r) => r.id == role.id));
        _snack('Role deleted.');
      }
    } catch (e) {
      if (mounted)
        _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<bool> _confirmDelete(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            title: const Text(
              'Delete Role',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            content: Text(
              'Delete "$name"? This cannot be undone.',
              style: const TextStyle(fontSize: 13.5, color: _textGrey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: _textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Form control ───────────────────────────────────────
  void _openForm({SchoolRole? edit}) => setState(() {
    _editTarget = edit;
    _showForm = true;
  });

  void _closeForm() => setState(() {
    _showForm = false;
    _editTarget = null;
  });

  void _onSaved(SchoolRole saved) {
    setState(() {
      if (_editTarget != null) {
        final idx = _roles.indexWhere((r) => r.id == saved.id);
        if (idx >= 0) _roles[idx] = saved;
      } else {
        _roles.insert(0, saved);
      }
      _showForm = false;
      _editTarget = null;
    });
    _snack(_editTarget == null ? 'Role created.' : 'Role updated.');
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.red[700] : _teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bgPage,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(orgName: _orgName),
              Expanded(
                child: _listLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: _teal,
                          strokeWidth: 2,
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHero(),
                            const SizedBox(height: 24),
                            _buildAddButton(),
                            const SizedBox(height: 24),
                            if (_showForm) ...[
                              _RoleForm(
                                orgId: _orgId,
                                edit: _editTarget,
                                onSaved: _onSaved,
                                onCancel: _closeForm,
                              ),
                              const SizedBox(height: 24),
                            ],
                            if (_roles.isNotEmpty) ...[
                              _buildRoleList(),
                              const SizedBox(height: 32),
                            ],
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

  // ── Hero block ─────────────────────────────────────────
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label chip
          const Text(
            'INSTITUTIONAL MANAGEMENT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _teal,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          // Title — 2 lines, second in teal
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'School Management\n',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                    height: 1.15,
                  ),
                ),
                TextSpan(
                  text: 'Profiles.',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: _teal,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Define administrative hierarchies and assign\nresponsible personnel. Establish key\nleadership roles to maintain institutional\noversight and operational excellence.',
            style: TextStyle(fontSize: 14, color: _textGrey, height: 1.65),
          ),
        ],
      ),
    );
  }

  // ── Add new profile button ─────────────────────────────
  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _showForm ? null : () => _openForm(),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _showForm ? _teal.withOpacity(0.5) : _teal,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'ADD NEW PROFILE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Saved roles list ───────────────────────────────────
  Widget _buildRoleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'SAVED PROFILES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _labelColor,
              letterSpacing: 1.3,
            ),
          ),
        ),
        ..._roles.map(
          (r) => _RoleCard(
            role: r,
            onEdit: () => _openForm(edit: r),
            onDelete: () => _deleteRole(r),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════
//  TOP BAR
// ════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final String orgName;
  const _TopBar({required this.orgName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgPage,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: _textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              orgName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
          ),
          const Icon(Icons.settings_outlined, size: 24, color: _textDark),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  ROLE CARD (saved list item)
// ════════════════════════════════════════════════════════
class _RoleCard extends StatelessWidget {
  final SchoolRole role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleCard({
    required this.role,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left teal accent dot
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _teal,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.position,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: _textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        role.assignedTo,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Edit
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.edit_outlined, size: 18, color: _teal),
              ),
            ),
            // Delete
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  ROLE FORM (Profile Definition card from image)
// ════════════════════════════════════════════════════════
class _RoleForm extends StatefulWidget {
  final String orgId;
  final SchoolRole? edit;
  final void Function(SchoolRole) onSaved;
  final VoidCallback onCancel;

  const _RoleForm({
    required this.orgId,
    required this.onSaved,
    required this.onCancel,
    this.edit,
  });

  @override
  State<_RoleForm> createState() => _RoleFormState();
}

class _RoleFormState extends State<_RoleForm> {
  final _positionCtrl = TextEditingController();
  final _assignedToCtrl = TextEditingController();
  final _posFocus = FocusNode();
  final _assignFocus = FocusNode();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.edit != null) {
      _positionCtrl.text = widget.edit!.position;
      _assignedToCtrl.text = widget.edit!.assignedTo;
    }
  }

  @override
  void dispose() {
    _positionCtrl.dispose();
    _assignedToCtrl.dispose();
    _posFocus.dispose();
    _assignFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();

    if (_positionCtrl.text.trim().isEmpty) {
      _snack('Institutional position is required.', isError: true);
      return;
    }

    final role = SchoolRole(
      id: widget.edit?.id ?? '',
      orgId: widget.orgId,
      position: _positionCtrl.text.trim(),
      assignedTo: _assignedToCtrl.text.trim(),
    );

    setState(() => _saving = true);
    try {
      final SchoolRole saved;
      if (widget.edit != null) {
        saved = await RoleService.update(role.id, role);
      } else {
        saved = await RoleService.create(role);
      }
      if (mounted) widget.onSaved(saved);
    } catch (e) {
      if (mounted)
        _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.red[700] : _teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ──────────────────────────
            Row(
              children: [
                const Text(
                  'Profile Definition',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onCancel,
                  child: const Icon(Icons.close, size: 20, color: _textLight),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Institutional position ───────────────
            _label('INSTITUTIONAL POSITION'),
            const SizedBox(height: 8),
            _field(
              controller: _positionCtrl,
              focusNode: _posFocus,
              hint: 'e.g. Principal',
              next: _assignFocus,
            ),
            const SizedBox(height: 18),

            // ── Assign full name ─────────────────────
            _label('ASSIGN FULL NAME'),
            const SizedBox(height: 8),
            _field(
              controller: _assignedToCtrl,
              focusNode: _assignFocus,
              hint: 'Dr. Julian Sterling',
              isLast: true,
            ),
            const SizedBox(height: 24),

            // ── Save button ──────────────────────────
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: _teal,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          widget.edit != null
                              ? 'UPDATE PROFILE'
                              : 'SAVE PROFILES',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────
  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: _labelColor,
      letterSpacing: 1.2,
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    FocusNode? next,
    bool isLast = false,
  }) => TextField(
    controller: controller,
    focusNode: focusNode,
    textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
    onSubmitted: (_) {
      if (isLast) {
        FocusScope.of(context).unfocus();
      } else if (next != null) {
        FocusScope.of(context).requestFocus(next);
      }
    },
    style: const TextStyle(fontSize: 15, color: _textDark),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14.5,
        color: _textLight,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: _bgField,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: _borderCol),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: _borderCol),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: _teal, width: 1.5),
      ),
    ),
  );
}
