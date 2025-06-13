import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart'; // Add this package

class FullScreenVideoViewer extends StatefulWidget {
  final String videoPath;

  const FullScreenVideoViewer({super.key, required this.videoPath});

  @override
  State<FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<FullScreenVideoViewer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.file(File(widget.videoPath));
    await _videoController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      allowFullScreen: false, // We're already full-screen
      showControlsOnInitialize: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.red,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey.withOpacity(0.5),
      ),
      placeholder: Container(color: Colors.black),
      autoInitialize: true,
    );

    setState(() {});
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () => _saveVideo(context),
            ),
          ],
        ),
        body: Center(
          child: _chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized
              ? Chewie(controller: _chewieController!)
              : const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading video...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveVideo(BuildContext context) async {
    try {
      // Add video saving logic here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video saved to gallery')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}')),
      );
    }
  }
}