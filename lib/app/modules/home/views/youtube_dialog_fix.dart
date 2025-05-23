import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/tiling_window_controller.dart';
import '../widgets/media_tile.dart';
import '../widgets/audio_tile.dart';
import '../widgets/image_tile.dart';
import '../widgets/auto_hide_title_bar.dart';
import '../widgets/webview_tile_manager.dart';
import '../widgets/youtube_player_tile.dart';
import '../../../data/models/window_tile_v2.dart';
import '../../../routes/app_pages.dart';
import '../../../services/navigation_service.dart';
import '../../../widgets/system_info_dashboard.dart';
import '../../../services/platform_sensor_service.dart';
import '../../../controllers/app_state_controller.dart';
import '../../../modules/settings/controllers/settings_controller.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../widgets/settings_lock_pin_pad.dart';
import '../../../services/window_manager_service.dart';
import '../controllers/web_window_controller.dart';
import '../controllers/youtube_window_controller.dart';
import '../../../services/ai_assistant_service.dart';
import 'package:king_kiosk/notification_system/notification_system.dart';
import '../../../widgets/window_halo_wrapper.dart';

// ... existing code ...

// Show a dialog to add a new YouTube window
void _showAddYouTubeDialog(BuildContext context) {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController urlController = TextEditingController();

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
                controller.addYouTubeTile(nameController.text, url, videoId);
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
