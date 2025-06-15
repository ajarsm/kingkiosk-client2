import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../controllers/settings_controller_compat.dart';
import 'web_url_settings_view_fixed.dart';
import 'mqtt_settings_view.dart';
import 'communications_settings_view.dart';
import 'ai_settings_view.dart';
import 'media_settings_view.dart';
import '../../../controllers/app_state_controller.dart';
import '../../../widgets/responsive_app_bar.dart';
import '../../../widgets/responsive_settings_layout.dart';
import '../../../core/utils/responsive_utils.dart';

class SettingsViewFixed extends GetView<SettingsControllerFixed> {
  const SettingsViewFixed({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Controller is automatically provided by GetView
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'Settings',
        actions: [
          ResponsiveAction(
            icon: const Icon(Icons.refresh),
            label: 'Reset All',
            tooltip: 'Reset All Settings',
            onPressed: controller.resetAllSettings,
          ),
          ResponsiveAction(
            icon: const Icon(Icons.info_outline),
            label: 'Help',
            tooltip: 'Settings Help',
            onPressed: () => _showSettingsHelp(context),
          ),
        ],
      ),
      body: ResponsiveSettingsLayout(
        children: [
          _buildPinSettings(controller), // App Settings
          _buildSection(
            context,
            title: 'App Settings',
            children: [
              _buildThemeToggle(),
              _buildKioskModeToggle(),
              _buildSystemInfoToggle(),
              _buildLocationServicesToggle(),
              _buildAutoLockSettings(),
              _buildBackgroundSettings(),
            ],
          ), // Web URLs
          _buildSection(
            context,
            title: 'Web URLs',
            children: [
              WebUrlSettingsViewFixed(),
            ],
          ), // MQTT
          _buildSection(
            context,
            title: 'IoT & Integrations',
            children: [
              MqttSettingsView(),
            ],
          ), // Communications
          _buildSection(
            context,
            title: 'Communications',
            children: [
              CommunicationsSettingsView(),
            ],
          ), // AI Settings
          _buildSection(
            context,
            title: 'AI Assistant',
            children: [
              const AiSettingsView(),
            ],
          ), // Media Settings
          _buildSection(
            context,
            title: 'Media & Playback',
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                child: ListTile(
                  leading: ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      colors: [Colors.redAccent, Colors.orangeAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(rect),
                    child: Icon(Icons.videocam, color: Colors.white),
                  ),
                  title: Text('Media Settings',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Hardware acceleration, video compatibility'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.blueGrey.shade300),
                  onTap: () => Get.to(() => MediaSettingsView()),
                ),
              ),
            ],
          ), // App info
          Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
            child: Center(
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      'King Kiosk v${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.0,
                      ),
                    );
                  } else {
                    return Text(
                      'King Kiosk v1.0.0',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.0,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ], // Close children array for ResponsiveSettingsLayout
      ),
    );
  }

  // Add the help method
  void _showSettingsHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings Help'),
        content: const Text(
          'Navigate through different settings categories:\n\n'
          '• App Settings: General application preferences\n'
          '• Web URLs: Configure web content sources\n'
          '• IoT & Integrations: MQTT and device connections\n'
          '• Communications: Video call and chat settings\n'
          '• AI Assistant: AI model and behavior settings\n'
          '• Media & Playback: Hardware acceleration options\n\n'
          'Use the refresh button to reset all settings to defaults.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return ResponsiveCard(
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
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 22.0),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
          ...children,
        ],
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

  Widget _buildLocationServicesToggle() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: ListTile(
        leading: ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            colors: [Colors.green, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
          child: Icon(Icons.location_on, color: Colors.white),
        ),
        title: Text(
          'Location Services',
          style: TextStyle(fontWeight: FontWeight.bold),
          softWrap: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Enable location tracking and MQTT publishing',
          softWrap: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Obx(() {
          return Switch(
            value: controller.locationEnabled.value,
            onChanged: (value) {
              // Prevent rapid toggling by disabling for a moment
              controller.toggleLocationEnabled(value);
            },
          );
        }),
        onTap: () {
          final newValue = !controller.locationEnabled.value;
          controller.toggleLocationEnabled(newValue);
        },
      ),
    );
  }

  Widget _buildAutoLockSettings() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(rect),
                  child: Icon(Icons.lock_clock, color: Colors.white),
                ),
                SizedBox(width: 8),
                Text(
                  'Auto-lock Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 12),

            // Auto-lock toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Enable Auto-lock',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Obx(() => Switch(
                      value: controller.autoLockEnabled.value,
                      onChanged: controller.toggleAutoLockEnabled,
                    )),
              ],
            ),

            SizedBox(height: 16),

            // Timeout setting (only shown when auto-lock is enabled)
            Obx(() {
              if (!controller.autoLockEnabled.value) {
                return SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-lock Timeout',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue:
                              controller.autoLockTimeout.value.toString(),
                          decoration: InputDecoration(
                            labelText: 'Minutes',
                            hintText: 'e.g., 5.0 or 0.5',
                            border: OutlineInputBorder(),
                            suffixText: 'min',
                          ),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            final timeout = double.tryParse(value);
                            if (timeout != null &&
                                timeout > 0 &&
                                timeout <= 60) {
                              controller.setAutoLockTimeout(timeout);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      // Quick preset buttons
                      Column(
                        children: [
                          SizedBox(
                            width: 60,
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () =>
                                  controller.setAutoLockTimeout(0.5),
                              child:
                                  Text('0.5', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () =>
                                  controller.setAutoLockTimeout(1.0),
                              child: Text('1', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () =>
                                  controller.setAutoLockTimeout(5.0),
                              child: Text('5', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The app will automatically lock after ${controller.autoLockTimeout.value} minutes of inactivity.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundSettings() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wallpaper),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Root Window Background',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Divider(),
            Obx(() => DropdownButton<String>(
                  value: controller.backgroundType.value,
                  items: [
                    DropdownMenuItem(value: 'default', child: Text('Default')),
                    DropdownMenuItem(value: 'image', child: Text('Image')),
                    DropdownMenuItem(value: 'webview', child: Text('WebView')),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.setBackgroundType(value);
                  },
                )),
            Obx(() {
              if (controller.backgroundType.value == 'image') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(
                          text: controller.backgroundImagePath.value),
                      decoration: InputDecoration(
                        labelText: 'Image URL',
                        hintText: 'Enter image URL',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.image),
                      ),
                      onChanged: (value) =>
                          controller.setBackgroundImagePath(value),
                    ),
                    SizedBox(height: 8),
                    controller.backgroundImagePath.value.isNotEmpty
                        ? Image.network(
                            controller.backgroundImagePath.value,
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Text(
                                'Could not load image',
                                style: TextStyle(color: Colors.red)),
                          )
                        : SizedBox.shrink(),
                  ],
                );
              } else if (controller.backgroundType.value == 'webview') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(
                          text: controller.backgroundWebUrl.value),
                      decoration: InputDecoration(
                        labelText: 'WebView URL',
                        hintText: 'Enter web page URL',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.public),
                      ),
                      onChanged: (value) =>
                          controller.setBackgroundWebUrl(value),
                    ),
                  ],
                );
              } else {
                return SizedBox.shrink();
              }
            }),
          ],
        ),
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
