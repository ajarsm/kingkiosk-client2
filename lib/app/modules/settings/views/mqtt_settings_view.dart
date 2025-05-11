import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class MqttSettingsView extends GetView<SettingsController> {
  const MqttSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_outlined),
                SizedBox(width: 8),
                Text(
                  'MQTT Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            // Enable MQTT
            _buildMqttEnabledSwitch(),
            
            // MQTT Configuration (only shown when enabled)
            Obx(() {
              if (!controller.mqttEnabled.value) {
                return SizedBox.shrink();
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  _buildTextField(
                    label: 'Broker URL',
                    hint: 'e.g. broker.emqx.io',
                    initialValue: controller.mqttBrokerUrl.value,
                    onChanged: controller.saveMqttBrokerUrl,
                  ),
                  SizedBox(height: 8),
                  _buildPortTextField(
                    label: 'Broker Port',
                    hint: '1883',
                    initialValue: controller.mqttBrokerPort.value.toString(),
                    onChanged: (value) {
                      final port = int.tryParse(value) ?? 1883;
                      controller.saveMqttBrokerPort(port);
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Authentication (optional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildTextField(
                    label: 'Username',
                    hint: 'MQTT username (if required)',
                    initialValue: controller.mqttUsername.value,
                    onChanged: controller.saveMqttUsername,
                  ),
                  SizedBox(height: 8),
                  _buildPasswordTextField(
                    label: 'Password',
                    hint: 'MQTT password (if required)',
                    initialValue: controller.mqttPassword.value,
                    onChanged: controller.saveMqttPassword,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    label: 'Device Name',
                    hint: 'Unique identifier for this device',
                    initialValue: controller.deviceName.value,
                    onChanged: controller.saveDeviceName,
                  ),
                  SizedBox(height: 16),
                  // Home Assistant Auto-Discovery
                  _buildHaDiscoverySwitch(),
                  SizedBox(height: 16),
                  // Connect/Disconnect Button
                  _buildConnectionButton(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMqttEnabledSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Enable MQTT'),
        Obx(() => Switch(
          value: controller.mqttEnabled.value,
          onChanged: controller.toggleMqttEnabled,
        )),
      ],
    );
  }
  
  Widget _buildHaDiscoverySwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Home Assistant Auto-Discovery'),
            Text(
              'Publish sensors to Home Assistant',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        Obx(() => Switch(
          value: controller.mqttHaDiscovery.value,
          onChanged: controller.toggleMqttHaDiscovery,
        )),
      ],
    );
  }
  
  Widget _buildTextField({
    required String label,
    required String hint,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
  
  Widget _buildPortTextField({
    required String label,
    required String hint,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }
  
  Widget _buildPasswordTextField({
    required String label,
    required String hint,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(),
      ),
      obscureText: true,
      onChanged: onChanged,
    );
  }
  
  Widget _buildConnectionButton() {
    return Obx(() {
      final isConnected = controller.mqttConnected.value;
      
      return ElevatedButton.icon(
        onPressed: isConnected 
            ? controller.disconnectMqtt 
            : controller.connectMqtt,
        icon: Icon(isConnected ? Icons.link_off : Icons.link),
        label: Text(isConnected ? 'Disconnect' : 'Connect'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 48),
        ),
      );
    });
  }
}