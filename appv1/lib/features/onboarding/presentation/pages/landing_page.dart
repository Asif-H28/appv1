import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../main_app/main_app_screen.dart';
import '../../../main_app/pages/login_page.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/student_register_sheet.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// SHARED HELPERS
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const Color _accent = Colors.teal;

Widget _fieldLabel(String text) => Text(
  text,
  style: TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  ),
);

InputDecoration _fieldDeco({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(
    color: AppColors.textSecondary.withOpacity(0.5),
    fontSize: 13,
  ),
  prefixIcon: Icon(icon, color: _accent, size: 16),
  suffixIcon: suffixIcon,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: BorderSide(color: Colors.grey[200]!),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: BorderSide(color: Colors.grey[200]!),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: BorderSide(color: _accent.withOpacity(0.5), width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
  ),
  filled: true,
  fillColor: Colors.white,
  isDense: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
  errorStyle: TextStyle(color: Colors.red[400], fontSize: 11),
);

Widget _primaryBtn({
  required String label,
  required bool isLoading,
  required String loadingLabel,
  required IconData icon,
  required VoidCallback? onTap,
}) => Theme(
  data: ThemeData(
    colorScheme: ColorScheme.light(primary: _accent, onPrimary: Colors.white),
  ),
  child: SizedBox(
    width: double.infinity,
    height: 46,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _accent.withOpacity(0.45),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  loadingLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
    ),
  ),
);

