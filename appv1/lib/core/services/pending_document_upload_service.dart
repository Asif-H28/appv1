import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PendingDocumentUploadService {
  static const String _keyActive = 'isPendingDocumentUpload';
  static const String _keyScreen = 'pendingTargetScreen';
  static const String _keyData = 'pendingExtraData';

  static Future<void> markPendingUpload({
    required String targetScreen,
    Map<String, dynamic>? extraData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyActive, true);
    await prefs.setString(_keyScreen, targetScreen);
    if (extraData != null) {
      await prefs.setString(_keyData, jsonEncode(extraData));
    }
  }

  static Future<bool> isPendingUpload() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyActive) ?? false;
  }

  static Future<Map<String, dynamic>?> getPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyActive) ?? false)) return null;
    final screen = prefs.getString(_keyScreen) ?? '';
    final extraRaw = prefs.getString(_keyData);
    Map<String, dynamic>? extra;
    if (extraRaw != null && extraRaw.isNotEmpty) {
      try {
        extra = jsonDecode(extraRaw);
      } catch (_) {}
    }
    return {
      'screen': screen,
      'extra': extra,
    };
  }

  static Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActive);
    await prefs.remove(_keyScreen);
    await prefs.remove(_keyData);
  }
}
