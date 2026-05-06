import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  // 👇 Replace with your GitHub username and repo name
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
      final currentVersion = packageInfo.version; // e.g., "1.0.0"

      if (_isNewerVersion(latestVersion, currentVersion)) {
        // Find the APK download URL from release assets
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
      return null; // No update available
    } catch (e) {
      return null;
    }
  }

  // Compare version strings like "1.0.2" > "1.0.0"
  static bool _isNewerVersion(String latest, String current) {
    final l = latest.split('.').map(int.parse).toList();
    final c = current.split('.').map(int.parse).toList();
    
    // Ensure both lists have at least 3 elements
    while (l.length < 3) {
      l.add(0);
    }
    while (c.length < 3) {
      c.add(0);
    }


    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  // Download APK and install it
  static Future<void> downloadAndInstall(
    String downloadUrl,
    Function(double) onProgress,
  ) async {
    // Request install permission
    final status = await Permission.requestInstallPackages.request();
    if (!status.isGranted) return;

    final dir = await getExternalStorageDirectory();
    if (dir == null) return;
    
    final savePath = '${dir.path}/school_app_update.apk';

    // Delete existing file if any
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
          onProgress(received / total); // 0.0 to 1.0
        }
      },
    );

    // Open APK installer
    await OpenFile.open(savePath);
  }
}
