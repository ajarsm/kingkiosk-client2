import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../controllers/settings_controller_compat.dart';

class AiSettingsView extends GetView<SettingsController> {
  const AiSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'AI Assistant Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildAiToggle(),
            SizedBox(height: 16),
            _buildAiProviderField(),
            SizedBox(height: 16),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAiToggle() {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enable AI Assistant',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Switch(
              value: controller.aiEnabled.value,
              onChanged: (value) {
                controller.toggleAiEnabled(value);
              },
            ),
          ],
        ));
  }

  Widget _buildAiProviderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Provider Host:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Obx(() => TextFormField(
              controller: controller.aiProviderHostController,
              decoration: InputDecoration(
                hintText: 'Enter AI provider hostname or IP',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              enabled: controller.aiEnabled.value,
            )),
        SizedBox(height: 4),
        Text(
          'Enter the hostname or IP address of your AI provider service',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {
        controller.saveAiSettings();
      },
      child: Text('Save AI Settings'),
    );
  }
}
