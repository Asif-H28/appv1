import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:appv1/features/main_app/pages/manage_vehicles_page.dart';
import 'package:appv1/features/main_app/pages/pwa_notification_panel.dart';
import 'package:flutter/material.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class TeacherProfileSection extends StatefulWidget {
  const TeacherProfileSection({super.key});

  @override
  State<TeacherProfileSection> createState() => _TeacherProfileSectionState();
}

class _TeacherProfileSectionState extends State<TeacherProfileSection> {
  bool _loading = true;
  bool _saving = false;
  bool _isCoordinator = false;
  String _teacherId = '';
  String _orgId = '';

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  String? _gender;
  String _email = '';

  final _formKey = GlobalKey<FormState>();
  static const _genderOptions = ['male', 'female', 'other'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _teacherId = prefs.getString('teacherId') ?? '';
    if (_teacherId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/teacher/$_teacherId/profile',
        ),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final t = (jsonDecode(res.body) as Map)['teacher'] as Map;
        _nameCtrl.text = t['name'] ?? '';
        _phoneCtrl.text = t['phoneNumber'] ?? '';
        _addressCtrl.text = t['address'] ?? '';
        _dobCtrl.text = (t['dob'] ?? '').toString().split('T').first;
        _email = t['email'] ?? '';
        _gender = _genderOptions.contains(t['gender']) ? t['gender'] : null;
        _isCoordinator = t['isTransportCoordinator'] ?? false;
        _orgId = t['orgId'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{};
      if (_nameCtrl.text.trim().isNotEmpty)
        body['name'] = _nameCtrl.text.trim();
      if (_phoneCtrl.text.trim().isNotEmpty)
        body['phoneNumber'] = _phoneCtrl.text.trim();
      if (_addressCtrl.text.trim().isNotEmpty)
        body['address'] = _addressCtrl.text.trim();
      if (_dobCtrl.text.trim().isNotEmpty) body['dob'] = _dobCtrl.text.trim();
      if (_gender != null) body['gender'] = _gender;

      final res = await http.put(
        Uri.parse(
          '${ApiConstants.apiBaseUrl}/teacher/$_teacherId/profile',
        ),
        headers: await ApiService.getHeaders(),
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _snack('Profile updated successfully', Colors.teal);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('teacherName', _nameCtrl.text.trim());
      } else {
        _snack('Failed to update profile', Colors.red[600]!);
      }
    } catch (_) {
      if (mounted) _snack('No internet connection', Colors.red[600]!);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 18),
      builder: (ctx, child) => Theme(
        data: ThemeData(
          colorScheme: const ColorScheme.light(primary: Colors.teal),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile header card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: Colors.teal.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.teal,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Teacher',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _email,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'Teacher',
                          style: TextStyle(
                            color: Colors.teal,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const PwaNotificationPanel(),
          const SizedBox(height: 24),

          Text(
            'EDIT PROFILE',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _addressCtrl,
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDob,
                  child: AbsorbPointer(
                    child: _buildField(
                      controller: _dobCtrl,
                      label: 'Date of Birth',
                      icon: Icons.cake_outlined,
                      hint: 'YYYY-MM-DD',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.wc_outlined,
                      color: Colors.teal,
                      size: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(3),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(3),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(3),
                      borderSide: const BorderSide(
                        color: Colors.teal,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  dropdownColor: Colors.white,
                  items: _genderOptions.map((g) {
                    return DropdownMenuItem(
                      value: g,
                      child: Text(
                        g[0].toUpperCase() + g.substring(1),
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _gender = v),
                  hint: Text(
                    'Select gender',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SAVE CHANGES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ),
                ),
                if (_isCoordinator) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageVehiclesPage(
                              orgId: _orgId,
                              coordinatorId: _teacherId,
                              coordinatorName: _nameCtrl.text,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.directions_bus_rounded, size: 18),
                      label: const Text('MANAGE VEHICLES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.teal, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Colors.teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }
}

