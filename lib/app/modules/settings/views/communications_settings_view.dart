import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller_compat.dart';

/// Communications settings view for SIP/Drachtio server configuration
class CommunicationsSettingsView extends StatelessWidget {
  const CommunicationsSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsControllerFixed>();
    return Obx(() => Card(
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
                Row(
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
                ),

                // SIP Configuration (only shown when enabled)
                if (!controller.sipEnabled.value)
                  const SizedBox.shrink()
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16.0),

                      // Protocol Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Protocol: '),
                          const SizedBox(height: 8.0),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<String>(
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
                                ),
                              );
                            },
                          ),
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

                      // Connection buttons
                      _buildConnectionButtons(controller),
                    ],
                  ),
              ],
            ),
          ),
        ));
  }

  Widget _buildConnectionButtons(SettingsControllerFixed controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 500;

        if (isSmallScreen) {
          // On small screens, stack buttons vertically
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
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
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: ElevatedButton.icon(
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
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              _buildConnectionIndicator(controller),
            ],
          );
        } else {
          // On larger screens, use horizontal layout
          return Row(
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
              _buildConnectionIndicator(controller),
            ],
          );
        }
      },
    );
  }

  Widget _buildConnectionIndicator(SettingsControllerFixed controller) {
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
        Text(
            registered ? 'Registered ($protocol)' : 'Unregistered ($protocol)'),
      ],
    );
  }
}
