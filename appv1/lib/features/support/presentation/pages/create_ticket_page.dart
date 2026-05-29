import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({Key? key}) : super(key: key);

  @override
  _CreateTicketPageState createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();

  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e', isError: true);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final formData = FormData.fromMap({
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'description': _descController.text.trim(),
      });

      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(
            file.path,
            filename: 'image_$i.png',
          ),
        ));
      }

      final response = await ApiService.dio.post(
        '/support/issue',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Support ticket submitted successfully!');
        if (mounted) {
          Navigator.pop(context, true); // Return true to signal success
        }
      } else {
        final msg = response.data['message'] ?? 'Failed to submit ticket';
        _showSnackBar(msg, isError: true);
      }
    } on DioError catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      _showSnackBar('Error: $msg', isError: true);
    } catch (e) {
      _showSnackBar('Unexpected error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Create Ticket',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.teal),
                  SizedBox(height: 16),
                  Text(
                    'Submitting your ticket...',
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 60),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.teal[600]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Please describe your issue below. You can also attach screenshots to help us understand better.',
                              style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _descController,
                      label: 'Issue Description',
                      icon: Icons.description_outlined,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please describe the issue';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    const Row(
                      children: [
                        Icon(Icons.attach_file, size: 20, color: Colors.black54),
                        SizedBox(width: 8),
                        Text(
                          'Attachments (Optional)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_selectedImages.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _selectedImages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length) {
                            return _buildAddImageButton();
                          }
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImages[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    else
                      _buildAddImageButton(),

                    const SizedBox(height: 40),
                    
                    ElevatedButton(
                      onPressed: _submitTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Ticket',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        alignLabelWithHint: maxLines > 1,
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey[500], size: 22) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.withOpacity(0.5), width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: Colors.teal[400], size: 32),
            const SizedBox(height: 8),
            Text(
              'Add Image',
              style: TextStyle(color: Colors.teal[600], fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
