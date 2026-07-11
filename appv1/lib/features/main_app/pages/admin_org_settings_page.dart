import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appv1/core/services/api_service.dart';

class AdminOrgSettingsPage extends StatefulWidget {
  const AdminOrgSettingsPage({Key? key}) : super(key: key);

  @override
  State<AdminOrgSettingsPage> createState() => _AdminOrgSettingsPageState();
}

class _AdminOrgSettingsPageState extends State<AdminOrgSettingsPage> {
  bool _isLoading = false;
  bool _isSaving = false;
  TimeOfDay? _selectedTime;
  String? _orgId;
  DateTime? _updatedAt;
  String? _currentRestrictionTime;
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getOrgSettings();
    setState(() => _isLoading = false);

    if (result['success']) {
      var data = result['data'];
      // Some endpoints return the payload wrapped in another 'data' object
      if (data != null && data['data'] != null && data['data'] is Map) {
        data = data['data'];
      }
      
      if (data != null) {
        if (data['orgId'] != null) _orgId = data['orgId'] as String;
        if (data['updatedAt'] != null) {
          _updatedAt = DateTime.tryParse(data['updatedAt'] as String);
        }
        
        if (data['tutorCheckInRestrictionTime'] != null) {
          final timeStr = data['tutorCheckInRestrictionTime'] as String;
          try {
            final parts = timeStr.split(':');
            _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
            _timeController.text = _selectedTime!.format(context);
            _currentRestrictionTime = _selectedTime!.format(context);
          } catch (e) {
            debugPrint('Error parsing time: $e');
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to load settings')),
        );
      }
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 18, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.teal.shade900,
              secondary: Colors.teal.shade200,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a restriction time')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final String apiTimeFormat = 
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
        
    final result = await ApiService.updateOrgSettings({
      'tutorCheckInRestrictionTime': apiTimeFormat,
    });
    
    if (result['success']) {
      await _fetchSettings(); // Refresh to get the new updatedAt timestamp
    }
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to save settings')),
      );
      if (result['success']) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Organization Settings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.teal.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.teal.shade100, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_orgId != null) ...[
                        const Text(
                          'Current Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.business_rounded, color: Colors.teal, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Organization ID',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _orgId!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.teal.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_currentRestrictionTime != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_filled_rounded, color: Colors.teal, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tutor Check-In Cut-off',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentRestrictionTime!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.teal.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (_updatedAt != null) ...[
                                const Divider(color: Colors.black12, height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.update_rounded, color: Colors.teal, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Last Updated: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_updatedAt!.toLocal())}',
                                      style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Colors.black12, height: 1),
                        const SizedBox(height: 24),
                      ],
                      const Text(
                        'Update Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Set the daily cut-off time for tutor check-ins (12-hour format).',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        onTap: _pickTime,
                        decoration: InputDecoration(
                          labelText: 'Restriction Time',
                          hintText: 'e.g. 6:30 PM',
                          labelStyle: const TextStyle(color: Colors.teal),
                          suffixIcon: const Icon(Icons.access_time_rounded, color: Colors.teal),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.teal.shade200, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.teal, width: 2),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Settings',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}
