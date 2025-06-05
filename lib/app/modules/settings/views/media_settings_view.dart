import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller_compat.dart';
import '../../../services/media_device_service.dart';
import '../../../services/media_hardware_detection.dart';
import '../../../services/person_detection_service.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/person_detection_debug_widget.dart';

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
            _buildMediaDevicesSection(),
            SizedBox(height: 24),
            _buildDeviceInfoSection(),
            SizedBox(height: 24),
            if (controller.lastMediaError.value != null) _buildErrorSection(),
            SizedBox(height: 24),
            _buildPersonDetectionSection(),
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

  Widget _buildMediaDevicesSection() {
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
                Icon(Icons.devices, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Media Devices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Configure your audio and video input/output devices for communications and media playback.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            _buildMediaDevicesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaDevicesList() {
    try {
      Get.find<MediaDeviceService>(); // Verify service is available
      return Column(
        children: [
          // Audio Input Devices
          _buildAudioInputSelector(),
          const SizedBox(height: 12.0),

          // Video Input Devices
          _buildVideoInputSelector(),
          const SizedBox(height: 12.0),

          // Audio Output Devices
          _buildAudioOutputSelector(),
        ],
      );
    } catch (e) {
      // Show error if MediaDeviceService is not available
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Media device service not available. Please restart the application.',
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAudioInputSelector() {
    return Obx(() {
      try {
        final mediaDeviceService = Get.find<MediaDeviceService>();
        final audioInputDevices = mediaDeviceService.audioInputs;
        final selectedDevice = mediaDeviceService.selectedAudioInput.value;

        if (audioInputDevices.isEmpty) {
          return Card(
            color: Colors.grey.shade100,
            child: ListTile(
              leading: Icon(Icons.mic_off, color: Colors.grey),
              title: Text('No microphones found'),
              subtitle: Text('No audio input devices available'),
            ),
          );
        }

        return Card(
          child: ListTile(
            leading: Icon(Icons.mic, color: Colors.blue),
            title: Text('Microphone'),
            subtitle: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              value: selectedDevice?.deviceId,
              items: audioInputDevices.map((device) {
                return DropdownMenuItem<String>(
                  value: device.deviceId,
                  child: Text(
                    device.label.isNotEmpty ? device.label : 'Default Microphone',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (deviceId) {
                if (deviceId != null) {
                  final device = audioInputDevices.firstWhere(
                    (d) => d.deviceId == deviceId,
                    orElse: () => audioInputDevices.first,
                  );
                  mediaDeviceService.setAudioInput(device);
                }
              },
            ),
          ),
        );
      } catch (e) {
        return Card(
          color: Colors.red.shade50,
          child: ListTile(
            leading: Icon(Icons.error, color: Colors.red),
            title: Text('Audio Input Error'),
            subtitle: Text('Failed to load microphones'),
          ),
        );
      }
    });
  }

  Widget _buildVideoInputSelector() {
    return Obx(() {
      try {
        final mediaDeviceService = Get.find<MediaDeviceService>();
        final videoInputDevices = mediaDeviceService.videoInputs;
        final selectedDevice = mediaDeviceService.selectedVideoInput.value;

        if (videoInputDevices.isEmpty) {
          return Card(
            color: Colors.grey.shade100,
            child: ListTile(
              leading: Icon(Icons.videocam_off, color: Colors.grey),
              title: Text('No cameras found'),
              subtitle: Text('No video input devices available'),
            ),
          );
        }

        return Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.videocam, color: Colors.green),
                title: Text('Camera'),
                subtitle: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: selectedDevice?.deviceId,
                  items: videoInputDevices.map((device) {
                    return DropdownMenuItem<String>(
                      value: device.deviceId,
                      child: Text(
                        device.label.isNotEmpty ? device.label : 'Default Camera',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (deviceId) {
                    if (deviceId != null) {
                      final device = videoInputDevices.firstWhere(
                        (d) => d.deviceId == deviceId,
                        orElse: () => videoInputDevices.first,
                      );
                      mediaDeviceService.setVideoInput(device);
                    }
                  },
                ),
              ),
              // Camera preview
              if (selectedDevice != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CameraPreviewWidget(
                        deviceId: selectedDevice.deviceId,
                        width: double.infinity,
                        height: 200,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      } catch (e) {
        return Card(
          color: Colors.red.shade50,
          child: ListTile(
            leading: Icon(Icons.error, color: Colors.red),
            title: Text('Video Input Error'),
            subtitle: Text('Failed to load cameras'),
          ),
        );
      }
    });
  }

  Widget _buildAudioOutputSelector() {
    return Obx(() {
      try {
        final mediaDeviceService = Get.find<MediaDeviceService>();
        final audioOutputDevices = mediaDeviceService.audioOutputs;
        final selectedDevice = mediaDeviceService.selectedAudioOutput.value;

        if (audioOutputDevices.isEmpty) {
          return Card(
            color: Colors.grey.shade100,
            child: ListTile(
              leading: Icon(Icons.speaker_phone, color: Colors.grey),
              title: Text('No speakers found'),
              subtitle: Text('No audio output devices available'),
            ),
          );
        }

        return Card(
          child: ListTile(
            leading: Icon(Icons.speaker, color: Colors.purple),
            title: Text('Speaker'),
            subtitle: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              value: selectedDevice?.deviceId,
              items: audioOutputDevices.map((device) {
                return DropdownMenuItem<String>(
                  value: device.deviceId,
                  child: Text(
                    device.label.isNotEmpty ? device.label : 'Default Speaker',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (deviceId) {
                if (deviceId != null) {
                  final device = audioOutputDevices.firstWhere(
                    (d) => d.deviceId == deviceId,
                    orElse: () => audioOutputDevices.first,
                  );
                  mediaDeviceService.setAudioOutput(device);
                }
              },
            ),
          ),
        );
      } catch (e) {
        return Card(
          color: Colors.red.shade50,
          child: ListTile(
            leading: Icon(Icons.error, color: Colors.red),
            title: Text('Audio Output Error'),
            subtitle: Text('Failed to load speakers'),
          ),
        );
      }
    });
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

  Widget _buildPersonDetectionSection() {
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
                Icon(Icons.visibility, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Person Detection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Enable person presence detection using the camera. When enabled, the system will monitor for people in the camera view.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),            Obx(() => SwitchListTile(
                  title: Text('Enable Person Detection'),
                  subtitle: Text(controller.personDetectionEnabled.value
                      ? 'Person detection is active'
                      : 'Person detection is disabled'),
                  value: controller.personDetectionEnabled.value,
                  onChanged: (_) {
                    controller.togglePersonDetection();
                  },
                  secondary: Icon(
                    controller.personDetectionEnabled.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: controller.personDetectionEnabled.value
                        ? Colors.green
                        : Colors.grey,
                  ),
                )),
            SizedBox(height: 16),            // Debug visualization button - only show when person detection is enabled
            Obx(() => controller.personDetectionEnabled.value
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.bug_report, color: Colors.orange),
                          label: Text('Debug Visualization'),
                          onPressed: () {
                            Get.to(() => PersonDetectionDebugWidget());
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                    ],
                  )
                : SizedBox.shrink()),            // Status information
            Obx(() {
              if (!controller.personDetectionEnabled.value) {
                return SizedBox.shrink();
              }

              try {
                final personDetectionService = Get.find<PersonDetectionService>();
                return Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detection Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            personDetectionService.isPersonPresent.value
                                ? Icons.person
                                : Icons.person_outline,
                            color: personDetectionService.isPersonPresent.value
                                ? Colors.green
                                : Colors.grey,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            personDetectionService.isPersonPresent.value
                                ? 'Person detected'
                                : 'No person detected',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Confidence: ${(personDetectionService.confidence.value * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      Text(
                        'Frames processed: ${personDetectionService.framesProcessed.value}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                return Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Person detection service not available',
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}
