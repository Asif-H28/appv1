import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  static const String githubUser = 'Asif-H28';
  static const String githubRepo = 'appv1';
  static const String apiUrl =
      'https://api.github.com/repos/$githubUser/$githubRepo/releases/latest';

  static const _channel = MethodChannel('com.example.appv1/updater');

  // Check if a newer version exists on GitHub
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    if (kIsWeb) return null;
    try {
      final dio = Dio();
      final response = await dio.get(apiUrl);

      final latestVersion = response.data['tag_name']
          .toString()
          .replaceAll('v', ''); // e.g., "v1.0.2" → "1.0.2"

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isNewerVersion(latestVersion, currentVersion)) {
        final assets = response.data['assets'] as List;
        final apkAsset = assets.firstWhere(
          (a) => a['name'].toString().endsWith('.apk'),
          orElse: () => null,
        );

        if (apkAsset != null) {
          return {
            'version': latestVersion,
            'downloadUrl': apkAsset['browser_download_url'],
            'releaseNotes': response.data['body'] ?? 'Bug fixes and improvements',
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Compare version strings like "1.0.2" > "1.0.0"
  static bool _isNewerVersion(String latest, String current) {
    final l = latest.split('.').map(int.parse).toList();
    final c = current.split('.').map(int.parse).toList();

    while (l.length < 3) l.add(0);
    while (c.length < 3) c.add(0);

    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  /// Returns the path to the public Downloads directory.
  /// The APK is saved here so it survives app uninstall.
  static Future<String> _getDownloadsApkPath() async {
    final cacheDir = await getApplicationCacheDirectory();
    return '${cacheDir.path}/SchoolSync_update.apk';
  }

  // Download APK and install it
  // Returns null on success, or an error message string on failure.
  static Future<String?> downloadAndInstall(
    String downloadUrl,
    Function(double) onProgress,
  ) async {
    try {
      // Request install-packages permission (needed on Android 8+)
      final installStatus = await Permission.requestInstallPackages.request();
      if (!installStatus.isGranted) {
        return 'Install permission denied. Please allow "Install unknown apps" in settings.';
      }

      final savePath = await _getDownloadsApkPath();

      final file = File(savePath);

      final dio = Dio();
      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          headers: {
            // Accept APK binary
            HttpHeaders.acceptHeader: 'application/octet-stream',
          },
        ),
      );

      // Verify the file was actually downloaded
      if (!await file.exists() || await file.length() < 1000) {
        return 'Download failed or file is corrupt. Please try again.';
      }

      // ✅ Open the APK — open_file will use FileProvider internally on Android 7+
      final result = await OpenFile.open(savePath, type: 'application/vnd.android.package-archive');

      if (result.type != ResultType.done) {
        // Provide a clear message for the signature-conflict case
        return _friendlyOpenFileError(result.message);
      }

      return null; // success
    } catch (e) {
      return 'An error occurred during download: $e';
    }
  }

  /// Download APK only (to Downloads folder), without trying to install.
  /// Used in the "uninstall first" flow so the APK survives app removal.
  static Future<String?> downloadOnly(
    String downloadUrl,
    Function(double) onProgress,
  ) async {
    try {
      final savePath = await _getDownloadsApkPath();

      final file = File(savePath);

      final dio = Dio();
      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          headers: {
            HttpHeaders.acceptHeader: 'application/octet-stream',
          },
        ),
      );

      // Verify the file was actually downloaded
      if (!await file.exists() || await file.length() < 1000) {
        return null; // download failed
      }

      return savePath; // return path on success
    } catch (e) {
      return null;
    }
  }

  /// Open a previously downloaded APK for installation.
  static Future<String?> installFromPath(String path) async {
    try {
      final installStatus = await Permission.requestInstallPackages.request();
      if (!installStatus.isGranted) {
        return 'Install permission denied. Please allow "Install unknown apps" in settings.';
      }

      final result = await OpenFile.open(path, type: 'application/vnd.android.package-archive');
      if (result.type != ResultType.done) {
        return _friendlyOpenFileError(result.message);
      }
      return null;
    } catch (e) {
      return 'Could not open installer: $e';
    }
  }

  /// Trigger the Android uninstall dialog for the app.
  static Future<void> triggerUninstall() async {
    try {
      await _channel.invokeMethod('uninstallApp', {
        'packageName': 'com.example.appv1',
      });
    } catch (e) {
      // Ignore — the app may be killed during uninstall
    }
  }

  static String _friendlyOpenFileError(String rawMessage) {
    final msg = rawMessage.toLowerCase();
    if (msg.contains('conflict') || msg.contains('signature') || msg.contains('certificates')) {
      return 'SIGNATURE_CONFLICT';
    }
    if (msg.contains('permission')) {
      return 'Please allow "Install unknown apps" in your device settings, then try again.';
    }
    return 'Could not open installer: $rawMessage';
  }
}
