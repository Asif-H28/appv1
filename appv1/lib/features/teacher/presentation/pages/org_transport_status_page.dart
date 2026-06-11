import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrgTransportStatusPage extends StatefulWidget {
  final String orgId;
  const OrgTransportStatusPage({super.key, required this.orgId});

  @override
  State<OrgTransportStatusPage> createState() => _OrgTransportStatusPageState();
}

class _OrgTransportStatusPageState extends State<OrgTransportStatusPage> {
  bool _isLoading = true;
  List<dynamic> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getOrgVehicles(widget.orgId);
    if (mounted) {
      setState(() {
        _vehicles = res['vehicles'] ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Live Transport Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0D9488),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchVehicles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : _vehicles.isEmpty
              ? _buildEmptyState()
              : _buildVehicleList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No vehicles found in this organization', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildVehicleList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final v = _vehicles[index];
        final bool isActive = v['isActive'] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isActive ? const Color(0xFF0D9488) : Colors.grey[400])!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_bus_rounded,
                color: isActive ? const Color(0xFF0D9488) : Colors.grey[500],
                size: 24,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    v['vehicleName'] ?? 'Vehicle',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.green : Colors.grey[200])!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: (isActive ? Colors.green : Colors.grey[300])!.withOpacity(0.3)),
                  ),
                  child: Text(
                    isActive ? 'LIVE' : 'OFFLINE',
                    style: TextStyle(
                      color: isActive ? Colors.green[700] : Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  v['vehicleNumber'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Driver: ${v['driverName'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VehicleMapView(vehicleId: v['vehicleId'].toString()),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class VehicleMapView extends StatefulWidget {
  final String vehicleId;
  const VehicleMapView({super.key, required this.vehicleId});

  @override
  State<VehicleMapView> createState() => _VehicleMapViewState();
}

class _VehicleMapViewState extends State<VehicleMapView> {
  bool _isLoading = true;
  bool _isMapLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _vehicle;
  late final WebViewController _webViewController;
  Timer? _timer;
  
  bool _isRefreshDisabled = false;
  int _cooldownRemaining = 0;
  Timer? _refreshTimer;
  static const int _cooldownSeconds = 150; // 2 minutes 30 seconds
  static const String _prefsKeyPrefix = 'map_refresh_cooldown_';

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'MapLoaded',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'loaded' && mounted) {
            setState(() => _isMapLoading = false);
          }
        },
      );
      
    _checkRefreshCooldown();
    _fetchLocation();
    // Refresh every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchLocation();
    });
  }

  Future<void> _checkRefreshCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRefreshStr = prefs.getString('$_prefsKeyPrefix${widget.vehicleId}');
    if (lastRefreshStr != null) {
      final lastRefresh = DateTime.parse(lastRefreshStr);
      final difference = DateTime.now().difference(lastRefresh).inSeconds;
      if (difference < _cooldownSeconds) {
        final remaining = _cooldownSeconds - difference;
        _startRefreshTimer(remaining);
      }
    }
  }

  void _startRefreshTimer(int seconds) {
    _refreshTimer?.cancel();
    setState(() {
      _isRefreshDisabled = true;
      _cooldownRemaining = seconds;
    });
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownRemaining > 0) {
          _cooldownRemaining--;
        } else {
          _isRefreshDisabled = false;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshDisabled) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsKeyPrefix${widget.vehicleId}', DateTime.now().toIso8601String());
    
    _startRefreshTimer(_cooldownSeconds);
    _fetchLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final res = await ApiService.getVehicleLocation(widget.vehicleId);
    if (mounted) {
      if (res['success'] == true) {
        final bool isFirstLoad = _isLoading;
        setState(() {
          _vehicle = res['vehicle'];
          _isLoading = false;
          _errorMessage = null;
        });

        if (_vehicle != null && _vehicle!['latitude'] != null) {
          final lat = double.tryParse(_vehicle!['latitude'].toString()) ?? 0.0;
          final lng = double.tryParse(_vehicle!['longitude'].toString()) ?? 0.0;

          final url = 'https://maps.google.com/maps?q=$lat,$lng&z=16&output=embed';
          final htmlString = '''
            <!DOCTYPE html>
            <html>
              <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <style>
                  body, html { margin: 0; padding: 0; height: 100%; width: 100%; }
                  iframe { border: 0; width: 100%; height: 100%; }
                </style>
              </head>
              <body>
                <iframe src="$url" onload="window.MapLoaded.postMessage('loaded')" allowfullscreen></iframe>
              </body>
            </html>
          ''';
          setState(() => _isMapLoading = true);
          _webViewController.loadHtmlString(htmlString);
        }
      } else {
        setState(() {
          _isLoading = false;
          if (res['message'] == 'Vehicle location not found') {
            _errorMessage = 'Driver has not started the trip yet.';
          } else {
            _errorMessage = res['message'] ?? 'Failed to get location';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = double.tryParse(_vehicle?['latitude']?.toString() ?? '12.9716') ?? 12.9716;
    final lng = double.tryParse(_vehicle?['longitude']?.toString() ?? '77.5946') ?? 77.5946;
    final bool isActive = _vehicle?['isActive'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_vehicle?['vehicleName'] ?? 'Vehicle Map', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(isActive ? 'Currently Live' : 'Last Known Location', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF0D9488),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isRefreshDisabled)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  '${(_cooldownRemaining ~/ 60).toString().padLeft(2, '0')}:${(_cooldownRemaining % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded, 
              color: _isRefreshDisabled ? Colors.white38 : Colors.white
            ),
            onPressed: _isRefreshDisabled ? null : _handleRefresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_rounded, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    WebViewWidget(controller: _webViewController),
                    if (_isMapLoading)
                      const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
                  ],
                ),
    );
  }
}
