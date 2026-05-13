import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appv1/core/services/api_service.dart';

class SetupVehiclePinPage extends StatefulWidget {
  final String orgId;

  const SetupVehiclePinPage({super.key, required this.orgId});

  @override
  State<SetupVehiclePinPage> createState() => _SetupVehiclePinPageState();
}

class _SetupVehiclePinPageState extends State<SetupVehiclePinPage> {
  final List<TextEditingController> _pinControllers = List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> _confirmControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());
  final List<FocusNode> _confirmFocusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;

  @override
  void dispose() {
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var c in _confirmControllers) {
      c.dispose();
    }
    for (var f in _pinFocusNodes) {
      f.dispose();
    }
    for (var f in _confirmFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _pin => _pinControllers.map((c) => c.text).join();
  String get _confirmPin => _confirmControllers.map((c) => c.text).join();

  Future<void> _setupPin() async {
    if (_pin.length < 4 || _confirmPin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a 4-digit PIN')));
      return;
    }

    if (_pin != _confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
      return;
    }

    setState(() => _isLoading = true);

    final res = await ApiService.setupVehiclePin(
      orgId: widget.orgId,
      pin: _pin,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']), backgroundColor: Colors.teal, behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Widget _buildPinInput(List<TextEditingController> controllers, List<FocusNode> focusNodes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return SizedBox(
          width: 60,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 1,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
            decoration: InputDecoration(
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.teal, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty && index < 3) {
                focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                focusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Setup Transport PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.teal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set New PIN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 16),
            _buildPinInput(_pinControllers, _pinFocusNodes),
            const SizedBox(height: 32),
            const Text(
              'Confirm New PIN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 16),
            _buildPinInput(_confirmControllers, _confirmFocusNodes),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _setupPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'CREATE PIN',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.security_rounded, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This PIN will be required to authorize transport actions and vehicle assignments.',
                      style: TextStyle(color: Color(0xFF4A5568), fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
