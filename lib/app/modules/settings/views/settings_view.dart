import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import 'mqtt_settings_view.dart';
import 'web_url_settings_view.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use Get.find lazily here instead of during initialization
    // This avoids the setState during build issue
    final settingsController = Get.find<SettingsController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSection(
              title: 'Appearance',
              children: [
                _buildThemeSettings(context, settingsController),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Connection',
              children: [
                _buildWebSocketSettings(context, settingsController),
                const SizedBox(height: 16),
                _buildMediaServerSettings(context, settingsController),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Application',
              children: [
                _buildAppSettings(context, settingsController),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Web URLs',
              children: [
                WebUrlSettingsView(),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'IoT & Integrations',
              children: [
                MqttSettingsView(),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Use a future to avoid changing state during build
                  Future.microtask(() => settingsController.resetAllSettings());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Reset All Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Get.theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildThemeSettings(BuildContext context, SettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(() => SwitchListTile(
              title: const Text('Dark Mode'),
              value: controller.isDarkMode.value,
              onChanged: (value) {
                // Use Future.microtask to avoid changing state during build
                Future.microtask(() => controller.toggleDarkMode());
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSocketSettings(BuildContext context, SettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WebSocket Server',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(() => TextFormField(
              initialValue: controller.websocketUrl.value,
              decoration: const InputDecoration(
                hintText: 'wss://example.com',
                labelText: 'WebSocket URL',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (value) {
                if (value.isNotEmpty) {
                  // Use Future.microtask to avoid changing state during build
                  Future.microtask(() => controller.saveWebsocketUrl(value));
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaServerSettings(BuildContext context, SettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Media Server',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(() => TextFormField(
              initialValue: controller.mediaServerUrl.value,
              decoration: const InputDecoration(
                hintText: 'https://example.com',
                labelText: 'Media Server URL',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (value) {
                if (value.isNotEmpty) {
                  // Use Future.microtask to avoid changing state during build
                  Future.microtask(() => controller.saveMediaServerUrl(value));
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings(BuildContext context, SettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Application Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(() => SwitchListTile(
              title: const Text('Kiosk Mode'),
              subtitle: const Text('Full screen with no system controls'),
              value: controller.kioskMode.value,
              onChanged: (value) {
                // Use Future.microtask to avoid changing state during build
                Future.microtask(() => controller.toggleKioskMode());
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
            Obx(() => SwitchListTile(
              title: const Text('Show System Info'),
              subtitle: const Text('Display system information dashboard'),
              value: controller.showSystemInfo.value,
              onChanged: (value) {
                // Use Future.microtask to avoid changing state during build
                Future.microtask(() => controller.toggleShowSystemInfo());
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );
  }
}