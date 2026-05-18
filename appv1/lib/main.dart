import 'package:appv1/features/main_app/pages/notification_router.dart';
import 'package:appv1/features/main_app/pages/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_theme.dart';

import 'core/constants/app_colors.dart';
import 'features/main_app/pages/login_page.dart';
import 'features/main_app/main_app_screen.dart';
import 'features/student/student_main_screen.dart';
import 'features/student/student_join_org_page.dart';
import 'features/student/student_pending_screen.dart';
import 'features/student/student_rejected_screen.dart';
import 'features/teacher/presentation/pages/teacher_main_screen.dart';
import 'features/teacher/presentation/pages/teacher_pending_screen.dart';
import 'core/services/chat_socket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Keeps UI above the system navigation bar globally
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Init Firebase + local notification channel
  await NotificationService.initFirebase();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Admin',
      theme: appTheme(),
      navigatorKey: navigatorKey,
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          // Status bar
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          // Navigation bar
          systemNavigationBarColor: Colors.white,
          systemNavigationBarContrastEnforced: false,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        child: _StartupRouter(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─── Decides which screen to show on app launch ──────────

class _StartupRouter extends StatefulWidget {
  @override
  __StartupRouterState createState() => __StartupRouterState();
}

class __StartupRouterState extends State<_StartupRouter> {
  bool _isChecking = true;
  Widget _startScreen = const SizedBox();

  @override
  void initState() {
    super.initState();
    _checkLoginState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    // Wait for the app to initialize a bit
    await Future.delayed(const Duration(seconds: 2));
    final update = await UpdateService.checkForUpdate();
    if (update != null && mounted) {
      _showUpdateDialog(update);
    }
  }

  void _showUpdateDialog(Map<String, dynamic> update) {
    double progress = 0;
    bool isDownloading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Update Available 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version ${update['version']} is available.'),
              const SizedBox(height: 8),
              Text(
                update['releaseNotes'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              if (isDownloading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ]
            ],
          ),
          actions: [
            if (!isDownloading)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Later', style: TextStyle(color: Colors.grey)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isDownloading
                  ? null
                  : () async {
                      setState(() => isDownloading = true);
                      final error = await UpdateService.downloadAndInstall(
                        update['downloadUrl'],
                        (p) => setState(() => progress = p),
                      );
                      if (!ctx.mounted) return;
                      if (error != null) {
                        setState(() => isDownloading = false);
                        Navigator.pop(ctx); // close update dialog
                        if (error == 'SIGNATURE_CONFLICT') {
                          _showSignatureConflictDialog(update);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                      // On success the Android installer takes over — no further action needed
                    },
              child: Text(isDownloading ? 'Downloading...' : 'Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown when the installed app has a different signing certificate than the
  /// downloaded APK.  Guides the user through: download → uninstall old → install new.
  void _showSignatureConflictDialog(Map<String, dynamic> update) {
    double progress = 0;
    bool isDownloading = false;
    bool downloadDone = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('One-Time Reinstall ⚠️'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The update has a different signature than your installed app. '
                'This is a one-time step — future updates will work normally.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              // ── Step 1: Download ──
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: downloadDone ? Colors.green.withOpacity(0.08) : Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      downloadDone ? Icons.check_circle : Icons.download_rounded,
                      color: downloadDone ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        downloadDone
                            ? 'APK saved to Downloads ✓'
                            : 'Step 1: Download update to Downloads',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: downloadDone ? Colors.green[800] : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isDownloading) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 8),
              // ── Step 2: Uninstall ──
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Step 2: Uninstall this old app',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // ── Step 3: Install ──
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.install_mobile, color: Colors.blue[400], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Step 3: Open Downloads → install SchoolSync_update.apk',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your data is saved on our servers — logging back in will restore everything.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later', style: TextStyle(color: Colors.grey)),
            ),
            if (!downloadDone)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isDownloading
                    ? null
                    : () async {
                        setState(() => isDownloading = true);
                        final path = await UpdateService.downloadOnly(
                          update['downloadUrl'],
                          (p) => setState(() => progress = p),
                        );
                        if (!mounted) return;
                        if (path != null) {
                          setState(() {
                            isDownloading = false;
                            downloadDone = true;
                          });
                        } else {
                          setState(() => isDownloading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Download failed. Please try again.')),
                          );
                        }
                      },
                child: Text(isDownloading ? 'Downloading...' : 'Download APK'),
              ),
            if (downloadDone)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  // Trigger Android uninstall dialog
                  await UpdateService.triggerUninstall();
                  // App may be killed after this — that's expected.
                  // The APK is in Downloads, user installs from file manager.
                },
                child: const Text('Uninstall Old App'),
              ),
          ],
        ),
      ),
    );
  }


  Future<void> _checkLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userRole = prefs.getString('userRole') ?? '';

    Widget screen;

    if (!isLoggedIn || userRole.isEmpty) {
      await prefs.clear();
      screen = LoginPage();
    } else {
      // Connect to Chat Socket if logged in
      final userId = prefs.getString('userId') ?? 
                     prefs.getString('teacherId') ?? 
                     prefs.getString('studentId') ?? 
                     prefs.getString('orgId') ?? '';
      final token = prefs.getString('authToken') ?? '';
      if (userId.isNotEmpty && token.isNotEmpty) {
        ChatSocketService().connect(userId, token);
      }

      if (userRole == 'admin') {
        // ── Admin ─────────────────────────────────────────
        final orgId = prefs.getString('orgId') ?? '';
        if (orgId.isNotEmpty) {
          await NotificationService.saveAdminTokenAfterLogin(orgId: orgId);
        }
        screen = MainAppScreen(initialTab: 0);
      } else if (userRole == 'teacher') {
        // ── Teacher ───────────────────────────────────────
        final isVerified = prefs.getBool('teacherVerified') ?? false;
        final teacherName = prefs.getString('teacherName') ?? 'Teacher';
        final teacherId = prefs.getString('teacherId') ?? '';
        final orgId = prefs.getString('orgId') ?? '';

        if (isVerified) {
          if (teacherId.isNotEmpty) {
            await NotificationService.saveTokenAfterLogin(
              userId: teacherId,
              role: 'teacher',
            );
          }
          screen = TeacherMainScreen();
        } else {
          screen = TeacherPendingScreen(teacherName: teacherName, orgId: orgId);
        }
      } else if (userRole == 'student') {
        // ── Student ───────────────────────────────────────
        final joinStatus = prefs.getString('joinStatus') ?? 'none';
        final classId = prefs.getString('classId') ?? '';
        final studentId = prefs.getString('studentId') ?? '';
        final studentName = prefs.getString('studentName') ?? 'Student';

        switch (joinStatus) {
          case 'approved':
            if (classId.isNotEmpty) {
              if (studentId.isNotEmpty) {
                await NotificationService.saveTokenAfterLogin(
                  userId: studentId,
                  role: 'student',
                );
              }
              screen = StudentMainScreen();
            } else {
              screen = StudentJoinOrgPage();
            }
            break;
          case 'pending':
            screen = StudentPendingScreen(studentName: studentName);
            break;
          case 'rejected':
            screen = StudentRejectedScreen(studentName: studentName);
            break;
          default:
            screen = StudentJoinOrgPage();
        }
      } else {
        // Unknown role — reset
        await prefs.clear();
        screen = LoginPage();
      }
    }

    setState(() {
      _startScreen = screen;
      _isChecking = false;
    });

    // Init notification listeners after screen is set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (userRole == 'student' || userRole == 'teacher' || userRole == 'admin')) {
        NotificationService.requestPermission();
        NotificationService.initListeners(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.sync_alt,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'SchoolSync',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      );
    }

    return _startScreen;
  }
}
