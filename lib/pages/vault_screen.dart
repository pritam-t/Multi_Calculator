import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../vault_media.dart';
import '../vault_service.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final VaultService _vaultService = VaultService();
  List<VaultMedia> _mediaList = [];
  final List<VaultMedia> _selectedItems = [];
  VideoPlayerController? _currentVideoController;

  bool isSelectionMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);
    _disposeVideoControllers();
    final media = await _vaultService.getAllMedia();
    setState(() {
      _mediaList = media;
      _isLoading = false;
    });
  }

  void _disposeVideoControllers() {
    _currentVideoController?.dispose();
    _currentVideoController = null;
  }

  Future<void> _addMedia() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickMedia();

    if (file == null) return;

    setState(() => _isLoading = true);

    try {
      final ext = file.path.split('.').last.toLowerCase();
      final mediaType = ['mp4', 'avi', 'mov'].contains(ext)
          ? MediaType.video
          : MediaType.image;

      VaultMedia media = VaultMedia(
        path: file.path,
        mediaType: mediaType,
      );

      await _vaultService.addMedia(media);
      await _loadMedia();
    } catch (e) {
      debugPrint('Error adding media: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add media: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onMediaTap(VaultMedia media) {
    if (isSelectionMode) {
      setState(() {
        _selectedItems.contains(media)
            ? _selectedItems.remove(media)
            : _selectedItems.add(media);
      });
    } else if (media.mediaType == MediaType.video) {
      _disposeVideoControllers();
      _currentVideoController = VideoPlayerController.file(File(media.path))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Playing Video"),
              content: AspectRatio(
                aspectRatio: _currentVideoController!.value.aspectRatio,
                child: VideoPlayer(_currentVideoController!),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _currentVideoController?.pause();
                    Navigator.pop(context);
                  },
                  child: const Text("Close"),
                )
              ],
            ),
          );
          _currentVideoController?.play();
        }).catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to play video: ${e.toString()}')),
          );
        });
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Image"),
          content: Image.file(
            File(media.path),
            fit: BoxFit.contain,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        ),
      );
    }
  }

  void _onMediaLongPress(VaultMedia media) {
    setState(() {
      isSelectionMode = true;
      _selectedItems.add(media);
    });
  }

  void _cancelSelection() {
    setState(() {
      isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedItems.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete ${_selectedItems.length} item(s)?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _vaultService.deleteMedia(_selectedItems);
      await _loadMedia();
      _cancelSelection();
    }
  }


  // ... (keep other methods like _onMediaLongPress, _cancelSelection, _deleteSelected the same)

  @override
  void dispose() {
    _disposeVideoControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode ? '${_selectedItems.length} selected' : 'Vault'),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelSelection,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        itemCount: _mediaList.length,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (_, index) {
          final media = _mediaList[index];
          return GestureDetector(
            onTap: () => _onMediaTap(media),
            onLongPress: () => _onMediaLongPress(media),
            child: Stack(
              fit: StackFit.expand,
              children: [
                media.mediaType == MediaType.image
                    ? Image.file(File(media.path), fit: BoxFit.cover)
                    : FutureBuilder<Uint8List?>(
                  future: _getVideoThumbnail(media.path),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    }
                    return Container(color: Colors.grey);
                  },
                ),
                if (_selectedItems.contains(media))
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Icon(Icons.check_circle, color: Colors.white),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedia,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<Uint8List?> _getVideoThumbnail(String videoPath) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        quality: 50,
      );
      return thumbnail;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }
}