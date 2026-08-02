import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../widgets/in_app_media_picker_sheet.dart';

/// Opens the system file manager, in a way that survives Android destroying
/// our Activity while the file manager is in front.
///
/// The native side writes the chosen files into our cache the moment the
/// result arrives and records the outcome on disk. Nothing is held in memory
/// on either side of the channel, so a pick cannot be dropped by a teardown —
/// which is exactly what file_picker gets wrong (flutter_file_picker#1258:
/// it parks the Dart callback in a field that dies with the Activity).
class DocumentPickerService {
  static const MethodChannel _channel =
      MethodChannel('com.example.appv1/documents');

  static const String _statusWaiting = 'waiting';
  static const String _statusPicked = 'picked';

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Whether this platform uses the durable native picker. Callers on web or
  /// iOS should keep their existing file_picker path.
  static bool get isSupported => _supported;

  /// How long to keep waiting on a pick before giving up. Generous on purpose:
  /// the user may browse for a while, and the only cost of waiting is an
  /// occasional cheap status read.
  static const Duration _pollInterval = Duration(milliseconds: 300);
  static const int _maxPolls = 2000; // ~10 minutes

  /// Common MIME sets, so callers don't hand-roll them.
  static const List<String> pdfOnly = ['application/pdf'];
  static const List<String> imagesAndPdf = [
    'application/pdf',
    'image/jpeg',
    'image/png',
  ];
  static const List<String> spreadsheets = [
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ];

  /// Launches the file manager and waits for the outcome.
  ///
  /// Returns an empty list if the user cancelled — or if our Activity was
  /// destroyed and took this isolate with it, in which case the pick stays
  /// parked natively and [consumePending] collects it once the screen is back.
  ///
  /// Polls the native status rather than watching app lifecycle: the outcome
  /// lives on disk, so reading it is correct whether or not we were ever
  /// backgrounded, and there is no lifecycle edge case to get wrong.
  static Future<List<PickedMediaFile>> pick({
    List<String> mimeTypes = pdfOnly,
    bool multiple = false,
  }) async {
    if (!_supported) return const [];

    await _channel.invokeMethod('pickDocument', {
      'mimeTypes': mimeTypes,
      'multiple': multiple,
    });

    for (var attempt = 0; attempt < _maxPolls; attempt++) {
      await Future<void>.delayed(_pollInterval);
      final outcome = await _read();
      if (outcome?['status'] != _statusWaiting) return _toPickedFiles(outcome);
    }
    return const [];
  }

  /// Single-file convenience wrapper.
  static Future<PickedMediaFile?> pickPdf() async {
    final files = await pick(mimeTypes: pdfOnly);
    return files.isEmpty ? null : files.first;
  }

  /// Collects a pick that completed while this isolate was gone.
  ///
  /// Call when a screen that was waiting on a document reappears after a
  /// restart. Returns each pick exactly once — the native side clears it.
  static Future<List<PickedMediaFile>> consumePending() async {
    if (!_supported) return const [];
    final outcome = await _read();
    if (outcome?['status'] != _statusPicked) return const [];
    return _toPickedFiles(outcome);
  }

  /// Single-file variant of [consumePending].
  static Future<PickedMediaFile?> consumePendingSingle() async {
    final files = await consumePending();
    return files.isEmpty ? null : files.first;
  }

  static Future<Map<String, dynamic>?> _read() async {
    try {
      return await _channel
          .invokeMapMethod<String, dynamic>('consumePendingDocument');
    } catch (_) {
      return null;
    }
  }

  static Future<List<PickedMediaFile>> _toPickedFiles(
      Map<String, dynamic>? map) async {
    if (map?['status'] != _statusPicked) return const [];

    final raw = (map?['files'] as List?) ?? const [];
    final result = <PickedMediaFile>[];

    for (final entry in raw) {
      final item = (entry as Map).cast<dynamic, dynamic>();
      final path = item['path'] as String?;
      final name = item['name'] as String?;
      if (path == null || name == null) continue;

      final file = File(path);
      if (!await file.exists()) continue;

      result.add(PickedMediaFile(
        path: path,
        name: name,
        bytes: await file.readAsBytes(),
        isPdf: name.toLowerCase().endsWith('.pdf'),
      ));
    }
    return result;
  }
}
