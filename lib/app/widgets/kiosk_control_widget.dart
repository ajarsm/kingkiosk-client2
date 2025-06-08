import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:king_kiosk/app/services/android_kiosk_service.dart';

/// Demo widget showing how to integrate kiosk controls into your app
/// This can be added to settings or admin panels
class KioskControlWidget extends StatelessWidget {
  const KioskControlWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final kioskService = Get.find<AndroidKioskService>();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔒 Kiosk Mode Controls',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Status Display
            Obx(() => _buildStatusSection(kioskService)),
            const SizedBox(height: 24),

            // Main Controls
            _buildMainControls(kioskService),
            const SizedBox(height: 24),

            // Advanced Controls
            _buildAdvancedControls(kioskService),
            const SizedBox(height: 16),

            // Warning Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kiosk mode will lock this device. Ensure you have admin access to disable it.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(AndroidKioskService kioskService) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Status',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Kiosk Mode',
            kioskService.isKioskModeActive,
            kioskService.isKioskModeActive ? Colors.green : Colors.grey,
          ),
          _buildStatusRow(
            'Home Launcher',
            kioskService.isHomeAppSet,
            kioskService.isHomeAppSet ? Colors.blue : Colors.grey,
          ),
          _buildStatusRow(
            'System Permissions',
            kioskService.hasSystemPermissions,
            kioskService.hasSystemPermissions ? Colors.green : Colors.orange,
          ),
          if (kioskService.isRestoring)
            _buildStatusRow('Auto-Restoring', true, Colors.amber),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${status ? 'Active' : 'Inactive'}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControls(AndroidKioskService kioskService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Main Controls',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _enableKioskMode(kioskService),
                icon: const Icon(Icons.lock),
                label: const Text('Enable Kiosk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _disableKioskMode(kioskService),
                icon: const Icon(Icons.lock_open),
                label: const Text('Disable Kiosk'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _setupHomeLauncher(kioskService),
            icon: const Icon(Icons.home),
            label: const Text('Setup Home Launcher'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedControls(AndroidKioskService kioskService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Controls',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionChip(
              'Task Lock',
              Icons.screen_lock_portrait,
              () => _toggleTaskLock(kioskService),
            ),
            _buildActionChip(
              'Block Uninstall',
              Icons.security,
              () => _toggleUninstallProtection(kioskService),
            ),
            _buildActionChip(
              'Hide System UI',
              Icons.fullscreen,
              () => kioskService.hideSystemUI(),
            ),
            _buildActionChip(
              'Device Status',
              Icons.info,
              () => _showDeviceStatus(kioskService),
            ),
            _buildActionChip(
              'Force Cleanup',
              Icons.cleaning_services,
              () => _forceCleanupKioskState(kioskService),
              color: Colors.orange,
            ),
            _buildActionChip(
              'State Info',
              Icons.storage,
              () => _showKioskStateInfo(kioskService),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(
    String label,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color?.withOpacity(0.1) ?? Colors.blue.shade50,
      side: BorderSide(color: color?.withOpacity(0.3) ?? Colors.blue.shade200),
    );
  }

  // Action Methods
  void _enableKioskMode(AndroidKioskService kioskService) async {
    Get.dialog(
      AlertDialog(
        title: const Text('⚠️ Enable Kiosk Mode'),
        content: const Text(
          'This will lock the device and make King Kiosk the home launcher. '
          'Make sure you have admin access to disable it later.\n\n'
          'The device will require device administrator permissions and '
          'may restart the launcher selection process.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              _showLoadingDialog('Enabling kiosk mode...');

              bool success = await kioskService.enableKioskMode();

              Get.back(); // Close loading dialog

              Get.snackbar(
                success ? '✅ Success' : '❌ Failed',
                success
                    ? 'Kiosk mode enabled successfully'
                    : 'Failed to enable kiosk mode. Check permissions.',
                backgroundColor: success ? Colors.green : Colors.red,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _disableKioskMode(AndroidKioskService kioskService) async {
    _showLoadingDialog('Disabling kiosk mode...');

    bool success = await kioskService.disableKioskMode();

    Get.back(); // Close loading dialog

    Get.snackbar(
      success ? '✅ Success' : '❌ Failed',
      success
          ? 'Kiosk mode disabled successfully'
          : 'Failed to disable kiosk mode',
      backgroundColor: success ? Colors.green : Colors.red,
      colorText: Colors.white,
    );
  }

  void _setupHomeLauncher(AndroidKioskService kioskService) async {
    Get.dialog(
      AlertDialog(
        title: const Text('🏠 Setup Home Launcher'),
        content: const Text(
          'This will open Android settings to configure King Kiosk as '
          'the default home launcher. Please select "King Kiosk" and '
          'tap "Always" when prompted.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await kioskService.forceSetAsHomeLauncher();

              Get.snackbar(
                '📱 Launcher Settings',
                'Please select King Kiosk as your home app',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _toggleTaskLock(AndroidKioskService kioskService) async {
    bool isLocked = await kioskService.isTaskLocked();

    if (isLocked) {
      await kioskService.disableTaskLock();
      Get.snackbar('🔓 Task Lock', 'Screen pinning disabled');
    } else {
      await kioskService.enableTaskLock();
      Get.snackbar('📌 Task Lock', 'Screen pinning enabled');
    }
  }

  void _toggleUninstallProtection(AndroidKioskService kioskService) async {
    // This is a simplified toggle - in practice you'd check current state
    bool success = await kioskService.preventAppUninstall();

    Get.snackbar(
      success ? '🛡️ Protected' : '❌ Failed',
      success
          ? 'App uninstall blocked'
          : 'Device admin required for uninstall protection',
      backgroundColor: success ? Colors.green : Colors.orange,
      colorText: Colors.white,
    );
  }

  void _showDeviceStatus(AndroidKioskService kioskService) async {
    _showLoadingDialog('Checking device status...');

    Map<String, bool> status = await kioskService.getKioskStatus();

    Get.back(); // Close loading dialog

    Get.dialog(
      AlertDialog(
        title: const Text('📊 Device Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusItem('Kiosk Active', status['isKioskActive'] ?? false),
            _buildStatusItem('Home App', status['isHomeApp'] ?? false),
            _buildStatusItem('Device Admin', status['hasDeviceAdmin'] ?? false),
            _buildStatusItem('Task Locked', status['isTaskLocked'] ?? false),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text('$label: ${status ? 'Yes' : 'No'}'),
        ],
      ),
    );
  }

  void _showLoadingDialog(String message) {
    Get.dialog(
      AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _forceCleanupKioskState(AndroidKioskService kioskService) async {
    Get.dialog(
      AlertDialog(
        title: const Text('⚠️ Force Cleanup Kiosk State'),
        content: const Text(
          'This will forcefully clear all kiosk state and restrictions. '
          'Use this if kiosk mode is stuck or partially disabled.\n\n'
          'This action will:\n'
          '• Clear all persistent kiosk settings\n'
          '• Release all system restrictions\n'
          '• Reset the app to normal mode\n'
          '• Clear launcher preferences',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              _showLoadingDialog('Force cleaning up kiosk state...');

              bool success = await kioskService.forceCleanupKioskState();

              Get.back(); // Close loading dialog

              Get.snackbar(
                success ? '✅ Success' : '❌ Failed',
                success
                    ? 'Kiosk state force cleanup completed'
                    : 'Failed to cleanup kiosk state',
                backgroundColor: success ? Colors.green : Colors.red,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Force Cleanup'),
          ),
        ],
      ),
    );
  }

  void _showKioskStateInfo(AndroidKioskService kioskService) async {
    Map<String, dynamic> stateInfo = kioskService.getKioskStateInfo();

    Get.dialog(
      AlertDialog(
        title: const Text('📊 Kiosk State Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current State:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInfoItem(
                'Persistent Kiosk Enabled',
                stateInfo['persistentKioskEnabled'],
              ),
              _buildInfoItem(
                'Current Kiosk Active',
                stateInfo['currentKioskActive'],
              ),
              _buildInfoItem('Is Home App', stateInfo['isHomeApp']),
              _buildInfoItem('Has Permissions', stateInfo['hasPermissions']),
              _buildInfoItem('Is Restoring', stateInfo['isRestoring']),

              const SizedBox(height: 16),
              Text(
                'Configuration:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stateInfo['config'].isEmpty
                      ? 'No configuration saved'
                      : stateInfo['config'].toString(),
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, dynamic value) {
    Color color = Colors.grey;
    IconData icon = Icons.help;

    if (value is bool) {
      color = value ? Colors.green : Colors.red;
      icon = value ? Icons.check_circle : Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ${value.toString()}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
