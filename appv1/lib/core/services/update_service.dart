import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  static const String githubUser = 'Asif-H28';
  static const String githubRepo = 'appv1';
  static const String apiUrl =
      'https://api.github.com/repos/$githubUser/$githubRepo/releases/latest';

  // Check if a newer version exists on GitHub
  static Future<Map<String, dynamic>?> checkForUpdate() async {
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

      // ✅ Use app-private cache directory — no storage permission needed,
      //    works on all Android versions, and FileProvider can share it.
      final cacheDir = await getApplicationCacheDirectory();
      final savePath = '${cacheDir.path}/schoolsync_update.apk';

      // Delete any leftover APK from a previous attempt
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

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
