import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller_compat.dart';

/// MQTT settings view with proper connection handling and sensor republishing
class MqttSettingsView extends GetView<SettingsController> {
  const MqttSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the globally registered controller
    final controller = Get.find<SettingsController>();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MQTT Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // Enable MQTT
            _buildMqttEnabledSwitch(controller),
            
            // MQTT Configuration (only shown when enabled)
            Obx(() {
              if (!controller.mqttEnabled.value) {
                return const SizedBox.shrink();
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16.0),
                  
                  // Broker URL
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'MQTT Broker URL',
                      hintText: 'e.g., broker.emqx.io',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: controller.mqttBrokerUrl.value,
                    onChanged: controller.saveMqttBrokerUrl,
                  ),
                  const SizedBox(height: 8.0),
                  
                  // Broker Port
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'MQTT Broker Port',
                      hintText: 'e.g., 1883',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: controller.mqttBrokerPort.value.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final port = int.tryParse(value) ?? 1883;
                      controller.saveMqttBrokerPort(port);
                    },
                  ),
                  const SizedBox(height: 8.0),
                  
                  // Username
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'MQTT Username',
                      hintText: 'MQTT username (if required)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: controller.mqttUsername.value,
                    onChanged: controller.saveMqttUsername,
                  ),
                  const SizedBox(height: 8.0),
                  
                  // Password
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'MQTT Password',
                      hintText: 'MQTT password (if required)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: controller.mqttPassword.value,
                    obscureText: true,
                    onChanged: controller.saveMqttPassword,
                  ),
                  const SizedBox(height: 8.0),
                  
                  // Device Name
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Device Name',
                      hintText: 'Name used for MQTT topics',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: controller.deviceName.value,
                    onChanged: controller.saveDeviceName,
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Home Assistant Discovery
                  _buildHomeAssistantSwitch(controller),
                  const SizedBox(height: 16.0),
                  
                  // Connection buttons
                  _buildConnectionButtons(controller),
                  
                  // Republish sensors button
                  _buildRepublishSensorsButton(controller),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMqttEnabledSwitch(SettingsController controller) {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Enable MQTT'),
        Switch(
          value: controller.mqttEnabled.value,
          onChanged: controller.toggleMqttEnabled,
        ),
      ],
    ));
  }
  
  Widget _buildHomeAssistantSwitch(SettingsController controller) {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Home Assistant Discovery'),
        Switch(
          value: controller.mqttHaDiscovery.value,
          onChanged: controller.toggleMqttHaDiscovery,
        ),
      ],
    ));
  }
  
  Widget _buildConnectionButtons(SettingsController controller) {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.link),
          label: const Text('Connect'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
          onPressed: controller.mqttConnected.value ? null : controller.connectMqtt,
        ),
        const SizedBox(width: 16.0),
        ElevatedButton.icon(
          icon: const Icon(Icons.link_off),
          label: const Text('Disconnect'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
          ),
          onPressed: controller.mqttConnected.value ? controller.disconnectMqtt : null,
        ),
        const SizedBox(width: 16.0),
        // Connection status indicator
        _buildConnectionIndicator(controller),
      ],
    ));
  }
  
  Widget _buildConnectionIndicator(SettingsController controller) {
    return Obx(() => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: controller.mqttConnected.value ? Colors.green : Colors.red,
      ),
    ));
  }
  
  Widget _buildRepublishSensorsButton(SettingsController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Obx(() => ElevatedButton.icon(
        icon: const Icon(Icons.refresh),
        label: const Text('Republish All Sensors'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        onPressed: controller.mqttConnected.value ? controller.forceRepublishSensors : null,
      )),
    );
  }
}
