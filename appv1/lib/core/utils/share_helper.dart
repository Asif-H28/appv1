import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static Future<void> shareAchievement({
    required BuildContext context,
    required List<String> imageUrls,
    required String caption,
    String? authorName,
    String? className,
  }) async {
    // 1. Copy caption to clipboard (helpful fallback since Instagram can strip captions)
    final String shareText = _buildShareText(caption, authorName, className);
    try {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caption copied to clipboard! (You can paste it directly in Instagram)'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ShareHelper] clipboard copy failed: $e');
    }

    // If no images, just share text
    if (imageUrls.isEmpty) {
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await Share.share(
        shareText,
        sharePositionOrigin: sharePositionOrigin,
      );
      return;
    }

    // Show loading overlay
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    try {
      final List<XFile> xFiles = [];

      if (kIsWeb) {
        // On web, download the image bytes and create an XFile from data
        for (int i = 0; i < imageUrls.length; i++) {
          final res = await http.get(Uri.parse(imageUrls[i]));
          if (res.statusCode == 200) {
            final mimeType = res.headers['content-type'] ?? 'image/png';
            final ext = mimeType.split('/').last;
            xFiles.add(
              XFile.fromData(
                res.bodyBytes,
                name: 'achievement_$i.$ext',
                mimeType: mimeType,
              ),
            );
          }
        }
      } else {
        // On mobile, download the file to a temp folder
        final tempDir = await getTemporaryDirectory();
        for (int i = 0; i < imageUrls.length; i++) {
          final res = await http.get(Uri.parse(imageUrls[i]));
          if (res.statusCode == 200) {
            final mimeType = res.headers['content-type'] ?? 'image/png';
            final ext = mimeType.split('/').last;
            final file = File(p.join(tempDir.path, 'achievement_$i.$ext'));
            await file.writeAsBytes(res.bodyBytes);
            xFiles.add(XFile(file.path, mimeType: mimeType));
          }
        }
      }

      // Pop the loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (xFiles.isNotEmpty) {
        final box = context.findRenderObject() as RenderBox?;
        final sharePositionOrigin = box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null;

        await Share.shareXFiles(
          xFiles,
          text: shareText,
          sharePositionOrigin: sharePositionOrigin,
        );
      } else {
        throw Exception('Failed to download images');
      }
    } catch (e) {
      // Pop the loading dialog if it's still showing
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to prepare post for share: $e'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  static String _buildShareText(String caption, String? authorName, String? className) {
    final buffer = StringBuffer();
    if (authorName != null && authorName.isNotEmpty) {
      buffer.write('Achievement by $authorName');
      if (className != null && className.isNotEmpty) {
        buffer.write(' ($className)');
      }
      buffer.write('\n\n');
    }
    buffer.write(caption);
    return buffer.toString();
  }
}
