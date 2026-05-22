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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('App Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.withOpacity(0.02), Colors.teal.withOpacity(0.08)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusIcon(hasUpdate),
                      const SizedBox(height: 24),
                      Text(
                        hasUpdate ? 'New Update Available!' : 'Your App is Up to Date',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        hasUpdate
                            ? 'A new version of SchoolSync is ready for download.'
                            : 'You are running the latest features and security updates.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _buildVersionDetailsCard(),
                      const SizedBox(height: 24),
                      if (hasUpdate && _releaseNotes.isNotEmpty) _buildReleaseNotesCard(),
                      const SizedBox(height: 32),
                      if (_isDownloading)
                        _buildDownloadProgressIndicator()
                      else if (_isLoading)
                        const CircularProgressIndicator(color: Colors.teal)
                      else ...[
                        if (hasUpdate)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _handleUpdate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                kIsWeb ? 'Update & Refresh (PWA)' : 'Update Now',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _initAndCheck,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal,
                                side: const BorderSide(color: Colors.teal, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Check for Updates',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[100]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: Colors.red[600], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[800], fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool hasUpdate) {
    if (_isLoading) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 3),
          ),
        ),
      );
    }

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: hasUpdate ? Colors.teal.withOpacity(0.08) : const Color(0xFFE8F5E9),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          hasUpdate ? Icons.system_update_rounded : Icons.check_circle_outline_rounded,
          color: hasUpdate ? Colors.teal : const Color(0xFF2E7D32),
          size: 42,
        ),
      ),
    );
  }

  Widget _buildVersionDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'CURRENT VERSION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currentVersion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'LATEST VERSION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLoading ? '...' : (_latestVersion.isEmpty ? _currentVersion : _latestVersion),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseNotesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: double.infinity),
        const Text(
          'What\'s New',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          constraints: const BoxConstraints(maxHeight: 120),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Text(
                _releaseNotes,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
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
        LinearProgressIndicator(
          value: _downloadProgress,
          backgroundColor: Colors.teal.withOpacity(0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 8),
        Text(
          'Downloading update... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal),
        ),
      ],
    );
  }
}
