import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../core/utils/app_constants.dart';
import '../../../modules/home/controllers/tiling_window_controller.dart';

class WebUrlSettingsView extends GetView<SettingsController> {
  const WebUrlSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            SizedBox(height: 8),
            
            // Auto-load functionality has been removed
            SizedBox(height: 8),
            
            // Start URL
            _buildUrlInput(),
            SizedBox(height: 16),
            
            // Quick URL selection
            _buildQuickUrlSelection(),
            SizedBox(height: 16),
            
            // Refresh button
            _buildRefreshButton(),
          ],
        ),
      ),
    );
  }

  // Auto-load switch has been removed

  Widget _buildUrlInput() {
    return Obx(() => TextFormField(
      initialValue: controller.kioskStartUrl.value,
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
      onFieldSubmitted: (value) {
        if (value.isNotEmpty) {
          controller.saveKioskStartUrl(value);
        }
      },
    ));
  }

  Widget _buildQuickUrlSelection() {
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

  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      onPressed: () {
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
      },
      icon: Icon(Icons.add),
      label: Text('Open URL in New Window'),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 48),
      ),
    );
  }
}