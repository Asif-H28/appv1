import 'package:flutter/material.dart';
import 'package:appv1/core/constants/app_colors.dart';
import 'child_lock_service.dart';

class ChildLockSettingsPage extends StatefulWidget {
  const ChildLockSettingsPage({super.key});

  @override
  State<ChildLockSettingsPage> createState() => _ChildLockSettingsPageState();
}

class _ChildLockSettingsPageState extends State<ChildLockSettingsPage> {
  bool _isChildLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await ChildLockService.instance.isChildLockEnabled();
    setState(() {
      _isChildLockEnabled = enabled;
    });
  }

  Future<void> _showPinDialog(bool isEnabling) async {
    final TextEditingController pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(isEnabling ? 'Set 4-Digit PIN' : 'Enter 4-Digit PIN'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                hintText: 'Enter PIN',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.length != 4) {
                  return 'PIN must be 4 digits';
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'PIN must contain only numbers';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabling ? Colors.teal : Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final enteredPin = pinController.text;
                  if (isEnabling) {
                    await ChildLockService.instance.enableChildLock(enteredPin);
                    Navigator.pop(context);
                    _loadState();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Child Lock enabled.')),
                      );
                    }
                  } else {
                    final isValid = await ChildLockService.instance.verifyPin(
                      enteredPin,
                    );
                    if (isValid) {
                      await ChildLockService.instance.disableChildLock();
                      Navigator.pop(context);
                      _loadState();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Child Lock disabled.')),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Incorrect PIN.')),
                        );
                      }
                    }
                  }
                }
              },
              child: Text(
                isEnabling ? 'Enable' : 'Disable',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Child Lock Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Child Lock',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Prevent exiting the app',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isChildLockEnabled,
                    activeColor: Colors.teal,
                    onChanged: (value) {
                      _showPinDialog(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'When Child Lock is enabled, you cannot exit the application or use other apps without the 4-digit PIN. To force exit, hold the Back and Recent buttons on your Android device (requires device passcode).',
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
