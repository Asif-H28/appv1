import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// All-files access, needed to browse documents inside the app instead of
/// handing the user off to the system file manager.
///
/// On Android 11+ this is a "special app access" permission: it can only be
/// granted from the system Settings screen, there is no in-app dialog for it.
/// Leaving for Settings can cost us the Activity, so ask for it at a moment
/// where there is no unsaved work to lose — never mid-flow.
class StorageAccessService {
  static Future<bool> hasAccess() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;
    // Android 10 and below: legacy storage permission is enough.
    if (await Permission.storage.isGranted) return true;
    return false;
  }

  /// Sends the user to the system Settings toggle. Returns whether access was
  /// granted by the time they came back.
  static Future<bool> request() async {
    if (await Permission.storage.request().isGranted) return true;
    await Permission.manageExternalStorage.request();
    return hasAccess();
  }

  /// Prompt up-front, before the teacher has typed anything worth losing.
  ///
  /// Call this when a screen that will later need document attachment opens —
  /// so the one-time trip to Settings happens on an empty screen rather than
  /// on a half-filled end-session form.
  static Future<void> prepare(BuildContext context) async {
    if (await hasAccess()) return;
    if (!context.mounted) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.folder_shared_rounded, color: Colors.teal),
            SizedBox(width: 10),
            Expanded(child: Text('Allow file access')),
          ],
        ),
        content: const Text(
          'To attach homework PDFs without leaving the app, this app needs '
          'permission to read your files.\n\n'
          'Android only lets you turn this on from its Settings screen. '
          'Doing it now means you won\'t be interrupted later while ending a '
          'session.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    if (proceed == true) await request();
  }
}