void _snack(BuildContext ctx, String msg, Color color) {
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    ),
  );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// LANDING PAGE
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging)
        setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            // â”€â”€ Gradient header â”€â”€
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, _accent.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // â”€â”€ Back + Logo row â”€â”€
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            padding: EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.sync_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SchoolSync',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'School Management Platform',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 14),

                      Text(
                        _selectedTab == 0
                            ? 'Create Organization ðŸ«'
                            : 'Join Organization ðŸ”',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        _selectedTab == 0
                            ? 'Set up your school on SchoolSync'
                            : 'Search and join an existing organization',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 14),

                      // â”€â”€ Tab bar â”€â”€
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: _accent,
                          unselectedLabelColor: Colors.white.withOpacity(0.85),
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
                            _tab(Icons.add_business_outlined, 'Create', 0),
                            _tab(Icons.search_rounded, 'Join', 1),
                          ],
                        ),
                      ),
                      SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),

            // â”€â”€ Body â”€â”€
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                clipBehavior: Clip.antiAlias,
                child: TabBarView(
                  controller: _tabController,
                  children: [_CreateOrgTab(), _JoinOrgTab()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(IconData icon, String label, int index) {
    final active = _selectedTab == index;
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// CREATE ORG TAB
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CreateOrgTab extends StatefulWidget {
  @override
  __CreateOrgTabState createState() => __CreateOrgTabState();
}

class __CreateOrgTabState extends State<_CreateOrgTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  bool _isLoading = false;
  bool _allFieldsValid = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_checkValid);
    _orgCtrl.addListener(_checkValid);
    _passCtrl.addListener(_checkValid);
    _licenseCtrl.addListener(_checkValid);
  }

  void _checkValid() {
    setState(() {
      _allFieldsValid =
          _emailCtrl.text.isNotEmpty &&
          isValidEmail(_emailCtrl.text) &&
          _orgCtrl.text.isNotEmpty &&
          isValidOrgName(_orgCtrl.text) &&
          _passCtrl.text.isNotEmpty &&
          isValidPassword(_passCtrl.text) &&
          _licenseCtrl.text.trim().length == 16;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _orgCtrl.dispose();
    _passCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate() || !_allFieldsValid) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.createOrganization(
        orgName: _orgCtrl.text.trim(),
        adminEmail: _emailCtrl.text.trim(),
        adminPassword: _passCtrl.text,
        licenseKey: _licenseCtrl.text.trim(),
      );
      if (!mounted) return;
      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', _emailCtrl.text.trim());
        await prefs.setString('userOrg', _orgCtrl.text.trim());
        final data = result['data'] as Map<String, dynamic>? ?? {};
        final org = data['organization'] as Map<String, dynamic>? ?? {};
        await prefs.setString('orgId', org['orgId']?.toString() ?? '');
        if (!mounted) return;
        _snack(
          context,
          'Organization created successfully!',
          Colors.green[600]!,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      } else {
        setState(() => _isLoading = false);
        _snack(
          context,
          result['message']?.toString() ?? 'Something went wrong.',
          Colors.red[600]!,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack(
        context,
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Error: ${e.toString().replaceAll('Exception: ', '')}',
        Colors.red[600]!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14, 16, 14, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Info banner â”€â”€
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _accent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Icon(
                      Icons.add_business_rounded,
                      color: _accent,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Organization',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'You will be the admin of this org',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            _fieldLabel('EMAIL ADDRESS'),
            SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              cursorColor: _accent,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!isValidEmail(v)) return 'Invalid email format';
                return null;
              },
              decoration: _fieldDeco(
                hint: 'admin@school.com',
                icon: Icons.email_outlined,
              ),
            ),
            SizedBox(height: 12),

            _fieldLabel('ORGANIZATION NAME'),
            SizedBox(height: 6),
            TextFormField(
              controller: _orgCtrl,
              cursorColor: _accent,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Organization name required';
                if (!isValidOrgName(v)) return 'Minimum 2 characters';
                return null;
              },
              decoration: _fieldDeco(
                hint: 'e.g. St. Mary\'s School',
                icon: Icons.business_outlined,
              ),
            ),
            SizedBox(height: 12),

            _fieldLabel('CREATE PASSWORD'),
            SizedBox(height: 6),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              cursorColor: _accent,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (!isValidPassword(v))
                  return 'Password must be 6+ characters';
                return null;
              },
              decoration: _fieldDeco(
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 17,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            SizedBox(height: 12),

            _fieldLabel('LICENSE KEY (16 CHARACTERS)'),
            SizedBox(height: 6),
            TextFormField(
              controller: _licenseCtrl,
              cursorColor: _accent,
              maxLength: 16,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary, letterSpacing: 1.5),
              decoration: _fieldDeco(
                hint: 'XXXX-XXXX-XXXX-XXXX',
                icon: Icons.vpn_key_outlined,
              ).copyWith(counterText: ''),
              validator: (v) {
                if (v == null || v.isEmpty) return 'License key is required';
                if (v.trim().length != 16) return 'Must be exactly 16 characters';
                return null;
              },
            ),
            SizedBox(height: 20),

            _primaryBtn(
              label: 'Create Organization',
              isLoading: _isLoading,
              loadingLabel: 'Creating...',
              icon: Icons.add_business_rounded,
              onTap: (_isLoading || !_allFieldsValid) ? null : _handleCreate,
            ),
            SizedBox(height: 16),

            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                ),
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// JOIN ORG TAB
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _JoinOrgTab extends StatefulWidget {
  @override
  __JoinOrgTabState createState() => __JoinOrgTabState();
}

class __JoinOrgTabState extends State<_JoinOrgTab> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _errorMsg = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _errorMsg = '';
      _results = [];
    });
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/org/search?query=${Uri.encodeComponent(query.trim())}',
        ),
        headers: await ApiService.getHeaders(),
      );
      if (res.statusCode == 200 ||
          res.statusCode == 404 ||
          res.statusCode == 204) {
        List<dynamic> raw = [];
        try {
          final body = jsonDecode(res.body);
          if (body is List)
            raw = body;
          else if (body['organizations'] != null)
            raw = body['organizations'] as List;
          else if (body['data'] != null)
            raw = body['data'] as List;
          else if (body['results'] != null)
            raw = body['results'] as List;
        } catch (_) {
          // body might be empty on 204 â€” treat as no results
        }
        setState(() {
          _results = raw.map((e) => e as Map<String, dynamic>).toList();
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
          _errorMsg = 'Search failed. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _errorMsg = e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Something went wrong.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // â”€â”€ Search bar â”€â”€
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: TextField(
            controller: _searchCtrl,
            cursorColor: _accent,
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, city or phone...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 13,
              ),
              prefixIcon: Icon(Icons.search_rounded, color: _accent, size: 16),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _results = [];
                          _hasSearched = false;
                          _errorMsg = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide(
                  color: _accent.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
            ),
          ),
        ),

        // â”€â”€ Search button â”€â”€
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: _primaryBtn(
            label: 'Search Organizations',
            isLoading: _isSearching,
            loadingLabel: 'Searching...',
            icon: Icons.search_rounded,
            onTap: _isSearching ? null : () => _search(_searchCtrl.text),
          ),
        ),
        SizedBox(height: 12),

        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) return _buildEmptyState();
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _accent, strokeWidth: 3),
            SizedBox(height: 14),
            Text(
              'Searching organizations...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 50, color: Colors.grey[400]),
              SizedBox(height: 10),
              Text(
                _errorMsg,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 14),
              GestureDetector(
                onTap: () => _search(_searchCtrl.text),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: _accent, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Retry',
                        style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 50, color: Colors.grey[400]),
            SizedBox(height: 10),
            Text(
              'No organizations found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try a different name, city or phone number',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(14, 4, 14, 32),
      itemCount: _results.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (context, i) => _OrgResultCard(org: _results[i]),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14, 8, 14, 32),
      child: Column(
        children: [
          // â”€â”€ Illustration card â”€â”€
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.04),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _accent.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent.withOpacity(0.12),
                  ),
                  child: Icon(Icons.domain_rounded, color: _accent, size: 28),
                ),
                SizedBox(height: 14),
                Text(
                  'Find Your Organization',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Search by organization name, city,\nor phone number to find and join.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),

          // â”€â”€ Search tips â”€â”€
          _searchTip(
            Icons.business_outlined,
            'Search by name',
            'e.g. "St. Mary\'s School"',
          ),
          SizedBox(height: 8),
          _searchTip(
            Icons.location_city_outlined,
            'Search by city',
            'e.g. "Bengaluru" or "Mumbai"',
          ),
          SizedBox(height: 8),
          _searchTip(
            Icons.phone_outlined,
            'Search by phone',
            'e.g. "+919876543210"',
          ),
        ],
      ),
    );
  }

  Widget _searchTip(IconData icon, String title, String subtitle) => Container(
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(icon, color: _accent, size: 15),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// ORG RESULT CARD
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OrgResultCard extends StatelessWidget {
  final Map<String, dynamic> org;
  const _OrgResultCard({required this.org});

  @override
  Widget build(BuildContext context) {
    final name =
        org['name']?.toString() ?? org['orgName']?.toString() ?? 'Unknown';
    final city = org['city']?.toString() ?? '';
    final phone = org['phone']?.toString() ?? '';
    final orgId = org['orgId']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _accent.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: () => _showRoleSheet(context, name, orgId),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // â”€â”€ Avatar â”€â”€
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _accent.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          if (city.isNotEmpty) ...[
                            Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 2),
                            Text(
                              city,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          if (phone.isNotEmpty) ...[
                            Icon(
                              Icons.phone_outlined,
                              size: 11,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 2),
                            Text(
                              phone,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _accent.withOpacity(0.25)),
                  ),
                  child: Text(
                    'Join',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRoleSheet(BuildContext context, String orgName, String orgId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoleSelectionSheet(orgName: orgName, orgId: orgId),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// ROLE SELECTION BOTTOM SHEET
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RoleSelectionSheet extends StatelessWidget {
  final String orgName;
  final String orgId;
  const _RoleSelectionSheet({required this.orgName, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // â”€â”€ Drag handle â”€â”€
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 18),

          // â”€â”€ Org info row â”€â”€
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.04),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _accent.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Text(
                      orgName.isNotEmpty ? orgName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Joining',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        orgName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'CONTINUE AS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 3),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Select your role to create your account',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
            ),
          ),
          SizedBox(height: 14),

          // â”€â”€ Role cards â”€â”€
          Row(
            children: [
              Expanded(
                child: _RoleCard(
                  icon: Icons.school_rounded,
                  label: 'Teacher',
                  description: 'Manage classes,\nattendance & grades',
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          _TeacherRegisterSheet(orgName: orgName, orgId: orgId),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _RoleCard(
                  icon: Icons.person_rounded,
                  label: 'Student',
                  description: 'View timetable,\nresults & notices',
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          StudentRegisterSheet(orgName: orgName, orgId: orgId),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// ROLE CARD
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _accent.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(icon, color: _accent, size: 20),
            ),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 3),
            Text(
              description,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _accent.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: _accent, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// TEACHER REGISTER BOTTOM SHEET
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TeacherRegisterSheet extends StatefulWidget {
  final String orgName;
  final String orgId;
  const _TeacherRegisterSheet({required this.orgName, required this.orgId});
  @override
  __TeacherRegisterSheetState createState() => __TeacherRegisterSheetState();
}

class __TeacherRegisterSheetState extends State<_TeacherRegisterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final regRes = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/teacher/register'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'password': _passCtrl.text,
          'orgId': widget.orgId,
        }),
      );
      if (!mounted) return;
      final regBody = jsonDecode(regRes.body) as Map<String, dynamic>;

      if (regRes.statusCode != 200 && regRes.statusCode != 201) {
        setState(() => _isLoading = false);
        _snack(
          context,
          regBody['message']?.toString() ??
              'Registration failed. Please try again.',
          Colors.red[600]!,
        );
        return;
      }

      final teacherData = regBody['teacher'] as Map<String, dynamic>? ?? {};
      final teacherId = teacherData['teacherId']?.toString() ?? '';

      if (teacherId.isEmpty) {
        setState(() => _isLoading = false);
        _snack(
          context,
          'Registration error: Teacher ID missing.',
          Colors.red[600]!,
        );
        return;
      }

      await http.post(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/teacher/$teacherId/join-request',
        ),
        headers: await ApiService.getHeaders(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
      _snack(
        context,
        'Account created & join request sent! Sign in as Teacher.',
        Colors.teal[600]!,
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack(
        context,
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Something went wrong. Please try again.',
        Colors.red[600]!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ Drag handle â”€â”€
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // â”€â”€ Sheet header â”€â”€
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Icon(Icons.school_rounded, color: _accent, size: 20),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher Registration',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Joining ${widget.orgName}',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // â”€â”€ Org ID chip â”€â”€
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.domain_rounded, color: _accent, size: 12),
                    SizedBox(width: 5),
                    Text(
                      'Org ID: ${widget.orgId}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              _fieldLabel('FULL NAME'),
              SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                cursorColor: _accent,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2) return 'Enter a valid name';
                  return null;
                },
                decoration: _fieldDeco(
                  hint: 'e.g. John Doe',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              SizedBox(height: 12),

              _fieldLabel('EMAIL ADDRESS'),
              SizedBox(height: 6),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                cursorColor: _accent,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
                decoration: _fieldDeco(
                  hint: 'john@school.com',
                  icon: Icons.email_outlined,
                ),
              ),
              SizedBox(height: 12),

              _fieldLabel('CREATE PASSWORD'),
              SizedBox(height: 6),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                cursorColor: _accent,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
                decoration: _fieldDeco(
                  hint: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                  icon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 17,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              SizedBox(height: 20),

              _primaryBtn(
                label: 'Create Teacher Account',
                isLoading: _isLoading,
                loadingLabel: 'Creating Account...',
                icon: Icons.school_rounded,
                onTap: _isLoading ? null : _handleRegister,
              ),
              SizedBox(height: 10),

              Center(
                child: Text(
                  'By registering, your account will be reviewed\nby the organization admin before activation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

