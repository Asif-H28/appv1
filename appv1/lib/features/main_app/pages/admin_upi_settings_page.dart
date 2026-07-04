import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import '../../../../core/services/api_service.dart';

class AdminUpiSettingsPage extends StatefulWidget {
  const AdminUpiSettingsPage({Key? key}) : super(key: key);

  @override
  State<AdminUpiSettingsPage> createState() => _AdminUpiSettingsPageState();
}

class _AdminUpiSettingsPageState extends State<AdminUpiSettingsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  List<Map<String, dynamic>> _upiIds = [];
  List<Map<String, dynamic>> _customFees = [];

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/org/settings/payment');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          setState(() {
            _upiIds = List<Map<String, dynamic>>.from(data['upiIds'] ?? []);
            _customFees = List<Map<String, dynamic>>.from(data['customFees'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching payment settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    // Basic validation
    for (var u in _upiIds) {
      if ((u['title'] ?? '').toString().trim().isEmpty || (u['upiId'] ?? '').toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID and Title cannot be empty'), backgroundColor: Colors.red));
        return;
      }
    }
    for (var f in _customFees) {
      if ((f['title'] ?? '').toString().trim().isEmpty || f['amount'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee Title and Amount cannot be empty'), backgroundColor: Colors.red));
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final response = await ApiService.put(
        '/org/settings/payment',
        body: jsonEncode({
          'upiIds': _upiIds,
          'customFees': _customFees,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          if (mounted) {
            setState(() => _isEditing = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully'), backgroundColor: Colors.green));
            _fetchSettings();
          }
        } else {
          throw Exception(responseData['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saving payment settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addUpiId() {
    setState(() {
      _upiIds.add({'title': '', 'bankingName': '', 'upiId': ''});
    });
  }

  void _addCustomFee() {
    setState(() {
      _customFees.add({'title': '', 'amount': 0});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('UPI & Payment Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  // Cancel edits by refetching original data
                  _fetchSettings();
                  setState(() => _isEditing = false);
                } else {
                  setState(() => _isEditing = true);
                }
              },
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
              children: [
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: !_isEditing,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('UPI IDs', Icons.qr_code_scanner),
                        const SizedBox(height: 12),
                        if (_upiIds.isEmpty && !_isEditing)
                          _buildEmptyState('No UPI IDs added yet.'),
                        ..._upiIds.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final Map<String, dynamic> upi = entry.value;
                          return _buildUpiCard(index, upi);
                        }).toList(),
                        if (_isEditing)
                          Center(
                            child: TextButton.icon(
                              onPressed: _addUpiId,
                              icon: const Icon(Icons.add, color: Colors.teal),
                              label: const Text('Add UPI ID', style: TextStyle(color: Colors.teal)),
                            ),
                          ),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Custom Fees', Icons.attach_money),
                        const SizedBox(height: 12),
                        if (_customFees.isEmpty && !_isEditing)
                          _buildEmptyState('No Custom Fees added yet.'),
                        ..._customFees.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final Map<String, dynamic> fee = entry.value;
                          return _buildFeeCard(index, fee);
                        }).toList(),
                        if (_isEditing)
                          Center(
                            child: TextButton.icon(
                              onPressed: _addCustomFee,
                              icon: const Icon(Icons.add, color: Colors.teal),
                              label: const Text('Add Custom Fee', style: TextStyle(color: Colors.teal)),
                            ),
                          ),
                      ],
                    ),
                    ),
                  ),
                ),
                if (_isEditing)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal.shade700, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildUpiCard(int index, Map<String, dynamic> upi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: _isEditing
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: upi['title'],
                        decoration: const InputDecoration(labelText: 'Title (e.g., Primary UPI)', isDense: true),
                        onChanged: (val) => _upiIds[index]['title'] = val,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: upi['bankingName'],
                        decoration: const InputDecoration(labelText: 'Banking Name (e.g., HDFC Bank)', isDense: true),
                        onChanged: (val) => _upiIds[index]['bankingName'] = val,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: upi['upiId'],
                        decoration: const InputDecoration(labelText: 'UPI ID (e.g., 9999999999@ybl)', isDense: true),
                        onChanged: (val) => _upiIds[index]['upiId'] = val,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _upiIds.removeAt(index);
                    });
                  },
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.qr_code, color: Colors.teal.shade600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(upi['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(upi['bankingName'] ?? '', style: TextStyle(color: Colors.teal.shade800, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(upi['upiId'] ?? '', style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFeeCard(int index, Map<String, dynamic> fee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: _isEditing
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: fee['title'],
                        decoration: const InputDecoration(labelText: 'Title (e.g., General Fees)', isDense: true),
                        onChanged: (val) => _customFees[index]['title'] = val,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: fee['amount']?.toString() ?? '0',
                        decoration: const InputDecoration(labelText: 'Amount (₹)', isDense: true),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          _customFees[index]['amount'] = double.tryParse(val) ?? 0;
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _customFees.removeAt(index);
                    });
                  },
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.currency_rupee, color: Colors.teal.shade600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fee['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('₹ ${fee['amount']}', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
