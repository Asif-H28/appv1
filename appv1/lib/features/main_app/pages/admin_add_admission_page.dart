import 'package:flutter/material.dart';
import '../../admission/models/admission_model.dart';
import '../../admission/services/admission_service.dart';

class AdminAddAdmissionPage extends StatefulWidget {
  final AdmissionService admissionService;

  const AdminAddAdmissionPage({Key? key, required this.admissionService}) : super(key: key);

  @override
  State<AdminAddAdmissionPage> createState() => _AdminAddAdmissionPageState();
}

class _AdminAddAdmissionPageState extends State<AdminAddAdmissionPage> {
  final _formKey = GlobalKey<FormState>();

  // Standard fields
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _schoolNameCtrl = TextEditingController();
  final _classCtrl = TextEditingController();

  DateTime? _dob;
  DateTime? _admissionDate = DateTime.now();

  List<AdmissionFormTemplateField> _templateFields = [];
  final Map<String, TextEditingController> _customFieldControllers = {};

  List<Map<String, dynamic>> _upiIds = [];
  List<Map<String, dynamic>> _customFees = [];
  List<Map<String, dynamic>> _teachers = [];

  Map<String, dynamic>? _selectedUpi;
  Map<String, dynamic>? _selectedCustomFee;
  Map<String, dynamic>? _selectedTeacher;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _genderCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _schoolNameCtrl.dispose();
    _classCtrl.dispose();
    for (var ctrl in _customFieldControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.admissionService.getTemplateData();
      if (mounted) {
        setState(() {
          if (data['admissionFormTemplate'] != null) {
            _templateFields = (data['admissionFormTemplate'] as List)
                .map((e) => AdmissionFormTemplateField.fromJson(e))
                .toList();
          }
          if (data['upiIds'] != null) {
            _upiIds = List<Map<String, dynamic>>.from(data['upiIds']);
          }
          if (data['customFees'] != null) {
            _customFees = List<Map<String, dynamic>>.from(data['customFees']);
          }
          if (data['teachers'] != null) {
            _teachers = List<Map<String, dynamic>>.from(data['teachers']);
          }
          for (var field in _templateFields) {
            _customFieldControllers[field.title] = TextEditingController();
          }
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDob) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDob ? DateTime(2010) : DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        if (isDob) {
          _dob = picked;
        } else {
          _admissionDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Date of Birth')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final customFields = _templateFields.map((f) {
        return {
          'title': f.title,
          'value': _customFieldControllers[f.title]?.text.trim() ?? '',
        };
      }).toList();

      final data = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'gender': _genderCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'street': _streetCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'admissionDate': _admissionDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'schoolName': _schoolNameCtrl.text.trim(),
        'studentClass': _classCtrl.text.trim(),
        'dateOfBirth': _dob?.toIso8601String(),
        'customFields': customFields,
        if (_selectedCustomFee != null) 'feeTitle': _selectedCustomFee!['title'],
        if (_selectedCustomFee != null) 'feeAmount': _selectedCustomFee!['amount'],
        if (_selectedUpi != null) 'upiTitle': _selectedUpi!['title'],
        if (_selectedUpi != null) 'upiBankingName': _selectedUpi!['bankingName'],
        if (_selectedUpi != null) 'upiId': _selectedUpi!['upiId'],
        if (_selectedTeacher != null) 'tutorId': _selectedTeacher!['teacherId'],
        if (_selectedTeacher != null) 'tutorName': _selectedTeacher!['name'],
      };

      final success = await widget.admissionService.createSubmission(data);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admission form submitted successfully')));
        Navigator.pop(context, true); // true to indicate success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit form')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('New Admission', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Basic Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameCtrl,
                                  decoration: const InputDecoration(labelText: 'First Name *', border: OutlineInputBorder(), isDense: true),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameCtrl,
                                  decoration: const InputDecoration(labelText: 'Last Name *', border: OutlineInputBorder(), isDense: true),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _genderCtrl,
                                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder(), isDense: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  decoration: const InputDecoration(labelText: 'Phone *', border: OutlineInputBorder(), isDense: true),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), isDense: true),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, true),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'Date of Birth *', border: OutlineInputBorder(), isDense: true),
                                    child: Text(_dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'Select Date'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          const Text('Academic Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _schoolNameCtrl,
                                  decoration: const InputDecoration(labelText: 'School Name', border: OutlineInputBorder(), isDense: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _classCtrl,
                                  decoration: const InputDecoration(labelText: 'Class *', border: OutlineInputBorder(), isDense: true),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedTeacher,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Assign Tutor', border: OutlineInputBorder(), isDense: true),
                            hint: const Text('Select Tutor'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('None')),
                              ..._teachers.map((t) => DropdownMenuItem(value: t, child: Text(t['name'] ?? '', overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (val) => setState(() => _selectedTeacher = val),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedCustomFee,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Fee Structure', border: OutlineInputBorder(), isDense: true),
                            hint: const Text('Select Fee'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('None')),
                              ..._customFees.map((f) => DropdownMenuItem(value: f, child: Text('${f['title']} - ₹${f['amount']}', overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (val) => setState(() => _selectedCustomFee = val),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedUpi,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'UPI Account', border: OutlineInputBorder(), isDense: true),
                            hint: const Text('Select UPI'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('None')),
                              ..._upiIds.map((u) => DropdownMenuItem(
                                value: u, 
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(u['title'] ?? '', overflow: TextOverflow.ellipsis)),
                                    Tooltip(
                                      message: u['upiId'] ?? '',
                                      triggerMode: TooltipTriggerMode.tap,
                                      child: const Icon(Icons.remove_red_eye, size: 20, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                            onChanged: (val) => setState(() => _selectedUpi = val),
                          ),
                          
                          const SizedBox(height: 24),
                          const Text('Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _streetCtrl,
                            decoration: const InputDecoration(labelText: 'Street', border: OutlineInputBorder(), isDense: true),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cityCtrl,
                                  decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder(), isDense: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _stateCtrl,
                                  decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder(), isDense: true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _countryCtrl,
                            decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder(), isDense: true),
                          ),
                          
                          if (_templateFields.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text('Custom Fields (Template)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                            const SizedBox(height: 12),
                            ..._templateFields.map((field) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: TextFormField(
                                  controller: _customFieldControllers[field.title],
                                  decoration: InputDecoration(
                                    labelText: field.title,
                                    hintText: field.placeholder,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
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
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Submit Admission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
