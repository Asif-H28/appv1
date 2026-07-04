import 'dart:async';
import 'package:flutter/material.dart';
import '../../admission/models/admission_model.dart';
import '../../admission/services/admission_service.dart';
import 'admin_admission_template_page.dart';
import 'admin_add_admission_page.dart';

class AdminAdmissionFormsPage extends StatefulWidget {
  const AdminAdmissionFormsPage({Key? key}) : super(key: key);

  @override
  State<AdminAdmissionFormsPage> createState() => _AdminAdmissionFormsPageState();
}

class _AdminAdmissionFormsPageState extends State<AdminAdmissionFormsPage> {
  final AdmissionService _admissionService = AdmissionService();
  bool _isLoading = true;
  List<AdmissionForm> _forms = [];
  int _currentPage = 1;
  int _totalPages = 1;
  String _searchQuery = '';
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchForms();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isFetchingMore &&
        _currentPage < _totalPages) {
      _fetchMoreForms();
    }
  }

  Future<void> _fetchForms({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
      _forms.clear();
    }
    setState(() => _isLoading = true);
    try {
      final result = await _admissionService.getSubmissions(
        page: _currentPage,
        limit: 15,
        search: _searchQuery,
      );
      setState(() {
        _forms = result['forms'] as List<AdmissionForm>;
        _totalPages = result['totalPages'] as int;
      });
    } catch (e) {
      debugPrint('Error fetching forms: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreForms() async {
    setState(() => _isFetchingMore = true);
    _currentPage++;
    try {
      final result = await _admissionService.getSubmissions(
        page: _currentPage,
        limit: 15,
        search: _searchQuery,
      );
      setState(() {
        _forms.addAll(result['forms'] as List<AdmissionForm>);
        _totalPages = result['totalPages'] as int;
      });
    } catch (e) {
      debugPrint('Error fetching more forms: $e');
      _currentPage--;
    } finally {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        _searchQuery = query;
        _fetchForms(resetPage: true);
      }
    });
  }

  void _openTemplateEditor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminAdmissionTemplatePage()),
    );
    if (result == true) {
      // Refresh forms if needed, but template change doesn't directly affect existing forms' displayed list.
    }
  }

  void _editForm(AdmissionForm form) {
    // Show a dialog to edit tutor, etc.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _EditAdmissionFormSheet(form: form, admissionService: _admissionService),
    ).then((updated) {
      if (updated == true) {
        _fetchForms(resetPage: true); // Refresh list
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Admission Forms', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_document),
            tooltip: 'Edit Template',
            onPressed: _openTemplateEditor,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.teal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: _isLoading && _forms.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : _forms.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'No admission forms found.' : 'No results for "$_searchQuery".',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _forms.length + (_isFetchingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _forms.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator(color: Colors.teal)),
                            );
                          }
                          final form = _forms[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                            child: InkWell(
                              onTap: () => _editForm(form),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${form.firstName} ${form.lastName}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Class ${form.studentClass}',
                                            style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.phone_android, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(form.phoneNumber, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                        const SizedBox(width: 16),
                                        Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(form.tutorName ?? 'Unassigned', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                      ],
                                    ),
                                    if (form.upiId != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.account_balance_wallet_outlined, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(form.upiId!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                        ],
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminAddAdmissionPage(admissionService: _admissionService),
            ),
          );
          if (result == true) {
            _fetchForms(resetPage: true);
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _EditAdmissionFormSheet extends StatefulWidget {
  final AdmissionForm form;
  final AdmissionService admissionService;

  const _EditAdmissionFormSheet({required this.form, required this.admissionService});

  @override
  State<_EditAdmissionFormSheet> createState() => _EditAdmissionFormSheetState();
}

class _EditAdmissionFormSheetState extends State<_EditAdmissionFormSheet> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _classCtrl;
  
  List<Map<String, dynamic>> _teachers = [];
  String? _selectedTutorId;
  String? _selectedTutorName;
  bool _isLoadingTeachers = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.form.firstName);
    _lastNameCtrl = TextEditingController(text: widget.form.lastName);
    _phoneCtrl = TextEditingController(text: widget.form.phoneNumber);
    _classCtrl = TextEditingController(text: widget.form.studentClass);
    _selectedTutorId = widget.form.tutorId;
    _selectedTutorName = widget.form.tutorName;
    _fetchTeachers();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _classCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTeachers() async {
    setState(() => _isLoadingTeachers = true);
    try {
      final teachers = await widget.admissionService.getTeachers(widget.form.orgId);
      if (mounted) {
        setState(() {
          _teachers = teachers;
          // Ensure selected tutor exists in the list, otherwise clear it or keep it (might be a deleted teacher).
          if (_selectedTutorId != null && !_teachers.any((t) => t['teacherId'] == _selectedTutorId)) {
             _teachers.add({'teacherId': _selectedTutorId, 'name': _selectedTutorName ?? 'Unknown'});
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTeachers = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updateData = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'studentClass': _classCtrl.text.trim(),
        'tutorId': _selectedTutorId,
        'tutorName': _selectedTutorName,
      };
      final success = await widget.admissionService.updateSubmission(widget.form.id, updateData);
      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update form')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating form')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Edit Admission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstNameCtrl,
                          decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lastNameCtrl,
                          decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _classCtrl,
                    decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 16),
                  const Text('Assign Tutor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 8),
                  if (_isLoadingTeachers)
                    const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedTutorId,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      hint: const Text('Select a tutor'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('None (Unassigned)')),
                        ..._teachers.map((t) {
                          return DropdownMenuItem<String>(
                            value: t['teacherId'],
                            child: Text(t['name'] ?? ''),
                          );
                        }).toList(),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedTutorId = val;
                          if (val != null) {
                            _selectedTutorName = _teachers.firstWhere((t) => t['teacherId'] == val)['name'];
                          } else {
                            _selectedTutorName = null;
                          }
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  // Display custom fields (Read-only for now, can be made editable if needed)
                  if (widget.form.customFields.isNotEmpty) ...[
                    const Divider(),
                    const Text('Custom Fields', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(height: 8),
                    ...widget.form.customFields.map((field) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: Text(field.title, style: TextStyle(color: Colors.grey.shade700))),
                            const Text(': '),
                            Expanded(flex: 3, child: Text(field.value, style: const TextStyle(fontWeight: FontWeight.w500))),
                          ],
                        ),
                      );
                    }).toList(),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
