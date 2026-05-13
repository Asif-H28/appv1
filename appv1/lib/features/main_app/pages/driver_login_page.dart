import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DriverLoginPage extends StatefulWidget {
  const DriverLoginPage({super.key});

  @override
  State<DriverLoginPage> createState() => _DriverLoginPageState();
}

class _DriverLoginPageState extends State<DriverLoginPage> {
  final _phoneCtrl = TextEditingController();
  final List<TextEditingController> _pinControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  Map<String, dynamic>? _vehicle;

  // ── Tracking State ────────────────────────────────
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  LatLng _currentLocation = const LatLng(12.9716, 77.5946);
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var f in _pinFocusNodes) {
      f.dispose();
    }
    _stopTracking();
    super.dispose();
  }

  Future<void> _startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      return;
    }

    setState(() => _isTracking = true);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5),
    ).listen((Position position) {
      if (!mounted) return;
      final newLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = newLatLng;
      });
      _mapController.move(newLatLng, 17.0);
      _updateLocationOnServer(position);
    });
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    if (mounted) {
      setState(() => _isTracking = false);
    }
    if (_vehicle != null) {
      ApiService.stopVehicleRoute(_vehicle!['vehicleId'].toString());
    }
  }

  Future<void> _updateLocationOnServer(Position pos) async {
    if (_vehicle == null) return;
    await ApiService.updateVehicleLocation(
      vehicleId: _vehicle!['vehicleId'].toString(),
      orgId: _vehicle!['orgId'].toString(),
      latitude: pos.latitude,
      longitude: pos.longitude,
      vehicleName: _vehicle!['vehicleName'].toString(),
      driverName: _vehicle!['driverName'].toString(),
    );
  }

  String get _pin => _pinControllers.map((c) => c.text).join();

  Future<void> _login() async {
    if (_phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter phone number')));
      return;
    }
    if (_pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter 4-digit PIN')));
      return;
    }

    setState(() => _isLoading = true);

    final res = await ApiService.driverLogin(
      phoneNumber: _phoneCtrl.text,
      pin: _pin,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success']) {
      setState(() {
        _vehicle = res['vehicle'];
      });
      _initializeRealLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _initializeRealLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          forceAndroidLocationManager: true,
        );
        if (!mounted) return;
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLocation, 17.0);
        _updateLocationOnServer(position);
      }
    } catch (e) {
      debugPrint('Error getting initial location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Driver Access', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0D9488),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _vehicle != null ? _buildVehicleView() : _buildLoginView(),
    );
  }

  Widget _buildLoginView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFCCFBF1),
              child: Icon(Icons.directions_bus_rounded, color: Color(0xFF0D9488), size: 40),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Driver Phone Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'e.g. 9848012345',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2)),
              prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Security PIN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return SizedBox(
                width: 60,
                child: TextField(
                  controller: _pinControllers[index],
                  focusNode: _pinFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 1,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2)),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 3) {
                      _pinFocusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _pinFocusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('VIEW VEHICLE STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleView() {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation,
                  initialZoom: 17.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.appv1',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation,
                        width: 50,
                        height: 50,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Icon(
                              Icons.directions_bus_rounded,
                              color: Color(0xFF0D9488),
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: () {
                    _mapController.move(_currentLocation, 17.0);
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location_rounded, color: Color(0xFF0D9488)),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _isTracking ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isTracking ? 'ROUTE ACTIVE' : 'ROUTE INACTIVE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isTracking ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 6,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _vehicle?['vehicleName'] ?? 'Vehicle',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            _vehicle?['vehicleNumber'] ?? '',
                            style: const TextStyle(fontSize: 16, color: Color(0xFF0D9488), fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          _stopTracking();
                          setState(() => _vehicle = null);
                        },
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                  _buildInfoRow(Icons.person_rounded, 'Driver Name', _vehicle?['driverName'] ?? 'N/A'),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.phone_rounded, 'Phone', _vehicle?['driverPhoneNumber'] ?? 'N/A'),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.supervisor_account_rounded, 'Coordinator', _vehicle?['coordinatorName'] ?? 'N/A'),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isTracking ? _stopTracking : _startTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracking ? Colors.redAccent : const Color(0xFF0D9488),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            _isTracking ? 'STOP ROUTE' : 'START ROUTE',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF64748B), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
