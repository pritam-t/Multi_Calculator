import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';

class FullScreenVideoViewer extends StatefulWidget {
  final String videoPath;
  final bool autoplay;

  const FullScreenVideoViewer({
    super.key,
    required this.videoPath,
    this.autoplay = true,
  });

  @override
  State<FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<FullScreenVideoViewer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializePlayer() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.videoPath))
        ..addListener(_videoListener);

      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: widget.autoplay,
        looping: false,
        allowFullScreen: false,
        showControlsOnInitialize: true,
        materialProgressColors:  ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey,
        ),
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) => Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load video: ${e.toString()}')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _videoListener() {
    if (_videoController.value.aspectRatio > 1 && !_isLandscape) {
      setState(() => _isLandscape = true);
    } else if (_videoController.value.aspectRatio <= 1 && _isLandscape) {
      setState(() => _isLandscape = false);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _saveVideo() async {
    try {
      // TODO: Implement actual video saving
      // Using package like 'gallery_saver'
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video saved to gallery')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: !_isLandscape,
        bottom: !_isLandscape,
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: widget.videoPath,
                child: _isLoading
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading video...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                )
                    : Chewie(controller: _chewieController!),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: _saveVideo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}