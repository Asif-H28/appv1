import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/network/dio_http_adapter.dart' as http;

class StartTutorSessionPage extends StatefulWidget {
  const StartTutorSessionPage({Key? key}) : super(key: key);

  @override
  _StartTutorSessionPageState createState() => _StartTutorSessionPageState();
}

class _StartTutorSessionPageState extends State<StartTutorSessionPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedDuration = '2 hours';
  
  final List<TextEditingController> _studentIdControllers = [TextEditingController()];
  
  // To hold image paths/urls
  final ImagePicker _picker = ImagePicker();
  final List<String> _uploadedImageUrls = [];
  bool _isUploadingImage = false;

  final List<String> _durations = [
    '0.5 hours',
    '1 hour',
    '1.5 hours',
    '2 hours',
    '2.5 hours',
    '3 hours',
    '3.5 hours',
    '4 hours',
    '4.5 hours',
    '5 hours',
    '5.5 hours',
    '6 hours'
  ];

  @override
  void dispose() {
    for (var controller in _studentIdControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addStudentField() {
    setState(() {
      _studentIdControllers.add(TextEditingController());
    });
  }

  void _removeStudentField(int index) {
    setState(() {
      _studentIdControllers[index].dispose();
      _studentIdControllers.removeAt(index);
    });
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (image == null) return;
      
      setState(() => _isUploadingImage = true);

      final url = '${ApiConstants.apiBaseUrl}/upload/image';
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      
      final headers = await ApiService.getHeaders();
      request.headers.addAll(headers);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        setState(() {
          _uploadedImageUrls.add(body['file']['url'].toString());
        });
      } else {
        _showSnackBar('Failed to upload image: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error taking picture: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImageUrls.removeAt(index);
    });
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return null;
      bool? shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Location Disabled'),
          content: const Text('Location services are disabled. Please enable them to start a session.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enable Location'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }

      if (!serviceEnabled) {
        _showSnackBar('Location services are still disabled. Cannot start session.', isError: true);
        return null;
      }
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permissions are denied', isError: true);
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Location permissions are permanently denied, we cannot request permissions.', isError: true);
      return null;
    } 

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _startSession() async {
    if (!_formKey.currentState!.validate()) return;
    
    List<String> studentIds = _studentIdControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (studentIds.isEmpty) {
      _showSnackBar('Please add at least one student ID', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final position = await _determinePosition();
      if (position == null) {
        setState(() => _isLoading = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final orgId = prefs.getString('orgId') ?? '';
      final teacherId = prefs.getString('teacherId') ?? prefs.getString('userId') ?? '';
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final payload = {
        "orgId": orgId,
        "teacherId": teacherId,
        "studentPhotos": _uploadedImageUrls,
        "duration": _selectedDuration,
        "studentIds": studentIds,
        "lat": position.latitude,
        "lng": position.longitude,
        "date": todayStr,
        "sessionStartedTime": DateTime.now().toUtc().toIso8601String()
      };

      final response = await ApiService.post(
        '/tutor-sessions/start',
        headers: {'x-org-id': orgId},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Session started successfully!');
        if (mounted) Navigator.pop(context, true);
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Failed to start session';
        _showSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Start Session'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.teal),
                  SizedBox(height: 16),
                  Text('Getting location and starting session...', style: TextStyle(color: Colors.black54)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Field
                    const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: todayStr,
                      readOnly: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today_rounded, color: Colors.teal),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Duration Dropdown
                    const Text('Session Duration', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDuration,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.schedule_rounded, color: Colors.teal),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                      ),
                      items: _durations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDuration = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Student Photos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Student Photos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        TextButton.icon(
                          onPressed: _isUploadingImage ? null : _takePicture,
                          icon: _isUploadingImage 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : const Icon(Icons.camera_alt_rounded),
                          label: const Text('Capture'),
                          style: TextButton.styleFrom(foregroundColor: Colors.teal),
                        ),
                      ],
                    ),
                    if (_uploadedImageUrls.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _uploadedImageUrls.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: NetworkImage(_uploadedImageUrls[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    onPressed: () => _removeImage(index),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Student IDs List
                    const Text('Student IDs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    ...List.generate(_studentIdControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _studentIdControllers[index],
                                decoration: InputDecoration(
                                  hintText: 'Enter student ID',
                                  prefixIcon: const Icon(Icons.person_outline, color: Colors.teal),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                                ),
                                validator: (val) {
                                  if (index == 0 && (val == null || val.trim().isEmpty)) {
                                    return 'At least one student ID is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            if (_studentIdControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removeStudentField(index),
                              ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: _addStudentField,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add another student'),
                      style: TextButton.styleFrom(foregroundColor: Colors.teal),
                    ),
                    
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          elevation: 2,
                        ),
                        child: const Text('Start Activity'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
