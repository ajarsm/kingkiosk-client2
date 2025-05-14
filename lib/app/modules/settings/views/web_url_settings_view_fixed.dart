import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller_compat.dart';
import '../../../core/utils/app_constants.dart';
import '../../../modules/home/controllers/tiling_window_controller.dart';

class WebUrlSettingsViewFixed extends GetView<SettingsController> {
  const WebUrlSettingsViewFixed({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the globally registered controller
    final controller = Get.find<SettingsController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public),
                SizedBox(width: 8),
                Text(
                  'Web URL',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 16),
            
            // Start URL
            _buildUrlInput(controller),
            SizedBox(height: 16),
            
            // Quick URL selection
            _buildQuickUrlSelection(controller),
            SizedBox(height: 16),
            
            // Open URL button
            _buildOpenUrlButton(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput(SettingsController controller) {
    return Obx(() {
      // Create controller with text and place cursor at the end
      final textController = TextEditingController(text: controller.kioskStartUrl.value);
      textController.selection = TextSelection.fromPosition(
        TextPosition(offset: textController.text.length)
      );
      
      return TextField(
        controller: textController,
        decoration: InputDecoration(
          labelText: 'Web URL',
          hintText: 'https://example.com',
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => controller.saveKioskStartUrl(''),
            tooltip: 'Clear URL',
          ),
        ),
        textDirection: TextDirection.ltr, // Force left-to-right text direction
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            controller.saveKioskStartUrl(value);
          }
        },
        onChanged: (value) {
          // Update as user types
          controller.saveKioskStartUrl(value);
        },
      );
    });
  }

  Widget _buildQuickUrlSelection(SettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select URLs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.sampleWebItems.map((item) => 
            ActionChip(
              label: Text(item['name']!),
              onPressed: () => controller.saveKioskStartUrl(item['url']!),
              avatar: Icon(Icons.link, size: 16),
            )
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildOpenUrlButton(SettingsController controller) {
    return ElevatedButton.icon(
      onPressed: () {
        // Get the tiling window controller
        if (controller.kioskStartUrl.value.isEmpty) {
          Get.snackbar('Error', 'Please enter a URL first');
          return;
        }
        
        try {
          final tileController = Get.find<TilingWindowController>();
          
          // Add a new tile with the current URL
          tileController.addWebViewTile(
            'Web View', 
            controller.kioskStartUrl.value
          );
          
          // Show feedback to user
          Get.snackbar(
            'New Window Created', 
            'Loaded URL: ${controller.kioskStartUrl.value}',
            snackPosition: SnackPosition.BOTTOM,
          );
        } catch (e) {
          print('Error opening URL in new window: $e');
          Get.snackbar('Error', 'Failed to open URL: $e');
        }
      },
      icon: Icon(Icons.add),
      label: Text('Open URL in New Window'),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 48),
      ),
    );
  }
}