import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller_compat.dart';
import 'web_url_settings_view_fixed.dart';
import 'mqtt_settings_view.dart';
import 'communications_settings_view.dart';
import 'ai_settings_view.dart';
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
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  child: ListTile(
                    leading: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        colors: [Colors.blueAccent, Colors.cyanAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(rect),
                      child: Icon(Icons.settings_rounded, color: Colors.white),
                    ),
                    title: Text('App Settings',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('General application settings'),
                    trailing: Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.blueGrey.shade300),
                    onTap: () => controller.saveAppSettings(),
                  ),
                ),
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
            ), // Communications
            _buildSection(
              title: 'Communications',
              children: [
                CommunicationsSettingsView(),
              ],
            ),
            // AI Settings
            _buildSection(
              title: 'AI Assistant',
              children: [
                const AiSettingsView(),
              ],
            ),

            // Security Settings
            _buildSection(
              title: 'Security',
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  child: ListTile(
                    leading: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        colors: [Colors.blueAccent, Colors.cyanAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(rect),
                      child: Icon(Icons.security_rounded, color: Colors.white),
                    ),
                    title: Text('Security',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('PIN and access control'),
                    trailing: Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.blueGrey.shade300),
                    onTap: () {
                      // No saveSecuritySettings method exists; open PIN dialog or show info instead
                      Get.snackbar(
                        'Security',
                        'PIN and access control settings are managed above.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor:
                            Colors.blueGrey.shade900.withOpacity(0.9),
                        colorText: Colors.white,
                        margin: EdgeInsets.all(16),
                        borderRadius: 16,
                        icon: Icon(Icons.security_rounded,
                            color: Colors.cyanAccent),
                        duration: Duration(seconds: 3),
                      );
                    },
                  ),
                ),
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
    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                colors: [Colors.blueAccent, Colors.cyanAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(rect),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            SizedBox(height: 12.0),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: ListTile(
        leading: ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            colors: [Colors.blueAccent, Colors.cyanAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
          child: Icon(Icons.brightness_6, color: Colors.white),
        ),
        title: Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
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
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: ListTile(
        leading: ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            colors: [Colors.blueAccent, Colors.cyanAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
          child: Icon(Icons.tv, color: Colors.white),
        ),
        title:
            Text('Kiosk Mode', style: TextStyle(fontWeight: FontWeight.bold)),
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
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: ListTile(
        leading: ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            colors: [Colors.blueAccent, Colors.cyanAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
          child: Icon(Icons.info_outline, color: Colors.white),
        ),
        title:
            Text('System Info', style: TextStyle(fontWeight: FontWeight.bold)),
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
