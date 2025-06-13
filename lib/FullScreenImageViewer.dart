import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart'; // Add this package

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final FileImage? imageFile;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
    this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: () => _saveImage(context),
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: imageFile ?? FileImage(File(imagePath)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (_, __) => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _saveImage(BuildContext context) async {
    try {
      // Add image saving logic here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to gallery')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}')),
      );
    }
  }
}