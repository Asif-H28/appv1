// fee_config_page.dart
// Fee Configuration UI — 100% match to design image

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fee_structure_model.dart';

// ── Palette ───────────────────────────────────────────────
const _teal = Color(0xFF00796B);
const _tealLight = Color(0xFFE0F2F1);
const _textDark = Color(0xFF1A1A1A);
const _textGrey = Color(0xFF6B7280);
const _textLight = Color(0xFF9CA3AF);
const _bgPage = Color(0xFFF2F4F3);
const _bgCard = Colors.white;
const _bgField = Color(0xFFEEEEEE);
const _bgTable = Color(0xFFF5F5F5);
const _borderCol = Color(0xFFE0E0E0);
const _labelColor = Color(0xFF5C6B6A);

class FeeConfigPage extends StatefulWidget {
  const FeeConfigPage({super.key});

  @override
  State<FeeConfigPage> createState() => _FeeConfigPageState();
}

class _FeeConfigPageState extends State<FeeConfigPage> {
  String _orgId = '';
  String _orgName = '';

  // ── List state ───────────────────────────────────────
  bool _listLoading = true;
  List<FeeStructure> _structures = [];

  // ── Form visibility ──────────────────────────────────
  bool _showForm = false;

  // ── Edit target (null = new) ─────────────────────────
  FeeStructure? _editTarget;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    _orgName = prefs.getString('userOrg') ?? 'My School';
    await _loadStructures();
  }

  Future<void> _loadStructures() async {
    if (_orgId.isEmpty) {
      setState(() => _listLoading = false);
      return;
    }
    try {
      final list = await FeeStructureService.getAll(_orgId);
      if (mounted)
        setState(() {
          _structures = list;
          _listLoading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _listLoading = false);
        _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  // ── Delete ───────────────────────────────────────────
  Future<void> _delete(FeeStructure fs) async {
    final confirm = await _confirmDelete(fs.structureName);
    if (!confirm) return;
    try {
      await FeeStructureService.delete(fs.id, _orgId);
      if (mounted) {
        setState(() => _structures.removeWhere((s) => s.id == fs.id));
        _snack('Fee structure deleted.');
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
              'Delete Structure',
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

  void _openForm({FeeStructure? edit}) {
    setState(() {
      _editTarget = edit;
      _showForm = true;
    });
  }

  void _closeForm() => setState(() {
    _showForm = false;
    _editTarget = null;
  });

  void _onSaved(FeeStructure saved) {
    setState(() {
      if (_editTarget != null) {
        final idx = _structures.indexWhere((s) => s.id == saved.id);
        if (idx >= 0) _structures[idx] = saved;
      } else {
        _structures.insert(0, saved);
      }
      _showForm = false;
      _editTarget = null;
    });
    _snack(
      _editTarget == null ? 'Fee structure created.' : 'Fee structure updated.',
    );
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
                            const SizedBox(height: 20),
                            _buildAddButton(),
                            const SizedBox(height: 20),
                            if (_showForm) ...[
                              _FeeForm(
                                orgId: _orgId,
                                edit: _editTarget,
                                onSaved: _onSaved,
                                onCancel: _closeForm,
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (_structures.isNotEmpty) ...[
                              _buildListSection(),
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

  // ── Hero ─────────────────────────────────────────────
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Configuration',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _textDark,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Define and manage academic fee structures\nacross grade ranges. Establish your\ninstitution's financial baseline with editorial\nprecision.",
            style: TextStyle(fontSize: 13.5, color: _textGrey, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── Add button ───────────────────────────────────────
  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _showForm ? null : () => _openForm(),
        child: Container(
          width: double.infinity,
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
                'Add New Structure',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Existing structures list ──────────────────────────
  Widget _buildListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Saved Structures',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _labelColor,
              letterSpacing: 1.1,
            ),
          ),
        ),
        ..._structures.map(
          (fs) => _StructureCard(
            fs: fs,
            onEdit: () => _openForm(edit: fs),
            onDelete: () => _delete(fs),
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
//  EXISTING STRUCTURE CARD (list item)
// ════════════════════════════════════════════════════════
class _StructureCard extends StatelessWidget {
  final FeeStructure fs;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StructureCard({
    required this.fs,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fs.structureName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: _teal,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderCol),
          // Grade + fee row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                _chip('Grade ${fs.gradeFrom} – ${fs.gradeTo}'),
                const SizedBox(width: 8),
                _chip('₹ ${_fmt(fs.feeAmount)}'),
                if (fs.hasBreakdown) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _tealLight,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'BREAKDOWN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _teal,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _bgTable,
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: _borderCol),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _textGrey,
      ),
    ),
  );

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ════════════════════════════════════════════════════════
//  FEE FORM (Structure Definition card from image)
// ════════════════════════════════════════════════════════
class _FeeForm extends StatefulWidget {
  final String orgId;
  final FeeStructure? edit;
  final void Function(FeeStructure) onSaved;
  final VoidCallback onCancel;

  const _FeeForm({
    required this.orgId,
    required this.onSaved,
    required this.onCancel,
    this.edit,
  });

  @override
  State<_FeeForm> createState() => _FeeFormState();
}

class _FeeFormState extends State<_FeeForm> {
  final _nameCtrl = TextEditingController();
  final _gradeFromCtrl = TextEditingController(text: '1');
  final _gradeToCtrl = TextEditingController(text: '5');
  final _feeCtrl = TextEditingController(text: '0');

  bool _hasBreakdown = false;
  bool _saving = false;

  List<Map<String, TextEditingController>> _rows = [];

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    if (e != null) {
      _nameCtrl.text = e.structureName;
      _gradeFromCtrl.text = e.gradeFrom.toString();
      _gradeToCtrl.text = e.gradeTo.toString();
      _feeCtrl.text = e.feeAmount % 1 == 0
          ? e.feeAmount.toInt().toString()
          : e.feeAmount.toStringAsFixed(2);
      _hasBreakdown = e.hasBreakdown;
      _rows = e.breakdown
          .map(
            (b) => {
              'component': TextEditingController(text: b.component),
              'amount': TextEditingController(
                text: b.amount % 1 == 0
                    ? b.amount.toInt().toString()
                    : b.amount.toStringAsFixed(2),
              ),
            },
          )
          .toList();
    }
    if (_rows.isEmpty && _hasBreakdown) _addRow();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gradeFromCtrl.dispose();
    _gradeToCtrl.dispose();
    _feeCtrl.dispose();
    for (final r in _rows) {
      r['component']!.dispose();
      r['amount']!.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(
      () => _rows.add({
        'component': TextEditingController(),
        'amount': TextEditingController(text: '0'),
      }),
    );
  }

  void _removeRow(int i) {
    _rows[i]['component']!.dispose();
    _rows[i]['amount']!.dispose();
    setState(() => _rows.removeAt(i));
  }

  double get _breakdownTotal => _rows.fold(0, (s, r) {
    return s + (double.tryParse(r['amount']!.text) ?? 0);
  });

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();

    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Structure name is required.', isError: true);
      return;
    }

    final fs = FeeStructure(
      id: widget.edit?.id ?? '',
      orgId: widget.orgId,
      structureName: _nameCtrl.text.trim(),
      gradeFrom: int.tryParse(_gradeFromCtrl.text) ?? 1,
      gradeTo: int.tryParse(_gradeToCtrl.text) ?? 1,
      feeAmount: double.tryParse(_feeCtrl.text) ?? 0,
      hasBreakdown: _hasBreakdown,
      breakdown: _hasBreakdown
          ? _rows
                .map(
                  (r) => BreakdownItem(
                    component: r['component']!.text.trim(),
                    amount: double.tryParse(r['amount']!.text) ?? 0,
                  ),
                )
                .toList()
          : [],
    );

    setState(() => _saving = true);
    try {
      FeeStructure saved;
      if (widget.edit != null) {
        saved = await FeeStructureService.update(fs.id, fs);
      } else {
        saved = await FeeStructureService.create(fs);
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Form header ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined, color: _teal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Structure Definition',
                  style: TextStyle(
                    fontSize: 18,
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
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Structure name ───────────────────
                _label('STRUCTURE NAME'),
                const SizedBox(height: 8),
                _field(_nameCtrl, hint: 'e.g., Primary Annual Tuition'),
                const SizedBox(height: 16),

                // ── Grade from / to ──────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('GRADE FROM'),
                          const SizedBox(height: 8),
                          _field(
                            _gradeFromCtrl,
                            hint: '1',
                            type: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('GRADE TO'),
                          const SizedBox(height: 8),
                          _field(
                            _gradeToCtrl,
                            hint: '5',
                            type: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Fee amount ───────────────────────
                _label('FEE AMOUNT (INR)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _feeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontSize: 15, color: _textDark),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 6),
                      child: Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 15,
                          color: _textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    filled: true,
                    fillColor: _bgField,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
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
                ),
                const SizedBox(height: 16),

                // ── Breakdown toggle ─────────────────
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _hasBreakdown = !_hasBreakdown;
                      if (_hasBreakdown && _rows.isEmpty) _addRow();
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        _hasBreakdown
                            ? Icons.check_box_outlined
                            : Icons.table_rows_outlined,
                        size: 16,
                        color: _teal,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'BREAKDOWN FEE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _teal,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Breakdown table ──────────────────
                if (_hasBreakdown) ...[
                  const SizedBox(height: 16),
                  _label('BREAKDOWN DETAILS'),
                  const SizedBox(height: 8),
                  _buildBreakdownTable(),
                ],

                // ── Save button ──────────────────────
                const SizedBox(height: 24),
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
                                  ? 'Update Configuration'
                                  : 'Save Configuration',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Breakdown table ────────────────────────────────────
  Widget _buildBreakdownTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderCol),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: const BoxDecoration(
              color: _bgTable,
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'FEE COMPONENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _labelColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: Text(
                    'AMOUNT (₹)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _labelColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                SizedBox(width: 32),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderCol),

          // Rows
          ..._rows.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: r['component'],
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: _textGrey,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g., Admission Fee',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: _textLight,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: r['amount'],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.right,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: _textGrey,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeRow(i),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: _textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < _rows.length - 1)
                  const Divider(height: 1, color: _borderCol),
              ],
            );
          }),

          // Total row
          const Divider(height: 1, color: _borderCol),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Text(
                  'Total Allocated',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹ ${_breakdownTotal % 1 == 0 ? _breakdownTotal.toInt() : _breakdownTotal.toStringAsFixed(2)}.00',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                  ),
                ),
              ],
            ),
          ),

          // Add component button
          const Divider(height: 1, color: _borderCol),
          GestureDetector(
            onTap: _addRow,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(
                color: _bgTable,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
              ),
              child: const Center(
                child: Text(
                  '+ ADD COMPONENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _teal,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────
  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: _labelColor,
      letterSpacing: 1.2,
    ),
  );

  Widget _field(
    TextEditingController ctrl, {
    required String hint,
    TextInputType type = TextInputType.text,
  }) => TextField(
    controller: ctrl,
    keyboardType: type,
    style: const TextStyle(fontSize: 15, color: _textDark),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14.5, color: _textLight),
      filled: true,
      fillColor: _bgField,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
