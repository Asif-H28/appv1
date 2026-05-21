import 'dart:io';
import 'package:flutter/material.dart';

class AdminImageItem {
  final String? url;
  final String? filePath;
  final String title;

  AdminImageItem({
    this.url,
    this.filePath,
    required this.title,
  });
}

class AdminImageViewer extends StatefulWidget {
  final List<AdminImageItem> images;
  final int initialIndex;

  const AdminImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<AdminImageViewer> createState() => _AdminImageViewerState();
}

class _AdminImageViewerState extends State<AdminImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.images.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Photo PageView ────────────────────────────────
          GestureDetector(
            onVerticalDragEnd: (details) {
              // Swipe down to close option for premium native feel
              if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                Navigator.pop(context);
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: imageCount,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final item = widget.images[index];
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: Hero(
                      tag: 'admin_img_${item.filePath ?? item.url ?? index}',
                      child: item.filePath != null
                          ? Image.file(
                              File(item.filePath!),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.white60,
                                  size: 48,
                                ),
                              ),
                            )
                          : Image.network(
                              item.url!,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: Colors.teal,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.white60,
                                  size: 48,
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Top Bar Overlay ──────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  // Pagination / Counter Text
                  if (imageCount > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $imageCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 36), // Empty space spacer

                  // Right placeholder to keep alignment
                  const SizedBox(width: 36),
                ],
              ),
            ),
          ),

          // ── Bottom Information Overlay ────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                24,
                16,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.images[_currentIndex].title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (imageCount > 1) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        imageCount,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? Colors.teal
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
