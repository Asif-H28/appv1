import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/network/dio_http_adapter.dart' as http;
import '../../../../core/widgets/in_app_camera_sheet.dart';

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
  void initState() {
    super.initState();
    _checkLostData();
  }

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



  Future<void> _checkLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        _uploadXFile(response.file!);
      } else if (response.exception != null) {
        _showSnackBar('Error retrieving photo: ${response.exception}', isError: true);
      }
    } catch (e) {
      debugPrint('Error retrieving lost data: $e');
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await InAppCameraSheet.show(context);
      if (image == null) return;
      await _uploadXFile(image);
    } catch (e) {
      _showSnackBar('Error capturing photo: $e', isError: true);
    }
  }

  Future<void> _uploadXFile(XFile image) async {
    setState(() => _isUploadingImage = true);

    try {
      final url = '${ApiConstants.apiBaseUrl}/upload/image';
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: image.name,
      ));
      
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

  /// Explains why location is needed and offers the fix, rather than dropping
  /// a snackbar the teacher has to decode. Returns whether they chose to act.
  Future<bool> _promptForLocation({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final act = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.teal),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message, style: const TextStyle(height: 1.4)),
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
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return act == true;
  }

  Future<Position?> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      final open = await _promptForLocation(
        title: 'Turn on Location',
        message:
            'Location is off on your device. A tutor session records where it '
            'was started, so please switch on Location and come back.',
        actionLabel: 'Open Settings',
      );
      if (!open) return null;

      await Geolocator.openLocationSettings();
      // Re-check rather than trusting the trip: the teacher may have come back
      // without flipping the switch.
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showSnackBar('Location is still off — session not started.',
            isError: true);
        return null;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      // The OS won't show its prompt again — app settings is the only way back.
      final open = await _promptForLocation(
        title: 'Location Permission Needed',
        message:
            'Location access is blocked for this app, so a session can\'t be '
            'started. You can turn it back on in app settings.',
        actionLabel: 'Open App Settings',
      );
      if (open) await Geolocator.openAppSettings();
      return null;
    }

    if (permission == LocationPermission.denied) {
      _showSnackBar('Location permission is needed to start a session.',
          isError: true);
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

      final responseBody = jsonDecode(response.body);
      final bool isSuccess = (response.statusCode == 200 || response.statusCode == 201) && 
                             (responseBody['success'] == true || responseBody['success'] == null);

      if (isSuccess) {
        _showSnackBar('Session started successfully!');
        if (mounted) Navigator.pop(context, true);
      } else {
        final errorMsg = responseBody['message'] ?? responseBody['error'] ?? 'Failed to start session';
        _showErrorDialog(errorMsg);
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
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

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Check-in Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
