import 'dart:io';

import 'package:video_player/video_player.dart';

enum MediaType { image, video }

class VaultMedia {
  final String path;
  final MediaType mediaType;
  VideoPlayerController? _videoController;
  bool _isControllerInitialized = false;

  VaultMedia({
    required this.path,
    required this.mediaType,
  });

  // Getter for controller with lazy initialization
  Future<VideoPlayerController?> get videoController async {
    if (mediaType != MediaType.video) return null;
    if (_videoController == null) {
      _videoController = VideoPlayerController.file(File(path));
      await _videoController?.initialize();
      _isControllerInitialized = true;
    }
    return _videoController;
  }

  // Proper cleanup method
  Future<void> dispose() async {
    if (_videoController != null && _isControllerInitialized) {
      await _videoController?.dispose();
      _videoController = null;
      _isControllerInitialized = false;
    }
  }

  // Serialization
  Map<String, dynamic> toJson() => {
    'path': path,
    'mediaType': mediaType.name,
  };

  factory VaultMedia.fromJson(Map<String, dynamic> json) => VaultMedia(
    path: json['path'],
    mediaType: MediaType.values.firstWhere(
          (e) => e.name == json['mediaType'],
      orElse: () => MediaType.image,
    ),
  );

  // For selection/equality checks
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VaultMedia &&
              runtimeType == other.runtimeType &&
              path == other.path;

  @override
  int get hashCode => path.hashCode;
}