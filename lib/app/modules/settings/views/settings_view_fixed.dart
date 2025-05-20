import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller_compat.dart';
import 'web_url_settings_view_fixed.dart';
import 'mqtt_settings_view.dart';
import 'communications_settings_view.dart';
import '../../../controllers/app_state_controller.dart';

class SettingsViewFixed extends GetView<SettingsControllerFixed> {
  const SettingsViewFixed({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Controller is automatically provided by GetView
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: controller.resetAllSettings,
            tooltip: 'Reset All Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPinSettings(controller),
            // App Settings
            _buildSection(
              title: 'App Settings',
              children: [
                _buildThemeToggle(),
                _buildKioskModeToggle(),
                _buildSystemInfoToggle(),
              ],
            ),

            // Web URLs
            _buildSection(
              title: 'Web URLs',
              children: [
                WebUrlSettingsViewFixed(),
              ],
            ), // MQTT
            _buildSection(
              title: 'IoT & Integrations',
              children: [
                MqttSettingsView(),
              ],
            ),

            // Communications
            _buildSection(
              title: 'Communications',
              children: [
                CommunicationsSettingsView(),
              ],
            ),

            // App info
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
              child: Center(
                child: Text(
                  'Flutter GetX Kiosk v1.0.0',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildThemeToggle() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.brightness_6),
        title: Text('Dark Mode'),
        subtitle: Text('Toggle application theme'),
        trailing: Obx(() => Switch(
              value: controller.isDarkMode.value,
              onChanged: (_) => controller.toggleDarkMode(),
            )),
        onTap: () => controller.toggleDarkMode(),
      ),
    );
  }

  Widget _buildKioskModeToggle() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.tv),
        title: Text('Kiosk Mode'),
        subtitle: Text('Fullscreen display mode'),
        trailing: Obx(() => Switch(
              value: controller.kioskMode.value,
              onChanged: (_) => controller.toggleKioskMode(),
            )),
        onTap: () => controller.toggleKioskMode(),
      ),
    );
  }

  Widget _buildSystemInfoToggle() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.info_outline),
        title: Text('System Info'),
        subtitle: Text('Show system information'),
        trailing: Obx(() => Switch(
              value: controller.showSystemInfo.value,
              onChanged: (_) {
                controller.toggleShowSystemInfo();
                // Also update AppStateController to keep UI in sync
                if (Get.isRegistered<AppStateController>()) {
                  Get.find<AppStateController>().showSystemInfo.value =
                      controller.showSystemInfo.value;
                }
              },
            )),
        onTap: () {
          controller.toggleShowSystemInfo();
          if (Get.isRegistered<AppStateController>()) {
            Get.find<AppStateController>().showSystemInfo.value =
                controller.showSystemInfo.value;
          }
        },
      ),
    );
  }

  // Advanced Connection Settings removed
  Widget _buildPinSettings(SettingsControllerFixed controller) {
    final pinController =
        TextEditingController(text: controller.settingsPin.value);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock),
                SizedBox(width: 8),
                Text('Settings PIN',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Divider(),
            SizedBox(height: 8),
            TextField(
              controller: pinController,
              decoration: InputDecoration(
                labelText: '4-digit PIN',
                hintText: 'Enter new PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              onChanged: (value) {
                if (value.length == 4 && RegExp(r'^\d{4}$').hasMatch(value)) {
                  controller.setSettingsPin(value);
                }
              },
            ),
            Text('Changing this PIN will be required to unlock settings.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
