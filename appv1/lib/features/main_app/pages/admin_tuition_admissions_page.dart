import 'dart:async';
import 'package:flutter/material.dart';
import '../../admission/services/tuition_application_service.dart';

class AdminTuitionAdmissionsPage extends StatefulWidget {
  const AdminTuitionAdmissionsPage({Key? key}) : super(key: key);

  @override
  State<AdminTuitionAdmissionsPage> createState() => _AdminTuitionAdmissionsPageState();
}

class _AdminTuitionAdmissionsPageState extends State<AdminTuitionAdmissionsPage> {
  String _searchQuery = '';
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          title: const Text('Admissions', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.teal,
                boxShadow: [
                  BoxShadow(color: Colors.teal.shade900.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      cursorColor: Colors.teal,
                      decoration: InputDecoration(
                        hintText: 'Search admissions...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: Colors.teal),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                  ),
                  const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.white,
                    indicatorWeight: 4,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    tabs: [
                      Tab(text: 'New'),
                      Tab(text: 'Reviewed'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AdmissionsListTab(status: 'pending', searchQuery: _searchQuery),
                  _AdmissionsListTab(status: null, searchQuery: _searchQuery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdmissionsListTab extends StatefulWidget {
  final String? status;
  final String searchQuery;
  const _AdmissionsListTab({required this.status, required this.searchQuery});

  @override
  State<_AdmissionsListTab> createState() => _AdmissionsListTabState();
}

class _AdmissionsListTabState extends State<_AdmissionsListTab> {
  final TuitionApplicationService _service = TuitionApplicationService();
  bool _isLoading = true;
  List<dynamic> _applications = [];
  Map<String, dynamic>? _settings;
  int _currentPage = 1;
  int _totalPages = 1;
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _AdmissionsListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _fetchApplications(resetPage: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isFetchingMore &&
        _currentPage < _totalPages) {
      _fetchMoreApplications();
    }
  }

  Future<void> _fetchApplications({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
      _applications.clear();
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getTuitionApplications(
        page: _currentPage,
        limit: 15,
        search: widget.searchQuery,
        status: widget.status,
      );
      if (result['success'] == true) {
        setState(() {
          _applications = result['data'] ?? [];
          _settings = result['settings'];
          _totalPages = result['pagination']?['totalPages'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tuition applications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreApplications() async {
    setState(() => _isFetchingMore = true);
    _currentPage++;
    try {
      final result = await _service.getTuitionApplications(
        page: _currentPage,
        limit: 15,
        search: widget.searchQuery,
        status: widget.status,
      );
      if (result['success'] == true) {
        setState(() {
          _applications.addAll(result['data'] ?? []);
          _settings = result['settings'] ?? _settings;
          _totalPages = result['pagination']?['totalPages'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint('Error fetching more tuition applications: $e');
      _currentPage--;
    } finally {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  void _deleteApplication(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Admission', style: TextStyle(color: Colors.teal)),
        content: const Text('Are you sure you want to delete this admission?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _service.deleteTuitionApplication(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
        _fetchApplications(resetPage: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete')));
      }
    }
  }

  void _reviewApplication(Map<String, dynamic> app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ReviewAdmissionSheet(
        application: app,
        settings: _settings,
        service: _service,
      ),
    ).then((updated) {
      if (updated == true) {
        _fetchApplications(resetPage: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _applications.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }
    
    if (_applications.isEmpty) {
      return Center(
        child: Text(
          widget.searchQuery.isEmpty ? 'No admissions found.' : 'No results for "${widget.searchQuery}".',
          style: TextStyle(color: Colors.teal.shade700, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _applications.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _applications.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }
        final app = _applications[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.teal.shade100),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      app['studentName'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        app['classOrGrade'] ?? 'N/A',
                        style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone_android, size: 14, color: Colors.teal.shade300),
                    const SizedBox(width: 4),
                    Text(app['contactNumber'] ?? 'N/A', style: TextStyle(color: Colors.teal.shade800, fontSize: 13)),
                    const SizedBox(width: 16),
                    Icon(Icons.email, size: 14, color: Colors.teal.shade300),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        app['email'] ?? 'N/A', 
                        style: TextStyle(color: Colors.teal.shade800, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Syllabus: ', style: TextStyle(color: Colors.teal.shade600, fontSize: 13)),
                    Text(app['boardOrSyllabus'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('School: ', style: TextStyle(color: Colors.teal.shade600, fontSize: 13)),
                    Expanded(child: Text(app['schoolOrCollegeName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _deleteApplication(app['_id']),
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _reviewApplication(app),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.rate_review, size: 18),
                      label: const Text('Review'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewAdmissionSheet extends StatefulWidget {
  final Map<String, dynamic> application;
  final Map<String, dynamic>? settings;
  final TuitionApplicationService service;

  const _ReviewAdmissionSheet({
    required this.application,
    required this.settings,
    required this.service,
  });

  @override
  State<_ReviewAdmissionSheet> createState() => _ReviewAdmissionSheetState();
}

class _ReviewAdmissionSheetState extends State<_ReviewAdmissionSheet> {
  int? _selectedUpiIndex;
  int? _selectedFeeIndex;
  int? _selectedTutorIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final upiList = (widget.settings?['upiIds'] as List?) ?? [];
    final feeList = (widget.settings?['customFees'] as List?) ?? [];
    final teacherList = (widget.settings?['teachers'] as List?) ?? [];

    final initialUpi = widget.application['upiId'];
    if (initialUpi != null) {
      final index = upiList.indexWhere((u) => u['upiId'] == initialUpi);
      _selectedUpiIndex = index >= 0 ? index : null;
    }

    final initialFee = widget.application['feeAmount'];
    if (initialFee != null) {
      final index = feeList.indexWhere((f) => (f['amount'] is int ? f['amount'] : int.tryParse(f['amount'].toString())) == initialFee);
      _selectedFeeIndex = index >= 0 ? index : null;
    }

    final initialTutor = widget.application['tutorId'];
    if (initialTutor != null) {
      final index = teacherList.indexWhere((t) => t['teacherId'] == initialTutor);
      _selectedTutorIndex = index >= 0 ? index : null;
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final upiList = (widget.settings?['upiIds'] as List?) ?? [];
      final feeList = (widget.settings?['customFees'] as List?) ?? [];
      final teacherList = (widget.settings?['teachers'] as List?) ?? [];

      final updateData = {
        if (_selectedFeeIndex != null) 'feeAmount': feeList[_selectedFeeIndex!]['amount'] is int ? feeList[_selectedFeeIndex!]['amount'] : int.tryParse(feeList[_selectedFeeIndex!]['amount'].toString()),
        if (_selectedUpiIndex != null) 'upiId': upiList[_selectedUpiIndex!]['upiId'],
        if (_selectedTutorIndex != null) 'tutorId': teacherList[_selectedTutorIndex!]['teacherId'],
        if (_selectedTutorIndex != null) 'tutorName': teacherList[_selectedTutorIndex!]['name'],
      };
      final success = await widget.service.reviewTuitionApplication(widget.application['_id'], updateData);
      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admission updated successfully')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update admission')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final upiList = (widget.settings?['upiIds'] as List?) ?? [];
    final feeList = (widget.settings?['customFees'] as List?) ?? [];
    final teacherList = (widget.settings?['teachers'] as List?) ?? [];
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset + safeBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Review Admission', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Student', widget.application['studentName']),
                  _buildDetailRow('Class', widget.application['classOrGrade']),
                  _buildDetailRow('Medium', widget.application['mediumOfStudy']),
                  _buildDetailRow('Address', widget.application['address']),
                  _buildDetailRow('Preferred', widget.application['preferredTuition']),
                  _buildDetailRow('Tuition Required', widget.application['tuitionRequiredFor']),
                  
                  const SizedBox(height: 16),
                  
                  const Text('Select UPI ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _selectedUpiIndex,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade200)),
                      isDense: true,
                    ),
                    hint: const Text('Select a UPI ID'),
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text('None')),
                      ...List.generate(upiList.length, (index) {
                        final u = upiList[index];
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text('${u['title']} (${u['upiId']})'),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedUpiIndex = val),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Select Custom Fee', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _selectedFeeIndex,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade200)),
                      isDense: true,
                    ),
                    hint: const Text('Select Fee'),
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text('None')),
                      ...List.generate(feeList.length, (index) {
                        final f = feeList[index];
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text('${f['title']} (₹${f['amount']})'),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedFeeIndex = val),
                  ),
                  const SizedBox(height: 16),

                  const Text('Assign Teacher', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final result = await showDialog<int>(
                        context: context,
                        builder: (ctx) => _TeacherSearchDialog(
                          teachers: teacherList,
                          selectedIndex: _selectedTutorIndex,
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          if (result == -1) {
                            _selectedTutorIndex = null;
                          } else {
                            _selectedTutorIndex = result;
                          }
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade200)),
                        isDense: true,
                        suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      child: Text(
                        _selectedTutorIndex != null 
                            ? (teacherList[_selectedTutorIndex!]['name'] ?? 'Unknown') 
                            : 'None (Unassigned)',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.teal.shade700))),
          const Text(': ', style: TextStyle(color: Colors.teal)),
          Expanded(flex: 3, child: Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87))),
        ],
      ),
    );
  }
}

class _TeacherSearchDialog extends StatefulWidget {
  final List<dynamic> teachers;
  final int? selectedIndex;
  const _TeacherSearchDialog({required this.teachers, this.selectedIndex});
  @override
  State<_TeacherSearchDialog> createState() => _TeacherSearchDialogState();
}

class _TeacherSearchDialogState extends State<_TeacherSearchDialog> {
  String _query = '';
  
  @override
  Widget build(BuildContext context) {
    final filtered = widget.teachers.asMap().entries.where((e) {
      final name = (e.value['name'] ?? '').toString().toLowerCase();
      return name.contains(_query.toLowerCase());
    }).toList();

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: TextField(
        decoration: InputDecoration(
          hintText: 'Search Teacher...',
          prefixIcon: const Icon(Icons.search, color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.teal, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        cursorColor: Colors.teal,
        onChanged: (val) => setState(() => _query = val),
      ),
      contentPadding: const EdgeInsets.all(8),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: ListView(
          children: [
            ListTile(
              title: const Text('None (Unassigned)', style: TextStyle(color: Colors.teal)),
              selected: widget.selectedIndex == null,
              selectedTileColor: Colors.teal.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () => Navigator.pop(context, -1),
            ),
            ...filtered.map((e) => ListTile(
              title: Text(e.value['name'] ?? '', style: const TextStyle(color: Colors.black87)),
              selected: widget.selectedIndex == e.key,
              selectedTileColor: Colors.teal.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () => Navigator.pop(context, e.key),
            )),
          ],
        ),
      ),
    );
  }
}
