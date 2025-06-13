import 'package:video_player/video_player.dart';

enum MediaType { image, video }

class VaultMedia {
  final String path;
  final MediaType mediaType;
  VideoPlayerController? videoController;

  VaultMedia({
    required this.path,
    required this.mediaType,
    this.videoController,
  });

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
}


