import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildLockService {
  static const MethodChannel _kioskChannel = MethodChannel('com.example.appv1/kiosk');
  static const String _keyChildLockEnabled = 'child_lock_enabled';
  static const String _keyChildLockPin = 'child_lock_pin';

  // Private constructor
  ChildLockService._privateConstructor();
  static final ChildLockService instance = ChildLockService._privateConstructor();

  Future<bool> isChildLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyChildLockEnabled) ?? false;
  }

  Future<String?> getChildLockPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyChildLockPin);
  }

  Future<void> enableChildLock(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyChildLockEnabled, true);
    await prefs.setString(_keyChildLockPin, pin);
    try {
      await _kioskChannel.invokeMethod('startLockTask');
    } catch (e) {
      print('Failed to start LockTask: $e');
    }
  }

  Future<void> disableChildLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyChildLockEnabled, false);
    await prefs.remove(_keyChildLockPin);
    try {
      await _kioskChannel.invokeMethod('stopLockTask');
    } catch (e) {
      print('Failed to stop LockTask: $e');
    }
  }

  Future<bool> verifyPin(String pin) async {
    final savedPin = await getChildLockPin();
    return savedPin == pin;
  }
}
