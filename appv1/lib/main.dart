import 'package:appv1/features/main_app/pages/notification_router.dart';
import 'package:appv1/features/main_app/pages/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';
import 'features/main_app/pages/login_page.dart';
import 'features/main_app/main_app_screen.dart';
import 'features/student/student_main_screen.dart';
import 'features/student/student_join_org_page.dart';
import 'features/student/student_pending_screen.dart';
import 'features/student/student_rejected_screen.dart';
import 'features/teacher/presentation/pages/teacher_main_screen.dart';
import 'features/teacher/presentation/pages/teacher_pending_screen.dart';
import 'core/services/chat_socket_service.dart';
import 'features/notification_studio/controllers/notification_studio_controller.dart';
import 'package:appv1/features/student/student_theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Keeps UI above the system navigation bar globally
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Init Firebase + local notification channel
  await NotificationService.initFirebase();
  
  // Init Student Theme preference
  await StudentThemeManager.init();

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

class __StartupRouterState extends State<_StartupRouter>
    with TickerProviderStateMixin {
  bool _isChecking = true;
  Widget _startScreen = const SizedBox();

  // ── Loading animation controllers ──
  late AnimationController _pulseController;
  late AnimationController _iconSwapController;
  late AnimationController _progressController;
  late AnimationController _floatingController;

  int _loadingPhase = 0;

  static const List<Map<String, dynamic>> _phases = [
    {'icon': Icons.wifi_rounded, 'label': 'Connecting to your school...'},
    {'icon': Icons.school_rounded, 'label': 'Finding your classroom...'},
    {'icon': Icons.menu_book_rounded, 'label': 'Setting up your desk...'},
    {'icon': Icons.auto_awesome_rounded, 'label': 'Almost there!'},
  ];

  @override
  void initState() {
    super.initState();

    // Pulse animation for the icon container glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Icon swap fade animation
    _iconSwapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );

    // Smooth progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..forward();

    // Floating particles animation
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _startPhaseSequence();
    _checkLoginState();
    _checkForUpdate();
  }

  void _startPhaseSequence() async {
    for (int i = 1; i < _phases.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      // Fade out current icon
      await _iconSwapController.reverse();
      if (!mounted) return;
      setState(() => _loadingPhase = i);
      // Fade in new icon
      _iconSwapController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _iconSwapController.dispose();
    _progressController.dispose();
    _floatingController.dispose();
    super.dispose();
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
      builder: (ctx) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.system_update_rounded, color: Colors.teal),
              SizedBox(width: 8),
              Text('Update Available', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
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
                  backgroundColor: Colors.teal.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
                const SizedBox(height: 4),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ]
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
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
    ),);
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
      builder: (ctx) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.teal),
              SizedBox(width: 8),
              Text('One-Time Reinstall', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
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
                  backgroundColor: Colors.teal.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
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
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            if (!downloadDone)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
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
    ),);
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
        NotificationStudioController().init(token);
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
    if (!mounted) return;
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
        backgroundColor: const Color(0xFFF8FFFE),
        body: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _iconSwapController,
            _progressController,
            _floatingController,
          ]),
          builder: (context, _) {
            final phase = _phases[_loadingPhase];
            final pulseVal = _pulseController.value;
            final iconOpacity = _iconSwapController.value;
            final progressVal = _progressController.value;

            return Stack(
              children: [
                // ── Floating particles ──
                ..._buildFloatingParticles(),

                // ── Main content ──
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Pulsing glow circle + icon ──
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 120 + (pulseVal * 20),
                            height: 120 + (pulseVal * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.teal.withOpacity(0.04 + pulseVal * 0.03),
                            ),
                          ),
                          // Middle glow ring
                          Container(
                            width: 95 + (pulseVal * 10),
                            height: 95 + (pulseVal * 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.teal.withOpacity(0.06 + pulseVal * 0.04),
                            ),
                          ),
                          // Icon container
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.teal.shade400,
                                  Colors.teal.shade600,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withOpacity(0.25 + pulseVal * 0.15),
                                  blurRadius: 20 + (pulseVal * 10),
                                  spreadRadius: 2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Opacity(
                              opacity: iconOpacity,
                              child: Transform.scale(
                                scale: 0.8 + (iconOpacity * 0.2),
                                child: Icon(
                                  phase['icon'] as IconData,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // ── App name ──
                      Text(
                        'SchoolSync',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.teal.shade700,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Phase message ──
                      Opacity(
                        opacity: iconOpacity,
                        child: Text(
                          phase['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.teal.shade400,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Progress bar ──
                      SizedBox(
                        width: 180,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressVal,
                            minHeight: 4,
                            backgroundColor: Colors.teal.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.teal.shade400,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Phase dots ──
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_phases.length, (i) {
                          final isActive = i == _loadingPhase;
                          final isDone = i < _loadingPhase;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isActive
                                  ? Colors.teal.shade400
                                  : isDone
                                      ? Colors.teal.shade200
                                      : Colors.teal.withOpacity(0.12),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return _startScreen;
  }

  /// Build floating animated decorative particles
  List<Widget> _buildFloatingParticles() {
    final t = _floatingController.value;
    final size = MediaQuery.of(context).size;

    // 6 small teal circles floating at different speeds/positions
    final particles = <_ParticleData>[
      _ParticleData(0.12, 0.18, 10, 0.06),
      _ParticleData(0.85, 0.25, 8, 0.04),
      _ParticleData(0.22, 0.75, 12, 0.05),
      _ParticleData(0.78, 0.70, 7, 0.07),
      _ParticleData(0.50, 0.12, 9, 0.03),
      _ParticleData(0.65, 0.85, 11, 0.05),
      _ParticleData(0.08, 0.50, 6, 0.04),
      _ParticleData(0.92, 0.55, 8, 0.06),
    ];

    return particles.map((p) {
      final yOffset = 20 * (0.5 - ((t + p.phase) % 1.0)).abs();
      return Positioned(
        left: p.x * size.width,
        top: p.y * size.height + yOffset,
        child: Container(
          width: p.radius,
          height: p.radius,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.teal.withOpacity(p.opacity),
          ),
        ),
      );
    }).toList();
  }
}

/// Data for a floating particle
class _ParticleData {
  final double x;
  final double y;
  final double radius;
  final double opacity;
  double get phase => x * 0.7 + y * 0.3; // deterministic offset

  const _ParticleData(this.x, this.y, this.radius, this.opacity);
}
