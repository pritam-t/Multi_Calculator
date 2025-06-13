import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
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
  List<VaultMedia> _mediaItems = [];

  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final media = await _vaultService.getAllMedia();

    await Future.wait(media.map((item) async {
      if (item.mediaType == MediaType.video && item.videoController == null) {
        final controller = VideoPlayerController.file(File(item.path));
        await controller.initialize();
        item.videoController = controller;
      }
    }));

    setState(() {
      _mediaList = media;
    });
  }



  Future<void> _addMedia() async {

    final picker = ImagePicker();
    final XFile? file = await picker.pickMedia(); // picks either image or video

    if (file == null) return;

    final ext = file.path.split('.').last.toLowerCase();
    final mediaType = ['mp4', 'avi', 'mov',].contains(ext)
        ? MediaType.video
        : MediaType.image;

    VaultMedia media = VaultMedia(
      path: file.path,
      mediaType: mediaType,
    );
    if (mediaType == MediaType.video) {
      final controller = VideoPlayerController.file(File(file.path));
      await controller.initialize();
      media.videoController = controller;
    }

    await _vaultService.addMedia(media);
    await _loadMedia();
  }

  void _onMediaTap(VaultMedia media) {
    if (isSelectionMode) {
      setState(() {
        _selectedItems.contains(media)
            ? _selectedItems.remove(media)
            : _selectedItems.add(media);
      });
    } else if (media.mediaType == MediaType.video) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Playing Video"),
          content: AspectRatio(
            aspectRatio: media.videoController!.value.aspectRatio,
            child: VideoPlayer(media.videoController!),
          ),
          actions: [
            TextButton(
              onPressed: () {
                media.videoController?.pause();
                Navigator.pop(context);
              },
              child: const Text("Close"),
            )
          ],
        ),
      );
      media.videoController?.play();
    } else if (media.mediaType == MediaType.image) {
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


  @override
  void dispose() {
    for (var media in _mediaList) {
      media.videoController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode
            ? '${_selectedItems.length} selected'
            : 'Vault'),
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
      body: GridView.builder(
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
                    : media.videoController != null &&
                    media.videoController!.value.isInitialized
                    ? VideoPlayer(media.videoController!)
                    : const Center(child: CircularProgressIndicator()),
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
}
