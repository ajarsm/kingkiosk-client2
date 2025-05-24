import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller_compat.dart';
import '../../../services/media_hardware_detection.dart';

class MediaSettingsView extends GetView<SettingsControllerFixed> {
  const MediaSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Make sure hardware settings are loaded
    controller.loadHardwareAccelerationSettings();

    return Scaffold(
      appBar: AppBar(
        title: Text('Media Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHardwareAccelerationSection(),
            SizedBox(height: 24),
            _buildDeviceInfoSection(),
            SizedBox(height: 24),
            if (controller.lastMediaError.value != null) _buildErrorSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareAccelerationSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hardware, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Hardware Acceleration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Hardware acceleration uses the device\'s GPU to improve video playback performance. ' +
                  'However, some devices (particularly those with AllWinner processors) may experience ' +
                  'black screens or other issues with hardware acceleration enabled.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Obx(() => SwitchListTile(
                  title: Text('Enable Hardware Acceleration'),
                  subtitle: Text(controller.isHardwareAccelerationEnabled.value
                      ? 'Using GPU for video decoding'
                      : 'Using CPU for video decoding'),
                  value: controller.isHardwareAccelerationEnabled.value,
                  onChanged: (bool value) {
                    controller.toggleHardwareAcceleration(value);
                  },
                  secondary: Icon(
                    controller.isHardwareAccelerationEnabled.value
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: controller.isHardwareAccelerationEnabled.value
                        ? Colors.amber
                        : Colors.grey,
                  ),
                )),
            SizedBox(height: 8),
            Obx(() => controller.isProblematicDevice.value
                ? Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.amber.shade900),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your device has a processor that may experience issues with hardware acceleration.',
                            style: TextStyle(color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoSection() {
    // Get hardware detection service if available
    MediaHardwareDetectionService? service;
    try {
      service = Get.find<MediaHardwareDetectionService>();
    } catch (_) {
      // Service not available
    }

    if (service == null) {
      return SizedBox.shrink();
    }

    final deviceInfo = service.deviceInfo.value;
    if (deviceInfo.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Device Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...deviceInfo.entries.map((entry) {
              // Skip empty or null values
              if (entry.value == null || entry.value.toString().isEmpty) {
                return SizedBox.shrink();
              }

              // Format lists nicely
              String valueStr = entry.value.toString();
              if (entry.value is List) {
                valueStr = (entry.value as List).join(', ');
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${entry.key}:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        valueStr,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection() {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Last Media Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Obx(() => Text(
                  controller.lastMediaError.value ?? 'No errors',
                  style: TextStyle(fontSize: 14),
                )),
            SizedBox(height: 16),
            OutlinedButton.icon(
              icon: Icon(Icons.delete_outline),
              label: Text('Clear Error Log'),
              onPressed: () {
                try {
                  final service = Get.find<MediaHardwareDetectionService>();
                  service.lastError.value = null;
                  controller.lastMediaError.value = null;
                } catch (_) {
                  // Service not available
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
