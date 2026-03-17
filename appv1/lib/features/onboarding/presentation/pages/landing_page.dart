import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../main_app/main_app_screen.dart';
import '../../../main_app/pages/login_page.dart';
import '../widgets/custom_textfield.dart';

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
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _tabAccent => _selectedTab == 0 ? AppColors.primary : Colors.teal;

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
        child: Stack(
          children: [
            // ── Decorative blobs ──
            Positioned(
              top: -70,
              right: -50,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 400),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _tabAccent.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              top: 160,
              left: -40,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 400),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _tabAccent.withOpacity(0.07),
                ),
              ),
            ),

            Column(
              children: [
                // ─── Gradient Header ───
                AnimatedContainer(
                  duration: Duration(milliseconds: 350),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_tabAccent, _tabAccent.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Back + Logo ──
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                              SizedBox(width: 14),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.sync_alt,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SchoolSync',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'School Management Platform',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          Text(
                            _selectedTab == 0
                                ? 'Create Organization 🏫'
                                : 'Join Organization 🔍',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _selectedTab == 0
                                ? 'Set up your school on SchoolSync'
                                : 'Search and join an existing organization',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 22),

                          // ─── Tab Bar ───
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: _tabAccent,
                              unselectedLabelColor: Colors.white.withOpacity(
                                0.9,
                              ),
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              unselectedLabelStyle: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              padding: EdgeInsets.all(4),
                              dividerColor: Colors.transparent,
                              tabs: [
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_business_outlined,
                                        size: 15,
                                      ),
                                      SizedBox(width: 6),
                                      Text('Create'),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_rounded, size: 15),
                                      SizedBox(width: 6),
                                      Text('Join'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── Tab Views ───
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 20,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _CreateOrgTab(),
                        _JoinOrgTab(accentColor: Colors.teal),
                      ],
                    ),
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

// ─────────────────────────────────────────
//  CREATE ORG TAB
// ─────────────────────────────────────────
class _CreateOrgTab extends StatefulWidget {
  @override
  __CreateOrgTabState createState() => __CreateOrgTabState();
}

