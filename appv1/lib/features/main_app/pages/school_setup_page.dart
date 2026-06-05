import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SchoolSetupPage extends StatefulWidget {
  const SchoolSetupPage({super.key});

  @override
  State<SchoolSetupPage> createState() => _SchoolSetupPageState();
}

class _SchoolSetupPageState extends State<SchoolSetupPage> {
  // ── Constants ─────────────────────────────────────────
  static const _base = '${ApiConstants.apiBaseUrl}/org';
  static const _teal = Color(0xFF00796B);
  static const _tealDark = Color(0xFF004D40);
  static const _textDark = Color(0xFF1A1A1A);
  static const _textGrey = Color(0xFF6B7280);
  static const _textLight = Color(0xFF9CA3AF);
  static const _labelColor = Color(0xFF5C6B6A);
  static const _bgPage = Color(0xFFF2F4F3);
  static const _bgCard = Colors.white;
  static const _bgField = Color(0xFFEEEEEE);
  static const _borderField = Color(0xFFE0E0E0);
  static const _divider = Color(0xFFE5E7EB);
  static const _orange = Color(0xFFB45309);

  // ── Controllers ───────────────────────────────────────
  final _schoolNameCtrl = TextEditingController();
  final _campusAddressCtrl = TextEditingController();
  final _schoolEmailCtrl = TextEditingController();
  final _primaryContactCtrl = TextEditingController();

  // ── Focus nodes ───────────────────────────────────────
  final _nameFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _contactFocus = FocusNode();

  // ── State ─────────────────────────────────────────────
  bool _loading = true;
  bool _saving = false;
  bool _hasData = false;
  String _orgId = '';
  String _orgName = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _campusAddressCtrl.dispose();
    _schoolEmailCtrl.dispose();
    _primaryContactCtrl.dispose();
    _nameFocus.dispose();
    _addressFocus.dispose();
    _emailFocus.dispose();
    _contactFocus.dispose();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    _orgName = prefs.getString('userOrg') ?? 'My School';
    await _fetchDetails();
  }

  // ── GET ───────────────────────────────────────────────
  Future<void> _fetchDetails() async {
    if (_orgId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await ApiService.get(
        Uri.parse('$_base/$_orgId/school-details'),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data =
            jsonDecode(res.body)['data'] as Map<String, dynamic>? ?? {};
        _schoolNameCtrl.text = data['schoolName'] ?? '';
        _campusAddressCtrl.text = data['campusAddress'] ?? '';
        _schoolEmailCtrl.text = data['schoolEmail'] ?? '';
        _primaryContactCtrl.text = data['primaryContact'] ?? '';
        _hasData = _schoolNameCtrl.text.isNotEmpty;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // ── PUT ───────────────────────────────────────────────
  Future<void> _saveConfiguration() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();

    if (_schoolNameCtrl.text.trim().isEmpty) {
      _snack('Official school name is required.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final res = await ApiService.put(
        Uri.parse('$_base/$_orgId/school-details'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'schoolName': _schoolNameCtrl.text.trim(),
          'campusAddress': _campusAddressCtrl.text.trim(),
          'schoolEmail': _schoolEmailCtrl.text.trim(),
          'primaryContact': _primaryContactCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() => _hasData = true);
        _snack('Configuration saved successfully.');
      } else {
        _snack(body['message'] ?? 'Save failed.', isError: true);
      }
    } catch (_) {
      if (mounted) _snack('No internet connection.', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  // ── Snack ─────────────────────────────────────────────
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
  //  BUILD
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
              _buildTopBar(),
              _loading
                  ? const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _teal,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHero(),
                            const SizedBox(height: 20),
                            _buildCoreInfoCard(),
                            const SizedBox(height: 16),
                            _buildContactCard(),
                            const SizedBox(height: 24),
                            _buildSaveButton(),
                            const SizedBox(height: 32),
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

  // ── Top bar ───────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: _bgPage,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // ── Back button ──────────────────────────────
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

          // ── Org name ─────────────────────────────────
          Expanded(
            child: Text(
              _orgName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero block ────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(4),
        border: const Border(left: BorderSide(color: _teal, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'School Setup',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure the core identity and contact\nparameters of your institution.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _textGrey,
                    height: 1.55,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Core Information card ─────────────────────────────
  Widget _buildCoreInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label in orange/brown
          const Text(
            'INSTITUTIONAL PROFILE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _orange,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Core Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 24),

          // Official school name
          _fieldLabel('OFFICIAL SCHOOL NAME'),
          const SizedBox(height: 8),
          _inputField(
            controller: _schoolNameCtrl,
            focusNode: _nameFocus,
            hint: "e.g. St. Christopher's Academy",
            nextFocus: _addressFocus,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 20),

          // Campus address
          _fieldLabel('CAMPUS ADDRESS'),
          const SizedBox(height: 8),
          _inputField(
            controller: _campusAddressCtrl,
            focusNode: _addressFocus,
            hint: 'Street name, District, Postal Code...',
            nextFocus: _emailFocus,
            maxLines: 3,
            keyboardType: TextInputType.streetAddress,
          ),
        ],
      ),
    );
  }

  // ── Contact Details card ──────────────────────────────
  Widget _buildContactCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label in teal
          const Text(
            'CONNECTIVITY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _teal,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Contact Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 24),

          // Administrative email
          _fieldLabel('ADMINISTRATIVE EMAIL'),
          const SizedBox(height: 8),
          _inputField(
            controller: _schoolEmailCtrl,
            focusNode: _emailFocus,
            hint: 'admin@school.edu',
            nextFocus: _contactFocus,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 20),

          // Primary contact number
          _fieldLabel('PRIMARY CONTACT NUMBER'),
          const SizedBox(height: 8),
          _inputField(
            controller: _primaryContactCtrl,
            focusNode: _contactFocus,
            hint: '+1 (555) 000-0000',
            isLast: true,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
          ),
        ],
      ),
    );
  }

  // ── Save button ───────────────────────────────────────
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _saving ? null : _saveConfiguration,
        child: Container(
          width: double.infinity,
          height: 56,
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
                : const Text(
                    'SAVE CONFIGURATION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════

  // ── White card wrapper ────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
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

  // ── Field label ───────────────────────────────────────
  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: _labelColor,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Input field ───────────────────────────────────────
  Widget _inputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    FocusNode? nextFocus,
    bool isLast = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onSubmitted: (_) {
        if (isLast) {
          FocusScope.of(context).unfocus();
        } else if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      style: const TextStyle(
        fontSize: 15,
        color: _textDark,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14.5,
          color: _textLight,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: _bgField,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: _textLight)
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: prefixIcon != null ? 4 : 14,
          vertical: maxLines > 1 ? 14 : 0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _borderField),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _borderField),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _teal, width: 1.5),
        ),
      ),
    );
  }
}

