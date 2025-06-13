import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../vault_material/FullScreenImageViewer.dart';
import '../vault_material/FullScreenVideoViewer.dart';
import '../vault_material/vault_media.dart';
import '../vault_material/vault_service.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final VaultService _vaultService = VaultService();
  final ScrollController _scrollController = ScrollController();
  final Map<String, Uint8List> _thumbnailCache = {};
  List<VaultMedia> _mediaList = [];
  List<VaultMedia> _selectedItems = [];
  int _currentPage = 0;
  bool isSelectionMode = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadMedia();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);
    final media = await _vaultService.getMediaPaginated(_currentPage, 20);
    setState(() {
      _mediaList = media;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreMedia() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    final newItems = await _vaultService.getMediaPaginated(_currentPage, 20);
    setState(() {
      _mediaList.addAll(newItems);
      _isLoadingMore = false;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreMedia();
    }
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

      await _vaultService.addMedia(VaultMedia(
        path: file.path,
        mediaType: mediaType,
      ));
      await _loadMedia();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add media: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMediaTap(VaultMedia media) async {
    if (isSelectionMode) {
      setState(() => _toggleSelection(media));
      return;
    }

    await precacheImage(FileImage(File(media.path)), context);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => media.mediaType == MediaType.image
            ? FullScreenImageViewer(imagePath: media.path)
            : FullScreenVideoViewer(videoPath: media.path),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _toggleSelection(VaultMedia media) {
    setState(() {
      _selectedItems.contains(media)
          ? _selectedItems.remove(media)
          : _selectedItems.add(media);
    });
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
        content: Text("Delete ${_selectedItems.length} selected item(s)?"),
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
      setState(() => _isLoading = true);
      try {
        await _vaultService.deleteMedia(_selectedItems);
        await _loadMedia();
        _cancelSelection();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<Uint8List?> _getVideoThumbnail(String videoPath) async {
    if (_thumbnailCache.containsKey(videoPath)) {
      return _thumbnailCache[videoPath];
    }

    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.WEBP,
        maxWidth: 300,
        quality: 50,
      );
      if (thumbnail != null) _thumbnailCache[videoPath] = thumbnail;
      return thumbnail;
    } catch (e) {
      debugPrint('Thumbnail error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _thumbnailCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(isSelectionMode
              ? '${_selectedItems.length} Selected'
              : 'Media Vault'),
          actions: [
            if (isSelectionMode) ...[
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _selectedItems.isEmpty ? null : _deleteSelected,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelSelection,
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: _mediaList.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (_, index) {
            if (index >= _mediaList.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final media = _mediaList[index];
            return _buildMediaItem(media);
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addMedia,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildMediaItem(VaultMedia media) {
    return GestureDetector(
      onTap: () => _onMediaTap(media),
      onLongPress: () => _onMediaLongPress(media),
      child: Hero(
        tag: media.path,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              media.mediaType == MediaType.image
                  ? Image.file(File(media.path), fit: BoxFit.cover)
                  : FutureBuilder<Uint8List?>(
                future: _getVideoThumbnail(media.path),
                builder: (_, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    );
                  }
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(Icons.videocam, color: Colors.white),
                    ),
                  );
                },
              ),
              if (_selectedItems.contains(media))
                Container(
                  color: Colors.black54,
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              if (media.mediaType == MediaType.video)
                const Positioned(
                  bottom: 4,
                  right: 4,
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}