class __CreateOrgTabState extends State<_CreateOrgTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _orgController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _allFieldsValid = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkValid);
    _orgController.addListener(_checkValid);
    _passwordController.addListener(_checkValid);
  }

  void _checkValid() {
    setState(() {
      _allFieldsValid =
          _emailController.text.isNotEmpty &&
          isValidEmail(_emailController.text) &&
          _orgController.text.isNotEmpty &&
          isValidOrgName(_orgController.text) &&
          _passwordController.text.isNotEmpty &&
          isValidPassword(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _orgController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate() || !_allFieldsValid) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.createOrganization(
        orgName: _orgController.text.trim(),
        adminEmail: _emailController.text.trim(),
        adminPassword: _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', _emailController.text.trim());
        await prefs.setString('userOrg', _orgController.text.trim());

        final responseData = result['data'] as Map<String, dynamic>? ?? {};
        final orgData =
            responseData['organization'] as Map<String, dynamic>? ?? {};
        final orgId = orgData['orgId']?.toString() ?? '';
        await prefs.setString('orgId', orgId);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Organization created successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      } else {
        setState(() => _isLoading = false);
        _showError(
          result['message']?.toString() ??
              'Something went wrong. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Error: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Role header card ──
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.primary.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_business_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Organization',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'You will be the admin of this org',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            _label('Email Address'),
            SizedBox(height: 8),
            _inputBox(
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                cursorColor: AppColors.primary,
                style: TextStyle(fontSize: 15),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!isValidEmail(v)) return 'Invalid email format';
                  return null;
                },
                decoration: _deco(
                  hint: 'admin@school.com',
                  icon: Icons.email_outlined,
                  accent: AppColors.primary,
                ),
              ),
            ),
            SizedBox(height: 16),

            _label('Organization Name'),
            SizedBox(height: 8),
            _inputBox(
              child: TextFormField(
                controller: _orgController,
                cursorColor: AppColors.primary,
                style: TextStyle(fontSize: 15),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Organization name required';
                  if (!isValidOrgName(v)) return 'Minimum 2 characters';
                  return null;
                },
                decoration: _deco(
                  hint: 'e.g. St. Mary\'s School',
                  icon: Icons.business_outlined,
                  accent: AppColors.primary,
                ),
              ),
            ),
            SizedBox(height: 16),

            _label('Create Password'),
            SizedBox(height: 8),
            _inputBox(
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                cursorColor: AppColors.primary,
                style: TextStyle(fontSize: 15),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (!isValidPassword(v))
                    return 'Password must be 6+ characters';
                  return null;
                },
                decoration:
                    _deco(
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      accent: AppColors.primary,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
              ),
            ),
            SizedBox(height: 32),

            // ── Create Button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || !_allFieldsValid)
                    ? null
                    : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  child: _isLoading
                      ? Row(
                          key: ValueKey('loading'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Creating...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: ValueKey('idle'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Create Organization',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
            ),
            SizedBox(height: 24),

            // ── Already have account ──
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
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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

// ─────────────────────────────────────────
//  JOIN ORG TAB
// ─────────────────────────────────────────
class _JoinOrgTab extends StatefulWidget {
  final Color accentColor;
  const _JoinOrgTab({required this.accentColor});

  @override
  __JoinOrgTabState createState() => __JoinOrgTabState();
}

class __JoinOrgTabState extends State<_JoinOrgTab> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _errorMsg = '';

  @override
  void dispose() {
    _searchController.dispose();
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
      final url = Uri.parse(
        'https://appv1backend.onrender.com/api/org/search?query=${Uri.encodeComponent(query.trim())}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // Handle both array and nested response
        List<dynamic> rawList = [];
        if (body is List) {
          rawList = body;
        } else if (body['organizations'] != null) {
          rawList = body['organizations'] as List;
        } else if (body['data'] != null) {
          rawList = body['data'] as List;
        } else if (body['results'] != null) {
          rawList = body['results'] as List;
        }

        setState(() {
          _results = rawList.map((e) => e as Map<String, dynamic>).toList();
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
        // ── Search bar ──
        Container(
          color: AppColors.background,
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: widget.accentColor.withOpacity(0.2),
                width: 1.2,
              ),
            ),
            child: TextField(
              controller: _searchController,
              cursorColor: widget.accentColor,
              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search by name, city or phone number...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.55),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: widget.accentColor,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                            _hasSearched = false;
                            _errorMsg = '';
                          });
                        },
                      )
                    : Padding(
                        padding: EdgeInsets.all(10),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Search',
                            style: TextStyle(
                              color: widget.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
        ),

        // ── Search trigger button ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSearching
                  ? null
                  : () => _search(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: widget.accentColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: _isSearching
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Icon(Icons.search_rounded, size: 20),
              label: Text(
                _isSearching ? 'Searching...' : 'Search Organizations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),

        // ── Results / States ──
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return _buildEmptyState();
    }
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: widget.accentColor,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Searching organizations...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }
    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 52, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(
              _errorMsg,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _search(_searchController.text),
              icon: Icon(Icons.refresh, color: widget.accentColor),
              label: Text('Retry', style: TextStyle(color: widget.accentColor)),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(
              'No organizations found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try a different name, city or phone number',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 32),
      itemCount: _results.length,
      separatorBuilder: (_, __) => SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _OrgResultCard(org: _results[index], accentColor: widget.accentColor),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        children: [
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.accentColor.withOpacity(0.12)),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accentColor.withOpacity(0.08),
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accentColor.withOpacity(0.13),
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accentColor.withOpacity(0.2),
                      ),
                      child: Icon(
                        Icons.domain_rounded,
                        color: widget.accentColor,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Find Your Organization',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Search by organization name, city,\nor phone number to find and join.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // ── Search tips ──
          _searchTip(
            Icons.business_outlined,
            'Search by name',
            'e.g. "St. Mary\'s School"',
            widget.accentColor,
          ),
          SizedBox(height: 10),
          _searchTip(
            Icons.location_city_outlined,
            'Search by city',
            'e.g. "Bengaluru" or "Mumbai"',
            widget.accentColor,
          ),
          SizedBox(height: 10),
          _searchTip(
            Icons.phone_outlined,
            'Search by phone',
            'e.g. "+919876543210"',
            widget.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _searchTip(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  ORG RESULT CARD
// ─────────────────────────────────────────
// ─────────────────────────────────────────
//  ORG RESULT CARD (updated onTap)
// ─────────────────────────────────────────
class _OrgResultCard extends StatelessWidget {
  final Map<String, dynamic> org;
  final Color accentColor;

  const _OrgResultCard({required this.org, required this.accentColor});

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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: accentColor.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showRoleSelectionSheet(context, name, orgId),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // ── Org avatar ──
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          if (city.isNotEmpty) ...[
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 3),
                            Text(
                              city,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 10),
                          ],
                          if (phone.isNotEmpty) ...[
                            Icon(
                              Icons.phone_outlined,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 3),
                            Text(
                              phone,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Join',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  // ─── Step 1: Role selection bottom sheet ───
  void _showRoleSelectionSheet(
    BuildContext context,
    String orgName,
    String orgId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoleSelectionSheet(
        orgName: orgName,
        orgId: orgId,
        accentColor: accentColor,
      ),
    );
  }
}

// ─────────────────────────────────────────
//  ROLE SELECTION BOTTOM SHEET
// ─────────────────────────────────────────
class _RoleSelectionSheet extends StatelessWidget {
  final String orgName;
  final String orgId;
  final Color accentColor;

  const _RoleSelectionSheet({
    required this.orgName,
    required this.orgId,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 24),

          // ── Org info header ──
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.08),
                  accentColor.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accentColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      orgName.isNotEmpty ? orgName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Joining',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        orgName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          Text(
            'Continue as',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Select your role to create your account',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          SizedBox(height: 24),

          // ── Role cards ──
          Row(
            children: [
              Expanded(
                child: _RoleCard(
                  icon: Icons.school_rounded,
                  label: 'Teacher',
                  description: 'Manage classes,\nattendance & grades',
                  color: Colors.teal,
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
              SizedBox(width: 12),
              Expanded(
                child: _RoleCard(
                  icon: Icons.person_rounded,
                  label: 'Student',
                  description: 'View timetable,\nresults & notices',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Student registration coming soon!'),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.orange[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  ROLE CARD WIDGET
// ─────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  TEACHER REGISTER BOTTOM SHEET
// ─────────────────────────────────────────
class _TeacherRegisterSheet extends StatefulWidget {
  final String orgName;
  final String orgId;

  const _TeacherRegisterSheet({required this.orgName, required this.orgId});

  @override
  __TeacherRegisterSheetState createState() => __TeacherRegisterSheetState();
}

class __TeacherRegisterSheetState extends State<_TeacherRegisterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // ── Step 1: Register teacher ──
      final registerResponse = await http.post(
        Uri.parse('https://appv1backend.onrender.com/api/teacher/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'orgId': widget.orgId,
        }),
      );

      if (!mounted) return;
      final registerBody =
          jsonDecode(registerResponse.body) as Map<String, dynamic>;

      if (registerResponse.statusCode != 200 &&
          registerResponse.statusCode != 201) {
        setState(() => _isLoading = false);
        _showError(
          registerBody['message']?.toString() ??
              'Registration failed. Please try again.',
        );
        return;
      }

      // ── Extract teacherId from response ──
      final teacherData =
          registerBody['teacher'] as Map<String, dynamic>? ?? {};
      final teacherId = teacherData['teacherId']?.toString() ?? '';

      if (teacherId.isEmpty) {
        setState(() => _isLoading = false);
        _showError('Registration error: Teacher ID missing.');
        return;
      }

      // ── Step 2: Auto-send join request ──
      final joinResponse = await http.post(
        Uri.parse(
          'https://appv1backend.onrender.com/api/teacher/$teacherId/join-request',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      // Join request success or already sent — both are fine
      setState(() => _isLoading = false);
      Navigator.pop(context); // close sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ Account created & join request sent! Sign in as Teacher.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.teal[600],
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(
        e.toString().contains('SocketException')
            ? 'No internet connection.'
            : 'Something went wrong. Please try again.',
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal, Colors.teal.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher Registration',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Joining ${widget.orgName}',
                          style: TextStyle(
                            color: Colors.teal,
                            fontSize: 12,
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
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // ── Org chip ──
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.teal.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.domain_rounded, color: Colors.teal, size: 13),
                    SizedBox(width: 6),
                    Text(
                      'Org ID: ${widget.orgId}',
                      style: TextStyle(
                        color: Colors.teal,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // ── Full Name ──
              _sheetLabel('Full Name'),
              SizedBox(height: 8),
              _sheetInputBox(
                child: TextFormField(
                  controller: _nameController,
                  cursorColor: Colors.teal,
                  style: TextStyle(fontSize: 15),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Name is required';
                    if (v.trim().length < 2) return 'Enter a valid name';
                    return null;
                  },
                  decoration: _sheetDeco(
                    hint: 'e.g. John Doe',
                    icon: Icons.person_outline_rounded,
                    accent: Colors.teal,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // ── Email ──
              _sheetLabel('Email Address'),
              SizedBox(height: 8),
              _sheetInputBox(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: Colors.teal,
                  style: TextStyle(fontSize: 15),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  decoration: _sheetDeco(
                    hint: 'john@school.com',
                    icon: Icons.email_outlined,
                    accent: Colors.teal,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // ── Password ──
              _sheetLabel('Create Password'),
              SizedBox(height: 8),
              _sheetInputBox(
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  cursorColor: Colors.teal,
                  style: TextStyle(fontSize: 15),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  decoration:
                      _sheetDeco(
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        accent: Colors.teal,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                ),
              ),
              SizedBox(height: 28),

              // ── Register Button ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.teal.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: _isLoading
                        ? Row(
                            key: ValueKey('loading'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Creating Account...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: ValueKey('idle'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Create Teacher Account',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // ── Terms note ──
              Center(
                child: Text(
                  'By registering, your account will be reviewed\nby the organization admin before activation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
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

  Widget _sheetLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 13.5,
    ),
  );

  Widget _sheetInputBox({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
      border: Border.all(color: Colors.grey.withOpacity(0.12)),
    ),
    child: child,
  );

  InputDecoration _sheetDeco({
    required String hint,
    required IconData icon,
    required Color accent,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: AppColors.textSecondary.withOpacity(0.5),
      fontSize: 14,
    ),
    prefixIcon: Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Icon(icon, color: accent, size: 20),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: accent.withOpacity(0.4), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    errorStyle: TextStyle(color: Colors.red[400], fontSize: 12),
  );
}

// ─── Shared input helpers ───
Widget _label(String text) => Text(
  text,
  style: TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
    fontSize: 13.5,
  ),
);

Widget _inputBox({required Widget child}) => Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
    border: Border.all(color: Colors.grey.withOpacity(0.12)),
  ),
  child: child,
);

InputDecoration _deco({
  required String hint,
  required IconData icon,
  required Color accent,
}) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(
    color: AppColors.textSecondary.withOpacity(0.5),
    fontSize: 14,
  ),
  prefixIcon: Padding(
    padding: EdgeInsets.symmetric(horizontal: 14),
    child: Icon(icon, color: accent, size: 20),
  ),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: accent.withOpacity(0.4), width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
  ),
  filled: true,
  fillColor: Colors.white,
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  errorStyle: TextStyle(color: Colors.red[400], fontSize: 12),
);
