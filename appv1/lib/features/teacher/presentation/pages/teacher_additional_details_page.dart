import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/network/dio_http_adapter.dart' as http;
import '../../../../core/constants/app_colors.dart';

class TeacherAdditionalDetailsPage extends StatefulWidget {
  const TeacherAdditionalDetailsPage({super.key});

  @override
  State<TeacherAdditionalDetailsPage> createState() => _TeacherAdditionalDetailsPageState();
}

class _TeacherAdditionalDetailsPageState extends State<TeacherAdditionalDetailsPage> {
  bool _loading = true;
  bool _saving = false;
  bool _isEditing = false;
  String _teacherId = '';
  String _orgId = '';

  List<Map<String, String>> _records = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _teacherId = prefs.getString('teacherId') ?? '';
    _orgId = prefs.getString('orgId') ?? '';
    await _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    if (_teacherId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/teacher-additional-record/$_teacherId'),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final data = body['data'] as Map?;
        final rawRecords = (data != null ? data['records'] as List? : []) ?? [];
        setState(() {
          _records = rawRecords.map((r) {
            final map = r as Map<String, dynamic>;
            return map.map((k, v) => MapEntry(k, v.toString()));
          }).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveRecords() async {
    if (_teacherId.isEmpty || _orgId.isEmpty) return;
    setState(() => _saving = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/teacher-additional-record'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'teacherId': _teacherId,
          'orgId': _orgId,
          'records': _records,
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack('Records saved successfully', Colors.teal);
        setState(() => _isEditing = false);
      } else {
        _snack('Failed to save records', Colors.red[600]!);
      }
    } catch (_) {
      if (mounted) _snack('No internet connection', Colors.red[600]!);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _addRecord() async {
    String newKey = '';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        title: const Text('Add Field', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Field Name (e.g., Degree Title)',
            labelStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          onChanged: (v) => newKey = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (newKey.trim().isNotEmpty) {
                Navigator.pop(ctx, newKey.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _records.add({result: ''});
      });
    }
  }

  void _deleteRecord(int index) {
    setState(() {
      _records.removeAt(index);
    });
  }

  Future<void> _addField(int recordIndex) async {
    String newKey = '';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        title: const Text('Add Field', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Field Name (e.g., Degree Title)',
            labelStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          onChanged: (v) => newKey = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (newKey.trim().isNotEmpty) {
                Navigator.pop(ctx, newKey.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _records[recordIndex][result] = '';
      });
    }
  }

  void _removeField(int recordIndex, String key) {
    setState(() {
      _records[recordIndex].remove(key);
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 1,
        title: const Text(
          'Additional Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_loading)
            Center(
              child: GestureDetector(
                onTap: () {
                  if (_isEditing) {
                    if (!_saving) _saveRecords();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save' : 'Edit',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2),
            )
          : (_isEditing ? _buildEditBody() : _buildViewBody()),
    );
  }

  Widget _buildViewBody() {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No additional details found.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isEditing = true);
              },
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        final title = index == 0 ? 'Your Education Details' : 'Education Details #${index + 1}';
        final isLast = index == _records.length - 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
              padding: const EdgeInsets.only(left: 24, bottom: 20, top: 12),
              decoration: BoxDecoration(
                border: !isLast
                    ? Border(left: BorderSide(color: Colors.grey[300]!, width: 2))
                    : null,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: record.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.value.isEmpty ? 'N/A' : e.value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditBody() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _records.length + 1,
            itemBuilder: (context, index) {
              if (index == _records.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _addRecord,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'ADD RECORD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return _buildRecordCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(int index) {
    final record = _records[index];
    final keys = record.keys.toList();
    final title = index == 0 ? 'Your Education Details' : 'Education Details #${index + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, color: Colors.teal, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _deleteRecord(index),
                  child: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 18),
                ),
              ],
            ),
          ),
          // Fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...keys.map((key) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: record[key],
                            onChanged: (v) => _records[index][key] = v,
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: key,
                              labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(3),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(3),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.teal, width: 1.5),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeField(index, key),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Icon(Icons.remove_circle_outline_rounded, color: Colors.red[300], size: 18),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _addField(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.teal.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add_rounded, color: Colors.teal, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Add Field',
                          style: TextStyle(
                            color: Colors.teal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
}
