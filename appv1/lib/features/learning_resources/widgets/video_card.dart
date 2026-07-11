import 'package:flutter/material.dart';
import 'package:appv1/features/student/student_theme_manager.dart';

import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:appv1/features/learning_resources/screens/video_player_screen.dart';

class VideoCard extends StatelessWidget {
  StudentThemeConfig get theme => StudentThemeManager.themeNotifier.value;
  final Map<String, dynamic> videoData;
  final bool isTeacher;
  final VoidCallback? onDelete;

  const VideoCard({
    super.key,
    required this.videoData,
    required this.isTeacher,
    this.onDelete,
  });

  String getThumbnailUrl(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final title = videoData['title'] ?? 'Untitled Video';
    final teacherName = videoData['teacherName'] ?? 'Unknown Teacher';
    final url = videoData['url'] ?? '';
    final isLesson = videoData['videoType'] == 'lesson';
    final thumbnailUrl = getThumbnailUrl(url);

    String subtitle = "General Resource";
    if (isLesson) {
      final subjectName = videoData['subject']?['name'] ?? 'Subject';
      final lessonName = videoData['lesson']?['name'] ?? 'Lesson';
      subtitle = "$subjectName • $lessonName";
    }

    String dateStr = '';
    if (videoData['createdAt'] != null) {
      final dt = DateTime.parse(videoData['createdAt']).toLocal();
      dateStr = "${dt.day}/${dt.month}/${dt.year}";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(videoData: videoData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.primary.withOpacity(0.2)),
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: thumbnailUrl.isNotEmpty
                      ? Image.network(
                          thumbnailUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: Icon(Icons.video_library, size: 48, color: Colors.grey),
                            );
                          },
                        )
                      : Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: Icon(Icons.video_library, size: 48, color: Colors.grey),
                        ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow, color: Colors.white, size: 36),
                    ),
                  ),
                ),
                if (isTeacher)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        _showDeleteConfirmation(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
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
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: theme.textSecondary),
                          SizedBox(width: 4),
                          Text(
                            teacherName,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Video'),
        content: Text('Are you sure you want to delete this video?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (onDelete != null) {
                onDelete!();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
