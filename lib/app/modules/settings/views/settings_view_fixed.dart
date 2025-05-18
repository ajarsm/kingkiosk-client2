import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import 'web_url_settings_view_fixed.dart';
import 'mqtt_settings_view.dart';
import '../../../controllers/app_state_controller.dart';
import 'wyoming_settings_view.dart';
import '../../../controllers/call_settings_controller.dart';
import '../../../controllers/mediasoup_controller.dart';
import 'local_camera_preview_widget.dart';

class SettingsViewFixed extends GetView<SettingsController> {
  const SettingsViewFixed({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the globally registered controller
    final controller = Get.find<SettingsController>();
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
            ),

            // MQTT
            _buildSection(
              title: 'IoT & Integrations',
              children: [
                MqttSettingsView(),
              ],
            ),

            // Wyoming Satellite
            _buildSection(
              title: 'Wyoming Satellite',
              children: [
                ListTile(
                  title: Text('Wyoming Satellite'),
                  trailing: Icon(Icons.settings_voice),
                  onTap: () => Get.to(() => WyomingSettingsView()),
                ),
              ],
            ),

            // Other connection settings
            _buildSection(
              title: 'Advanced Connection Settings',
              children: [
                _buildWebSocketSettings(),
                _buildMediaServerSettings(),
                _buildMediasoupSettings(), // <-- Added Mediasoup settings UI
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

  Widget _buildWebSocketSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz),
                SizedBox(width: 8),
                Text(
                  'WebSocket Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 8),
            _buildWebSocketUrlField(),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSocketUrlField() {
    return Obx(() {
      // Create controller with text and place cursor at the end
      final textController =
          TextEditingController(text: controller.websocketUrl.value);
      textController.selection = TextSelection.fromPosition(
          TextPosition(offset: textController.text.length));

      return TextField(
        controller: textController,
        decoration: InputDecoration(
          labelText: 'WebSocket URL',
          hintText: 'wss://example.com/ws',
          border: OutlineInputBorder(),
        ),
        textDirection: TextDirection.ltr, // Force left-to-right text direction
        onSubmitted: controller.saveWebsocketUrl,
        onChanged: controller.saveWebsocketUrl,
      );
    });
  }

  Widget _buildMediaServerSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.video_library),
                SizedBox(width: 8),
                Text(
                  'Media Server Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 8),
            _buildMediaServerUrlField(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaServerUrlField() {
    return Obx(() {
      // Create controller with text and place cursor at the end
      final textController =
          TextEditingController(text: controller.mediaServerUrl.value);
      textController.selection = TextSelection.fromPosition(
          TextPosition(offset: textController.text.length));

      return TextField(
        controller: textController,
        decoration: InputDecoration(
          labelText: 'Media Server URL',
          hintText: 'https://example.com/media',
          border: OutlineInputBorder(),
        ),
        textDirection: TextDirection.ltr, // Force left-to-right text direction
        onSubmitted: controller.saveMediaServerUrl,
        onChanged: controller.saveMediaServerUrl,
      );
    });
  }

  Widget _buildMediasoupSettings() {
    final callSettings = Get.find<CallSettingsController>();
    final mediasoupController = Get.find<MediasoupController>();
    final ipController =
        TextEditingController(text: callSettings.mediasoupServerIp.value);
    final portController = TextEditingController(
        text: callSettings.mediasoupServerPort.value.toString());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_input_antenna),
                SizedBox(width: 8),
                Text(
                  'Mediasoup Server',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 8),
            // Mediasoup Server URL (user can enter ws:// or wss://)
            TextField(
              controller: ipController,
              decoration: InputDecoration(
                labelText: 'Mediasoup Server URL',
                hintText: 'ws://host:port/ws or wss://host:port/ws',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                callSettings.mediasoupServerIp.value = val;
                callSettings.saveSettings();
              },
            ),
            SizedBox(height: 12),
            // Group audio input and output device dropdowns in a Row
            Row(
              children: [
                Expanded(
                  child: Obx(() {
                    final devices = mediasoupController.audioInputDevices;
                    return DropdownButtonFormField<String>(
                      value: callSettings.selectedAudioInputId.value.isNotEmpty
                          ? callSettings.selectedAudioInputId.value
                          : (devices.isNotEmpty
                              ? devices.first.deviceId
                              : null),
                      items: devices
                          .map((d) => DropdownMenuItem(
                                value: d.deviceId,
                                child: Text(d.label.isNotEmpty
                                    ? d.label
                                    : 'Default Mic'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          callSettings.selectedAudioInputId.value = val;
                          callSettings.saveSettings();
                          final device = devices
                              .firstWhereOrNull((d) => d.deviceId == val);
                          if (device != null)
                            mediasoupController.switchAudioInput(device);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Audio Input',
                        border: OutlineInputBorder(),
                      ),
                    );
                  }),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Obx(() {
                    final devices = mediasoupController.audioOutputDevices;
                    return DropdownButtonFormField<String>(
                      value: callSettings.selectedAudioOutputId.value.isNotEmpty
                          ? callSettings.selectedAudioOutputId.value
                          : (devices.isNotEmpty
                              ? devices.first.deviceId
                              : null),
                      items: devices
                          .map((d) => DropdownMenuItem(
                                value: d.deviceId,
                                child: Text(d.label.isNotEmpty
                                    ? d.label
                                    : 'Default Speaker'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          callSettings.selectedAudioOutputId.value = val;
                          callSettings.saveSettings();
                          final device = devices
                              .firstWhereOrNull((d) => d.deviceId == val);
                          if (device != null)
                            mediasoupController.setAudioOutput(device);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Audio Output',
                        border: OutlineInputBorder(),
                      ),
                    );
                  }),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Video Input Device Dropdown
            Obx(() {
              final devices = mediasoupController.videoInputDevices;
              return DropdownButtonFormField<String>(
                value: callSettings.selectedVideoInputId.value.isNotEmpty
                    ? callSettings.selectedVideoInputId.value
                    : (devices.isNotEmpty ? devices.first.deviceId : null),
                items: devices
                    .map((d) => DropdownMenuItem(
                          value: d.deviceId,
                          child: Text(
                              d.label.isNotEmpty ? d.label : 'Default Camera'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    callSettings.selectedVideoInputId.value = val;
                    callSettings.saveSettings();
                    final device =
                        devices.firstWhereOrNull((d) => d.deviceId == val);
                    if (device != null)
                      mediasoupController.switchVideoInput(device);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Video Input Device',
                  border: OutlineInputBorder(),
                ),
              );
            }),
            SizedBox(height: 12),
            // Local video preview for selected camera
            Obx(() {
              final selectedId = callSettings.selectedVideoInputId.value;
              final devices = mediasoupController.videoInputDevices;
              final device =
                  devices.firstWhereOrNull((d) => d.deviceId == selectedId) ??
                      (devices.isNotEmpty ? devices.first : null);
              return Container(
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: device == null
                    ? Center(child: Text('No camera found'))
                    : LocalCameraPreviewWidget(deviceId: device.deviceId),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPinSettings(SettingsController controller) {
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
