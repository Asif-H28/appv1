import 'package:flutter/material.dart';
import '../../admission/models/admission_model.dart';
import '../../admission/services/admission_service.dart';

class AdminAdmissionTemplatePage extends StatefulWidget {
  const AdminAdmissionTemplatePage({Key? key}) : super(key: key);

  @override
  State<AdminAdmissionTemplatePage> createState() =>
      _AdminAdmissionTemplatePageState();
}

class _AdminAdmissionTemplatePageState
    extends State<AdminAdmissionTemplatePage> {
  final AdmissionService _admissionService = AdmissionService();
  bool _isLoading = true;
  bool _isSaving = false;
  List<AdmissionFormTemplateField> _templateFields = [];

  @override
  void initState() {
    super.initState();
    _fetchTemplate();
  }

  Future<void> _fetchTemplate() async {
    setState(() => _isLoading = true);
    try {
      final fields = await _admissionService.getTemplate();
      setState(() {
        _templateFields = fields;
      });
    } catch (e) {
      debugPrint('Error fetching template: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load template')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addField() {
    setState(() {
      _templateFields.add(
        AdmissionFormTemplateField(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '',
          placeholder: '',
        ),
      );
    });
  }

  void _removeField(int index) {
    setState(() {
      _templateFields.removeAt(index);
    });
  }

  void _updateField(int index, String title, String placeholder) {
    setState(() {
      _templateFields[index] = AdmissionFormTemplateField(
        id: _templateFields[index].id,
        title: title,
        placeholder: placeholder,
      );
    });
  }

  Future<void> _saveTemplate() async {
    // Validate empty titles
    if (_templateFields.any((f) => f.title.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a title for all custom fields'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = await _admissionService.updateTemplate(_templateFields);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template saved successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate change
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save template')),
        );
      }
    } catch (e) {
      debugPrint('Error saving template: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error occurred while saving')),
        );
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
        title: const Text(
          'Edit Admission Template',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _templateFields.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _templateFields.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: _addField,
                              icon: const Icon(Icons.add, color: Colors.teal),
                              label: const Text(
                                'Add Custom Field',
                                style: TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final field = _templateFields[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Field ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeField(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: field.title,
                                decoration: const InputDecoration(
                                  labelText: 'Field Title',
                                  hintText: 'e.g. Blood Group',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) =>
                                    _updateField(index, val, field.placeholder),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: field.placeholder,
                                decoration: const InputDecoration(
                                  labelText: 'Placeholder Text',
                                  hintText: 'e.g. O+',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) =>
                                    _updateField(index, field.title, val),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveTemplate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Template',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
