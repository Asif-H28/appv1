import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class PdfViewerPage extends StatelessWidget {
  final String? url;
  final String? filePath;
  final Uint8List? bytes;
  final String fileName;

  const PdfViewerPage({
    Key? key,
    this.url,
    this.filePath,
    this.bytes,
    required this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget pdfWidget;

    if (filePath != null && !filePath!.startsWith('http')) {
      pdfWidget = const PDF(
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        fitEachPage: true,
      ).fromPath(filePath!);
    } else if (url != null && url!.isNotEmpty) {
      pdfWidget = const PDF(
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        fitEachPage: true,
      ).cachedFromUrl(
        url!,
        placeholder: (progress) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: progress / 100,
                color: Colors.teal,
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 14),
              Text(
                'Loading PDF ($progress%)...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        errorWidget: (error) => _buildError(error.toString()),
      );
    } else {
      pdfWidget = _buildError('No PDF data available');
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'PDF Document',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
      body: pdfWidget,
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 44),
          const SizedBox(height: 12),
          Text(
            'Failed to load PDF',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
