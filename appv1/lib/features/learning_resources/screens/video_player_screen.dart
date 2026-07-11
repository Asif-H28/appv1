import 'package:flutter/material.dart';
import 'package:appv1/features/student/student_theme_manager.dart';

import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> videoData;

  const VideoPlayerScreen({super.key, required this.videoData});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  StudentThemeConfig get theme => StudentThemeManager.themeNotifier.value;
  YoutubePlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    final url = widget.videoData['url'] ?? '';
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
        ),
      );
    } else {
      _hasError = true;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _restoreSystemUI();
    super.dispose();
  }

  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // In Release mode, transitions can be too fast and get overridden by the player's native exit.
    // A slight delay ensures our command runs last.
    Future.delayed(const Duration(milliseconds: 400), () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.videoData['title'] ?? 'Video';
    final teacherName = widget.videoData['teacherName'] ?? 'Unknown Teacher';
    final isLesson = widget.videoData['videoType'] == 'lesson';
    
    // Attempt to parse subject/lesson names if available
    String subtitle = "General Resource";
    if (isLesson) {
      final subjectName = widget.videoData['subject']?['name'] ?? 'Subject';
      final lessonName = widget.videoData['lesson']?['name'] ?? 'Lesson';
      subtitle = "$subjectName • $lessonName";
    }

    String dateStr = '';
    if (widget.videoData['createdAt'] != null) {
      final dt = DateTime.parse(widget.videoData['createdAt']).toLocal();
      dateStr = "${dt.day}/${dt.month}/${dt.year}";
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: theme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Invalid video URL.', style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                ),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        _restoreSystemUI();
      },
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: theme.primary,
        progressColors: ProgressBarColors(
          playedColor: theme.primary,
          handleColor: theme.primary,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            title: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: theme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: ListView(
            children: [
              player,
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                        color: theme.primary.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.primary,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 16, color: theme.textSecondary),
                          SizedBox(width: 8),
                          Text(
                            teacherName,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (dateStr.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 16, color: theme.textSecondary),
                            SizedBox(width: 8),
                            Text(
                              'Shared on $dateStr',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
