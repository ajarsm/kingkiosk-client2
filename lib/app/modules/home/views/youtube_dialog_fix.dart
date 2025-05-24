import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/tiling_window_controller.dart';
import '../widgets/youtube_player_tile.dart';

// Note: This function should be called from a button or menu item
// to display the YouTube video addition dialog.

// Show a dialog to add a new YouTube window
void _showAddYouTubeDialog(BuildContext context) {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final tilingController = Get.find<TilingWindowController>();

  // Use Future.microtask to avoid setState during build errors
  Future.microtask(() {
    Get.dialog(
      AlertDialog(
        title: Text('Add YouTube Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter a name for this window',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'YouTube URL or Video ID',
                hintText: 'Enter YouTube URL or Video ID',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                // Extract video ID if this is a full URL
                String url = urlController.text.trim();
                String? extractedId = YouTubePlayerManager.extractVideoId(url);
                String videoId = extractedId ?? url;

                // Add the YouTube tile
                tilingController.addYouTubeTile(
                    nameController.text, url, videoId);
                Get.back();
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  });
}

// Example usage:
// Inside a widget's build method:
//
// ElevatedButton(
//   onPressed: () => _showAddYouTubeDialog(context),
//   child: Text('Add YouTube Video'),
// )
