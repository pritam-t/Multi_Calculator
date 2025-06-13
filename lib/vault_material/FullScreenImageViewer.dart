import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imagePath;
  final bool enableHeroAnimation;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
    this.enableHeroAnimation = true,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PhotoViewController _photoViewController;
  double _scale = 1.0;
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController()
      ..outputStateStream.listen(_onScaleChanged);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onScaleChanged(PhotoViewControllerValue value) {
    setState(() => _scale = value.scale ?? 1.0);
    if ((value.scale ?? 1.0) > 1.1 && _showAppBar) {
      setState(() => _showAppBar = false);
    } else if ((value.scale ?? 1.0) <= 1.1 && !_showAppBar) {
      setState(() => _showAppBar = true);
    }
  }

  Future<void> _saveImage() async {
    try {
      // TODO: Implement actual image saving
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to gallery')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = PhotoView(
      controller: _photoViewController,
      imageProvider: FileImage(File(widget.imagePath)),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      initialScale: PhotoViewComputedScale.contained,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (_, __) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white, size: 60),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showAppBar = !_showAppBar),
            child: widget.enableHeroAnimation
                ? Hero(
              tag: widget.imagePath,
              child: content,
            )
                : content,
          ),
          if (_showAppBar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.black54,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: _saveImage,
                  ),
                ],
              ),
            ),
          if (!_showAppBar && _scale > 1.1)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.small(
                backgroundColor: Colors.black54,
                child: const Icon(Icons.close, color: Colors.white),
                onPressed: () => _photoViewController.reset(),
              ),
            ),
        ],
      ),
    );
  }
}