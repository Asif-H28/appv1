import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:appv1/features/main_app/pages/teacher_join_requests_page.dart'
    show TeacherJoinRequestsPage;
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

class OrganizationPage extends StatefulWidget {
  @override
  _OrganizationPageState createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _teachersController = TextEditingController(text: '0');
  final _nonTeachingController = TextEditingController(text: '0');

  bool _isSaving = false;
  bool _isLoading = true; // ← true on first load
  bool _hasError = false; // ← shows retry UI on fetch failure
  bool _showForm = false;
  String _orgId = '';
  Map<String, dynamic> orgData = {};

  final List<Map<String, dynamic>> _members = [
    {
      'name': 'Phone Number',
      'preview': '...',
      'color': Colors.indigo,
      'icon': Icons.phone,
    },
    {
      'name': 'Address',
      'preview': '...',
      'color': Colors.teal,
      'icon': Icons.location_on,
    },
    {
      'name': 'City & State',
      'preview': '...',
      'color': Colors.purple,
      'icon': Icons.business,
    },
    {
      'name': 'Country',
      'preview': '...',
      'color': Colors.orange,
      'icon': Icons.public,
    },
    {
      'name': 'Teachers',
      'preview': '...',
      'color': Colors.blue,
      'icon': Icons.school,
    },
    {
      'name': 'Non-Teaching Staff',
      'preview': '...',
      'color': Colors.green,
      'icon': Icons.support_agent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  // ─── Step 1: Load orgId from prefs, then fetch from API ───
  Future<void> _initPage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final prefs = await SharedPreferences.getInstance();
    _orgId = prefs.getString('orgId') ?? '';
    final orgName = prefs.getString('userOrg') ?? 'ABC School';

    // Set org name immediately so header shows while loading
    setState(() {
      orgData = {'orgName': orgName};
    });

    if (_orgId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    await _fetchOrgProfile();
  }

  // ─── GET API: Fetch org profile ───
  Future<void> _fetchOrgProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final url = Uri.parse(
        '${ApiConstants.apiBaseUrl}/org/$_orgId/profile',
      );

      final response = await http.get(
        url,
        headers: await ApiService.getHeaders(),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        // ── Flexible parsing: handle both flat and nested responses ──
        final data =
            (body['organization'] ?? body['data'] ?? body)
                as Map<String, dynamic>;

        final phone = data['phone']?.toString() ?? '';
        final address = data['address']?.toString() ?? '';
        final city = data['city']?.toString() ?? '';
        final state = data['state']?.toString() ?? '';
        final country = data['country']?.toString() ?? 'India';
        final teachers = data['teachers']?.toString() ?? '0';
        final nonTeaching =
            (data['nonTeaching'] ?? data['non_teaching'])?.toString() ?? '0';
        final orgName =
            data['orgName']?.toString() ??
            data['name']?.toString() ??
            orgData['orgName'] ??
            'ABC School';

        // Populate controllers
        _phoneController.text = phone;
        _addressController.text = address;
        _cityController.text = city;
        _stateController.text = state;
        _countryController.text = country;
        _teachersController.text = teachers;
        _nonTeachingController.text = nonTeaching;

        // Persist to SharedPreferences for offline use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('orgPhone', phone);
        await prefs.setString('orgAddress', address);
        await prefs.setString('orgCity', city);
        await prefs.setString('orgState', state);
        await prefs.setString('orgCountry', country);
        await prefs.setString('orgTeachers', teachers);
        await prefs.setString('orgNonTeaching', nonTeaching);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _hasError = false;
          orgData = {
            'orgName': orgName,
            'phone': phone,
            'address': address,
            'city': city,
            'state': state,
            'country': country,
            'teachers': teachers,
            'nonTeaching': nonTeaching,
          };
          _refreshPreviews(
            phone,
            address,
            city,
            state,
            country,
            teachers,
            nonTeaching,
          );
        });
      } else {
        _fallbackToLocal();
      }
    } catch (e) {
      // Network error → fallback to locally cached values
      if (!mounted) return;
      _fallbackToLocal();
    }
  }

  // ─── Fallback: use SharedPreferences cache if API fails ───
  Future<void> _fallbackToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('orgPhone') ?? '';
    final address = prefs.getString('orgAddress') ?? '';
    final city = prefs.getString('orgCity') ?? '';
    final state = prefs.getString('orgState') ?? '';
    final country = prefs.getString('orgCountry') ?? 'India';
    final teachers = prefs.getString('orgTeachers') ?? '0';
    final nonTeaching = prefs.getString('orgNonTeaching') ?? '0';
    int _pendingCount = 0;

    _phoneController.text = phone;
    _addressController.text = address;
    _cityController.text = city;
    _stateController.text = state;
    _countryController.text = country;
    _teachersController.text = teachers;
    _nonTeachingController.text = nonTeaching;

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _hasError = false; // show cached data, not error
      orgData = {
        ...orgData,
        'phone': phone,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'teachers': teachers,
        'nonTeaching': nonTeaching,
      };
      _refreshPreviews(
        phone,
        address,
        city,
        state,
        country,
        teachers,
        nonTeaching,
      );
    });
  }

  // ─── Helper: refresh list tile previews ───
  void _refreshPreviews(
    String phone,
    String address,
    String city,
    String state,
    String country,
    String teachers,
    String nonTeaching,
  ) {
    _members[0]['preview'] = phone.isNotEmpty
        ? phone
        : 'Tap to add phone number...';
    _members[1]['preview'] = address.isNotEmpty
        ? address
        : 'Tap to add address...';
    _members[2]['preview'] = (city.isNotEmpty || state.isNotEmpty)
        ? '$city, $state'
        : 'Tap to add city and state...';
    _members[3]['preview'] = country.isNotEmpty ? country : 'India';
    _members[4]['preview'] = '$teachers teachers registered';
    _members[5]['preview'] = '$nonTeaching non-teaching staff';
  }

  // ─── PUT API: Update org profile ───
  Future<void> _updateOrgProfile() async {
    if (_orgId.isEmpty)
      throw Exception('Organization ID not found. Please re-login.');

    final url = Uri.parse(
      '${ApiConstants.apiBaseUrl}/org/$_orgId/profile',
    );

    final response = await http.put(
      url,
      headers: await ApiService.getHeaders(),
      body: jsonEncode({
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
        'teachers': int.tryParse(_teachersController.text.trim()) ?? 0,
        'nonTeaching': int.tryParse(_nonTeachingController.text.trim()) ?? 0,
      }),
    );

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('orgPhone', _phoneController.text.trim());
      await prefs.setString('orgAddress', _addressController.text.trim());
      await prefs.setString('orgCity', _cityController.text.trim());
      await prefs.setString('orgState', _stateController.text.trim());
      await prefs.setString('orgCountry', _countryController.text.trim());
      await prefs.setString('orgTeachers', _teachersController.text.trim());
      await prefs.setString(
        'orgNonTeaching',
        _nonTeachingController.text.trim(),
      );
    } else {
      final body = jsonDecode(response.body);
      throw Exception(
        body['message'] ?? 'Failed to update. (${response.statusCode})',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // ─── Gradient Header ───
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Organization\nDetails',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        Row(
                          children: [
                            // ── Refresh button ──
                            if (!_isLoading)
                              Container(
                                margin: EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  ),
                                  onPressed: _fetchOrgProfile,
                                  tooltip: 'Refresh',
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _showForm ? Icons.close : Icons.edit,
                                  color: Colors.white,
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(
                                        () => _showForm = !_showForm,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14),

                  // Story-style avatar row
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: (_members[index]['color'] as Color)
                                .withOpacity(0.85),
                            child: Icon(
                              _members[index]['icon'] as IconData,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ─── White Body ───
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isLoading
                  ? _buildLoadingState()
                  : _hasError
                  ? _buildErrorState()
                  : _showForm
                  ? _buildEditForm()
                  : _buildDetailsList(),
            ),
          ),
        ],
      ),

      floatingActionButton: (!_isLoading && !_hasError && _showForm)
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveOrgDetails,
              backgroundColor: AppColors.primary,
              elevation: 4,
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : null,
    );
  }

  // ─── Loading shimmer-style state ───
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 60),
                CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Fetching organization details...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error / retry state ───
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Could not load organization details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(Icons.refresh),
              label: Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Details List View ───
  Widget _buildDetailsList() {
    int _pendingCount = 0;
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 12),
      children: [
        // ── Teacher Join Requests entry ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Container(
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
              border: Border.all(color: Colors.indigo.withOpacity(0.15)),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  color: Colors.indigo,
                  size: 22,
                ),
              ),
              title: Text(
                'Teacher Join Requests',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Approve or reject teacher requests',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_pendingCount > 0)
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_pendingCount new',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TeacherJoinRequestsPage()),
              ),
            ),
          ),
        ),

        SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'ORGANIZATION INFO',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        SizedBox(height: 4),

        // ── Org info tiles ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Container(
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _members.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 64,
                endIndent: 16,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final item = _members[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    item['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    item['preview'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                  onTap: () => setState(() => _showForm = true),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  // ─── Edit Form ───
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrgNameCard(),
            SizedBox(height: 20),
            Text(
              'Complete Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16),

            _buildInputCard(
              child: Column(
                children: [
                  _buildField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v!.isEmpty ? 'Phone number required' : null,
                  ),
                  _divider(),
                  _buildField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'Address required' : null,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            _buildInputCard(
              child: Column(
                children: [
                  _buildField(
                    controller: _cityController,
                    label: 'City',
                    icon: Icons.location_city,
                    validator: (v) => v!.isEmpty ? 'City required' : null,
                  ),
                  _divider(),
                  _buildField(
                    controller: _stateController,
                    label: 'State',
                    icon: Icons.map,
                    validator: (v) => v!.isEmpty ? 'State required' : null,
                  ),
                  _divider(),
                  _buildField(
                    controller: _countryController,
                    label: 'Country',
                    icon: Icons.public,
                    validator: (v) => v!.isEmpty ? 'Country required' : null,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            _buildInputCard(
              child: Column(
                children: [
                  _buildField(
                    controller: _teachersController,
                    label: 'Teachers (optional)',
                    icon: Icons.school,
                    keyboardType: TextInputType.number,
                  ),
                  _divider(),
                  _buildField(
                    controller: _nonTeachingController,
                    label: 'Non-Teaching Staff (optional)',
                    icon: Icons.support_agent,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgNameCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Icon(Icons.business, color: AppColors.primary),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organization Name',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  orgData['orgName'] ?? 'Loading...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Admin',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: EdgeInsets.symmetric(vertical: 4), child: child),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          errorStyle: TextStyle(color: Colors.red[400]),
        ),
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, indent: 52, endIndent: 16, color: Colors.grey[200]);

  Future<void> _saveOrgDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _updateOrgProfile();
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _showForm = false;
        _refreshPreviews(
          _phoneController.text,
          _addressController.text,
          _cityController.text,
          _stateController.text,
          _countryController.text,
          _teachersController.text,
          _nonTeachingController.text,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Organization profile updated!'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.toString().contains('SocketException')
                      ? 'No internet connection.'
                      : e.toString().replaceAll('Exception: ', ''),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _teachersController.dispose();
    _nonTeachingController.dispose();
    super.dispose();
  }
}

