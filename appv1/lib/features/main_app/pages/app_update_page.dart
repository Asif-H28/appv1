import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/utils/pwa_update_helper.dart';

class AppUpdatePage extends StatefulWidget {
  const AppUpdatePage({Key? key}) : super(key: key);

  @override
  State<AppUpdatePage> createState() => _AppUpdatePageState();
}

class _AppUpdatePageState extends State<AppUpdatePage> {
  String _currentVersion = '...';
  String _latestVersion = '';
  String _releaseNotes = '';
  String _downloadUrl = '';
  bool _isLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initAndCheck();
  }

  Future<void> _initAndCheck() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
    } catch (_) {
      _currentVersion = '1.0.0';
    }

    try {
      final update = await UpdateService.checkForUpdate();
      if (update != null) {
        setState(() {
          _latestVersion = update['version'];
          _releaseNotes = update['releaseNotes'];
          _downloadUrl = update['downloadUrl'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _latestVersion = _currentVersion;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to check for updates: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdate() async {
    if (kIsWeb) {
      // PWA Update flow
      triggerPwaUpdate();
      return;
    }

    if (Platform.isAndroid) {
      if (_downloadUrl.isEmpty) return;
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
        _errorMessage = null;
      });

      final error = await UpdateService.downloadAndInstall(
        _downloadUrl,
        (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        if (error != null) {
          if (error == 'SIGNATURE_CONFLICT') {
            _showSignatureConflictDialog();
          } else {
            setState(() {
              _errorMessage = error;
            });
          }
        }
      }
    } else if (Platform.isIOS) {
      // iOS doesn't support direct downloads; redirect to releases page
      final url = Uri.parse('https://github.com/${UpdateService.githubUser}/${UpdateService.githubRepo}/releases/latest');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _errorMessage = 'Could not launch store/releases page.';
        });
      }
    }
  }

  void _showSignatureConflictDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Update Conflict', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'A signature conflict was detected. This happens when the installed app and the update have different certificate signatures.\n\n'
          'To update, you must:\n'
          '1. Uninstall your current app\n'
          '2. Download and install the new version\n\n'
          'Would you like to download the APK and uninstall the current app automatically?',
          style: TextStyle(height: 1.4, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleConflictFlow();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Download & Uninstall'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConflictFlow() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final savedPath = await UpdateService.downloadOnly(
      _downloadUrl,
      (progress) {
        setState(() {
          _downloadProgress = progress;
        });
      },
    );

    if (savedPath == null) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Download failed. Please check internet connection.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });
    }

    // Trigger uninstall flow
    await UpdateService.triggerUninstall();
  }

  @override
  Widget build(BuildContext context) {
    final hasUpdate = _latestVersion.isNotEmpty && _latestVersion != _currentVersion;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade700, Colors.teal.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'App Update',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // balance back button
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Icon
                          _buildStatusIcon(hasUpdate),
                          const SizedBox(height: 40),
                          
                          // Main Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withOpacity(0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  hasUpdate ? 'Update Available' : 'Up to Date',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  hasUpdate
                                      ? 'A newer version of SchoolSync is ready to be installed.'
                                      : 'You already have the latest features and security updates.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.teal.shade700.withOpacity(0.8),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildVersionDetailsCard(),
                                if (hasUpdate && _releaseNotes.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  _buildReleaseNotesCard(),
                                ],
                                const SizedBox(height: 32),
                                if (_isDownloading)
                                  _buildDownloadProgressIndicator()
                                else if (_isLoading)
                                  const CircularProgressIndicator(color: Colors.teal)
                                else ...[
                                  if (hasUpdate)
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _handleUpdate,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal.shade600,
                                          foregroundColor: Colors.white,
                                          elevation: 4,
                                          shadowColor: Colors.teal.withOpacity(0.4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          kIsWeb ? 'Update & Refresh' : 'Update Now',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: OutlinedButton(
                                        onPressed: _initAndCheck,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.teal.shade700,
                                          side: BorderSide(color: Colors.teal.shade200, width: 2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: const Text(
                                          'Check for Updates',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.teal.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline_rounded, color: Colors.teal.shade700, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(color: Colors.teal.shade900, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(bool hasUpdate) {
    if (_isLoading) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 3),
          ),
        ),
      );
    }

    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: hasUpdate ? Colors.teal.shade50 : Colors.teal.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            hasUpdate ? Icons.cloud_download_rounded : Icons.verified_rounded,
            color: Colors.teal.shade600,
            size: 46,
          ),
        ),
      ),
    );
  }

  Widget _buildVersionDetailsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildVersionCol('CURRENT', _currentVersion),
          Container(width: 1, height: 40, color: Colors.teal.shade200.withOpacity(0.5)),
          _buildVersionCol('LATEST', _isLoading ? '...' : (_latestVersion.isEmpty ? _currentVersion : _latestVersion)),
        ],
      ),
    );
  }

  Widget _buildVersionCol(String title, String version) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.teal.shade700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          version,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseNotesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.new_releases_rounded, size: 18, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            Text(
              'What\'s New',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.shade100.withOpacity(0.5)),
          ),
          constraints: const BoxConstraints(maxHeight: 140),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Text(
                _releaseNotes,
                style: TextStyle(fontSize: 13, color: Colors.teal.shade800, height: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Downloading...',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.teal.shade700),
            ),
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: Colors.teal.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
