import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:appv1/features/tuition_session/services/tuition_session_service.dart';
import 'teacher_active_session_screen.dart';

class TeacherQrScannerScreen extends StatefulWidget {
  const TeacherQrScannerScreen({Key? key}) : super(key: key);

  @override
  State<TeacherQrScannerScreen> createState() => _TeacherQrScannerScreenState();
}

class _TeacherQrScannerScreenState extends State<TeacherQrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  Future<Position?> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return null;
    } 

    return await Geolocator.getCurrentPosition();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String qrToken = barcodes.first.rawValue!;
      setState(() => _isProcessing = true);
      _scannerController.stop();

      final pos = await _getLocation();
      if (pos == null) {
        setState(() => _isProcessing = false);
        _scannerController.start();
        return;
      }

      final res = await TuitionSessionService.checkIn(
        qrToken: qrToken,
        teacherLat: pos.latitude,
        teacherLng: pos.longitude,
      );

      if (res['success']) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TeacherActiveSessionScreen(session: res['session'])),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
          setState(() => _isProcessing = false);
          _scannerController.start();
        }
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF009688),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF009688)),
                    SizedBox(height: 16),
                    Text('Processing check-in...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF009688), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Align the QR code within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, backgroundColor: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
