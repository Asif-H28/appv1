import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../widgets/in_app_media_picker_sheet.dart';

/// Opens the system file manager for a PDF, in a way that survives Android
/// destroying our Activity while the file manager is in front.
///
/// The native side writes the chosen file into our cache the moment the result
/// arrives and records the outcome on disk. Nothing is held in memory on
/// either side of the channel, so a pick cannot be dropped by a teardown —
/// which is exactly what file_picker gets wrong (flutter_file_picker#1258:
/// it parks the Dart callback in a field that dies with the Activity).
class DocumentPickerService {
  static const MethodChannel _channel =
      MethodChannel('com.example.appv1/documents');

  static const String _statusWaiting = 'waiting';
  static const String _statusPicked = 'picked';

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  /// How long to keep waiting on a pick before giving up. Generous on purpose:
  /// the teacher may browse for a while, and the only cost of waiting is an
  /// occasional cheap status read.
  static const Duration _pollInterval = Duration(milliseconds: 300);
  static const int _maxPolls = 2000; // ~10 minutes

  /// Launches the file manager and waits for the outcome.
  ///
  /// Returns null if the user cancelled — or if our Activity was destroyed and
  /// took this isolate with it, in which case the pick stays parked natively
  /// and [consumePending] collects it once the screen is back.
  ///
  /// Polls the native status rather than watching app lifecycle: the outcome
  /// lives on disk, so reading it is correct whether or not we were ever
  /// backgrounded, and there is no lifecycle edge case to get wrong.
  static Future<PickedMediaFile?> pickPdf() async {
    if (!_supported) return null;

    await _channel.invokeMethod('pickDocument');

    for (var attempt = 0; attempt < _maxPolls; attempt++) {
      await Future<void>.delayed(_pollInterval);
      final outcome = await _read();
      if (outcome?['status'] != _statusWaiting) return _toPickedFile(outcome);
    }
    return null;
  }

  /// Collects a pick that completed while this isolate was gone.
  ///
  /// Call when a screen that was waiting on a document reappears after a
  /// restart. Returns each pick exactly once — the native side clears it.
  static Future<PickedMediaFile?> consumePending() async {
    if (!_supported) return null;
    final outcome = await _read();
    if (outcome?['status'] != _statusPicked) return null;
    return _toPickedFile(outcome);
  }

  static Future<Map<String, dynamic>?> _read() async {
    try {
      return await _channel
          .invokeMapMethod<String, dynamic>('consumePendingDocument');
    } catch (_) {
      return null;
    }
  }

  static Future<PickedMediaFile?> _toPickedFile(Map<String, dynamic>? map) async {
    if (map?['status'] != _statusPicked) return null;
    final path = map?['path'] as String?;
    final name = map?['name'] as String?;
    if (path == null || name == null) return null;

    final file = File(path);
    if (!await file.exists()) return null;

    return PickedMediaFile(
      path: path,
      name: name,
      bytes: await file.readAsBytes(),
      isPdf: true,
    );
  }
}
