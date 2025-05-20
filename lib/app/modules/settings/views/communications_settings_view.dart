import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller_compat.dart';
import '../widgets/camera_preview_widget.dart';

/// Communications settings view for SIP/Drachtio server configuration
class CommunicationsSettingsView extends StatelessWidget {
  const CommunicationsSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsControllerFixed>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Communications Server',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16.0),

            // Enable SIP
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Enable Communications Server'),
                    Switch(
                      value: controller.sipEnabled.value,
                      onChanged: (value) {
                        controller.sipEnabled.value = value;
                        if (!value &&
                            controller.sipRegistered.value &&
                            controller.sipService != null) {
                          controller.sipService!.unregister();
                        }
                      },
                    ),
                  ],
                )),

            // SIP Configuration (only shown when enabled)
            Obx(() {
              if (!controller.sipEnabled.value) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16.0),

                  // Protocol Selection
                  Row(
                    children: [
                      const Text('Protocol: '),
                      const SizedBox(width: 8.0),
                      Obx(() => SegmentedButton<String>(
                            segments: const [
                              ButtonSegment<String>(
                                value: 'ws',
                                label: Text('ws (WebSocket)'),
                                icon: Icon(Icons.lock_open),
                              ),
                              ButtonSegment<String>(
                                value: 'wss',
                                label: Text('wss (Secure)'),
                                icon: Icon(Icons.lock),
                              ),
                            ],
                            selected: {controller.sipProtocol.value},
                            onSelectionChanged: (Set<String> selection) {
                              controller.setSipProtocol(selection.first);
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Server Host
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'SIP/Drachtio Server Host',
                      hintText: 'e.g., sip.example.com',
                      border: OutlineInputBorder(),
                    ),
                    controller: controller.sipServerHostController,
                    onChanged: (value) {
                      controller.saveSipServerHost(value);
                      if (controller.sipService != null) {
                        controller.sipService!.serverHost.value = value;
                        controller.sipService!.register();
                      }
                    },
                  ),
                  const SizedBox(height: 8.0),

                  // Device Name - Read-only, managed by MQTT settings
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'SIP Contact Name (from Device Name)',
                      border: OutlineInputBorder(),
                    ),
                    controller: controller.deviceNameController,
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 16.0),

                  // Media device selection
                  if (controller.sipService != null) ...[
                    Text(
                      'Media Devices',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8.0),

                    // Audio Input Devices
                    _buildAudioInputSelector(controller),
                    const SizedBox(height: 8.0),

                    // Video Input Devices
                    _buildVideoInputSelector(controller),
                    const SizedBox(height: 8.0),

                    // Audio Output Devices
                    _buildAudioOutputSelector(controller),
                    const SizedBox(height: 16.0),
                  ] else ...[
                    const Text('SIP Service not available'),
                    const SizedBox(height: 16.0),
                  ],

                  // Connection buttons
                  _buildConnectionButtons(controller),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioInputSelector(SettingsControllerFixed controller) {
    return Obx(() {
      final sipService = controller.sipService;
      if (sipService == null) return const SizedBox.shrink();

      final audioInputDevices = sipService.audioInputs;
      final selectedDevice = sipService.selectedAudioInput.value;

      if (audioInputDevices.isEmpty) {
        return const Text('No audio input devices found');
      }

      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Microphone',
          border: OutlineInputBorder(),
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
            sipService.setAudioInput(device);
          }
        },
      );
    });
  }

  Widget _buildVideoInputSelector(SettingsControllerFixed controller) {
    return Obx(() {
      final sipService = controller.sipService;
      if (sipService == null) return const SizedBox.shrink();

      final videoInputDevices = sipService.videoInputs;
      final selectedDevice = sipService.selectedVideoInput.value;

      if (videoInputDevices.isEmpty) {
        return const Text('No video input devices found');
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Camera',
              border: OutlineInputBorder(),
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
                sipService.setVideoInput(device);
              }
            },
          ),

          // Camera Preview Section
          const SizedBox(height: 16),
          if (selectedDevice != null)
            _buildCameraPreview(selectedDevice.deviceId),
        ],
      );
    });
  }

  Widget _buildCameraPreview(String deviceId) {
    if (deviceId.isEmpty) return const SizedBox();

    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Camera Preview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CameraPreviewWidget(
              deviceId: deviceId,
              width: double.infinity,
              height: 240,
            ),
          ),
        ],
      );
    } catch (e) {
      print('Error rendering camera preview: $e');
      return const Text('Camera preview not available');
    }
  }

  Widget _buildAudioOutputSelector(SettingsControllerFixed controller) {
    return Obx(() {
      final sipService = controller.sipService;
      if (sipService == null) return const SizedBox.shrink();

      final audioOutputDevices = sipService.audioOutputs;
      final selectedDevice = sipService.selectedAudioOutput.value;

      if (audioOutputDevices.isEmpty) {
        return const Text('No audio output devices found');
      }

      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Speaker',
          border: OutlineInputBorder(),
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
            sipService.setAudioOutput(device);
          }
        },
      );
    });
  }

  Widget _buildConnectionButtons(SettingsControllerFixed controller) {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.phone),
              label: const Text('Register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              onPressed: controller.sipRegistered.value
                  ? null
                  : () {
                      if (controller.sipService != null) {
                        controller.sipService!.register();
                      }
                    },
            ),
            const SizedBox(width: 16.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.phone_disabled),
              label: const Text('Unregister'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              onPressed: controller.sipRegistered.value
                  ? () {
                      if (controller.sipService != null) {
                        controller.sipService!.unregister();
                      }
                    }
                  : null,
            ),
            const SizedBox(width: 16.0),
            // Connection status indicator
            _buildConnectionIndicator(controller),
          ],
        ));
  }

  Widget _buildConnectionIndicator(SettingsControllerFixed controller) {
    return Obx(() {
      final registered = controller.sipRegistered.value;
      final protocol = controller.sipProtocol.value;
      return Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: registered ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8.0),
          Text(registered
              ? 'Registered ($protocol)'
              : 'Unregistered ($protocol)'),
        ],
      );
    });
  }
}
