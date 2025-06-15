import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/modules/settings/controllers/settings_controller_compat.dart';
import '../app/modules/settings/controllers/settings_controller.dart';

/// Test widget to verify auto-lock functionality
class AutoLockTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Ensure controllers are registered
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }
    if (!Get.isRegistered<SettingsControllerFixed>()) {
      Get.put(SettingsControllerFixed());
    }

    final settingsController = Get.find<SettingsController>();
    final settingsControllerFixed = Get.find<SettingsControllerFixed>();

    return Scaffold(
      appBar: AppBar(title: Text('Auto-Lock Test')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Auto-Lock Debug Info:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Obx(() => Text(
                'Auto-lock enabled: ${settingsControllerFixed.autoLockEnabled.value}')),
            Obx(() => Text(
                'Auto-lock timeout: ${settingsControllerFixed.autoLockTimeout.value} minutes')),
            Obx(() => Text(
                'Settings locked: ${settingsController.isSettingsLocked.value}')),
            SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    settingsControllerFixed.toggleAutoLockEnabled(
                        !settingsControllerFixed.autoLockEnabled.value);
                  },
                  child: Text('Toggle Auto-Lock'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    settingsControllerFixed
                        .setAutoLockTimeout(0.1); // 6 seconds for testing
                  },
                  child: Text('Set 0.1 min'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                settingsController.recordUserInteraction();
                print('✅ Manual interaction recorded');
              },
              child: Text('Record Interaction'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (settingsController.isSettingsLocked.value) {
                  settingsController.unlockSettings();
                } else {
                  settingsController.lockSettings();
                }
              },
              child: Obx(() => Text(settingsController.isSettingsLocked.value
                  ? 'Unlock'
                  : 'Lock')),
            ),
            SizedBox(height: 20),
            Text('Instructions:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('1. Enable auto-lock'),
            Text('2. Set timeout to 0.1 minutes (6 seconds)'),
            Text('3. Wait 6 seconds without touching screen'),
            Text('4. Should auto-lock and show notification'),
          ],
        ),
      ),
    );
  }
}
