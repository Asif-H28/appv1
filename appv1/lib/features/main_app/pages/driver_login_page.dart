import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appv1/core/services/api_service.dart';

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

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                const Icon(Icons.directions_bus_rounded, color: Color(0xFF0D9488), size: 64),
                const SizedBox(height: 16),
                Text(
                  _vehicle?['vehicleName'] ?? 'Vehicle',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  _vehicle?['vehicleNumber'] ?? '',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF0D9488), fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                _buildInfoRow(Icons.person_rounded, 'Driver Name', _vehicle?['driverName'] ?? 'N/A'),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.phone_rounded, 'Phone', _vehicle?['driverPhoneNumber'] ?? 'N/A'),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.supervisor_account_rounded, 'Coordinator', _vehicle?['coordinatorName'] ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => setState(() => _vehicle = null),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0D9488)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('BACK TO LOGIN', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
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
