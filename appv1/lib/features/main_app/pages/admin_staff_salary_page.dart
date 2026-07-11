import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/constants/api_constants.dart';

class AdminStaffSalaryPage extends StatefulWidget {
  const AdminStaffSalaryPage({Key? key}) : super(key: key);

  @override
  State<AdminStaffSalaryPage> createState() => _AdminStaffSalaryPageState();
}

class _AdminStaffSalaryPageState extends State<AdminStaffSalaryPage> {
  bool _isLoading = false;
  String _orgId = '';
  List<dynamic> _teachers = [];
  final Set<String> _selectedTeacherIds = {};

  @override
  void initState() {
    super.initState();
    _loadOrgIdAndFetchData();
  }

  Future<void> _loadOrgIdAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orgId = prefs.getString('orgId') ?? '';
    });
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    if (_orgId.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get('/teacher/salary/list/$_orgId');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _teachers = data['teachers'] ?? [];
            _selectedTeacherIds.clear();
          });
        } else {
          _showSnackBar(data['message'] ?? 'Failed to load teachers', isError: true);
        }
      } else {
        _showSnackBar('Failed to load teachers', isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSalary(List<String> teacherIds, String type, int amount) async {
    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.put(
        '/teacher/salary/bulk',
        body: jsonEncode({
          'teacherIds': teacherIds,
          'salaryType': type,
          'salaryAmount': amount,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSnackBar(data['message'] ?? 'Salary updated successfully');
          setState(() {
            _selectedTeacherIds.clear();
          });
          _fetchTeachers();
        } else {
          _showSnackBar(data['message'] ?? 'Failed to update salary', isError: true);
        }
      } else {
        _showSnackBar('Failed to update salary', isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUpdateSalarySheet({List<String>? teacherIds}) {
    final targetIds = teacherIds ?? _selectedTeacherIds.toList();
    if (targetIds.isEmpty) return;
    final targetNames = _teachers
        .where((t) => targetIds.contains(t['teacherId']?.toString()))
        .map((t) => t['name']?.toString() ?? 'Unknown')
        .toList();
        
    String subtitle = 'Updating for ${targetIds.length} teacher(s)';
    if (targetNames.isNotEmpty) {
      if (targetNames.length == 1) {
        subtitle = 'Updating for ${targetNames.first}';
      } else if (targetNames.length <= 3) {
        subtitle = 'Updating for ${targetNames.join(', ')}';
      } else {
        subtitle = 'Updating for ${targetNames.take(2).join(', ')} and ${targetNames.length - 2} others';
      }
    }

    String selectedType = 'monthwise';
    final TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        targetIds.length > 1 ? 'Bulk Salary Update' : 'Update Salary',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Salary Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeOption(
                          title: 'Month-wise',
                          isSelected: selectedType == 'monthwise',
                          onTap: () => setSheetState(() => selectedType = 'monthwise'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeOption(
                          title: 'Day-wise',
                          isSelected: selectedType == 'daywise',
                          onTap: () => setSheetState(() => selectedType = 'daywise'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Colors.teal),
                      hintText: 'Enter amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.teal, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = int.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          _showSnackBar('Please enter a valid amount', isError: true);
                          return;
                        }
                        Navigator.pop(context);
                        _updateSalary(targetIds, selectedType, amount);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Salary',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeOption({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.teal : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleSelection(String teacherId) {
    setState(() {
      if (_selectedTeacherIds.contains(teacherId)) {
        _selectedTeacherIds.remove(teacherId);
      } else {
        _selectedTeacherIds.add(teacherId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedTeacherIds.length == _teachers.length) {
        _selectedTeacherIds.clear();
      } else {
        _selectedTeacherIds.addAll(_teachers.map((t) => t['teacherId'].toString()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSelectionMode = _selectedTeacherIds.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Staff Salary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_teachers.isNotEmpty)
            IconButton(
              icon: Icon(
                _selectedTeacherIds.length == _teachers.length ? Icons.deselect_rounded : Icons.select_all_rounded,
              ),
              onPressed: _selectAll,
              tooltip: _selectedTeacherIds.length == _teachers.length ? 'Deselect All' : 'Select All',
            ),
        ],
      ),
      body: _isLoading && _teachers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: _fetchTeachers,
              color: Colors.teal,
              child: _teachers.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No teachers found', style: TextStyle(color: Colors.grey))),
                      ],
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: (isSelectionMode ? 160 : 80) + MediaQuery.of(context).padding.bottom, 
                        top: 12, left: 16, right: 16
                      ),
                      itemCount: _teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = _teachers[index];
                        final teacherId = teacher['teacherId']?.toString() ?? '';
                        final isSelected = _selectedTeacherIds.contains(teacherId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: isSelected ? Colors.teal : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (isSelectionMode) {
                                _toggleSelection(teacherId);
                              }
                            },
                            onLongPress: () => _toggleSelection(teacherId),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  if (isSelectionMode) ...[
                                    Icon(
                                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      color: isSelected ? Colors.teal : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  CircleAvatar(
                                    backgroundColor: Colors.teal.withOpacity(0.1),
                                    child: Text(
                                      (teacher['name']?.toString() ?? 'T')[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          teacher['name'] ?? 'Unknown Teacher',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID: $teacherId',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (teacher['salaryType'] != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.currency_rupee_rounded, size: 14, color: Colors.teal.shade700),
                                              Text(
                                                '${teacher['salaryAmount']} (${teacher['salaryType'] == 'monthwise' ? 'Monthly' : 'Daily'})',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.teal.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (!isSelectionMode)
                                    ElevatedButton(
                                      onPressed: () => _showUpdateSalarySheet(teacherIds: [teacherId]),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal.shade50,
                                        foregroundColor: Colors.teal,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Update Salary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isSelectionMode
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _showUpdateSalarySheet(),
                icon: const Icon(Icons.payments_rounded),
                label: Text(
                  'Update Salary for ${_selectedTeacherIds.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            )
          : null,
    );
  }
}
