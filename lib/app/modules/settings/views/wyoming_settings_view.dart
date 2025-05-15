import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/wyoming_settings_controller.dart';

class WyomingSettingsView extends StatelessWidget {
  final WyomingSettingsController controller = Get.put(WyomingSettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wyoming Satellite Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => SwitchListTile(
                  title: Text('Enable Wyoming Satellite'),
                  value: controller.enabled.value,
                  onChanged: (val) => controller.enabled.value = val,
                )),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Server IP/Host'),
              controller: controller.hostController,
              onChanged: (val) => controller.host.value = val,
              textDirection: TextDirection.ltr,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Port'),
              keyboardType: TextInputType.number,
              controller: controller.portController,
              onChanged: (val) => controller.port.value = int.tryParse(val) ?? 10300,
              textDirection: TextDirection.ltr,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.saveSettings,
              child: Text('Save'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.announceDiscovery,
              child: Text('Announce Wyoming Discovery'),
            ),
            Obx(() {
              final status = controller.discoveryStatus.value;
              final time = controller.lastDiscoveryTime.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (status.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: status.contains('success') ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (time != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Last published: '
                        '${time.hour.toString().padLeft(2, '0')}:''${time.minute.toString().padLeft(2, '0')}:''${time.second.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                ],
              );
            }),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.setAdvancedConfig(
                controller.host.value,
                controller.port.value,
                controller.enabled.value,
              ),
              child: Text('Apply Advanced Config'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.removeDiscovery,
              child: Text('Remove Discovery Config'),
            ),
          ],
        ),
      ),
    );
  }
}
