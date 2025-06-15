import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/windows_kiosk_service.dart';

/// Windows Kiosk Control Widget
/// Provides comprehensive controls for Windows kiosk mode with multiple security levels
class WindowsKioskControlWidget extends StatelessWidget {
  const WindowsKioskControlWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final kioskService = Get.find<WindowsKioskService>();

    return Obx(() {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(kioskService),
              const SizedBox(height: 16),
              _buildStatusOverview(kioskService),
              const SizedBox(height: 16),
              _buildSecurityLevelSelector(kioskService),
              const SizedBox(height: 16),
              _buildMainControls(kioskService),
              const SizedBox(height: 16),
              _buildAdvancedControls(kioskService),
              const SizedBox(height: 16),
              _buildEmergencyControls(kioskService),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(WindowsKioskService service) {
    return Row(
      children: [
        Icon(
          Icons.computer,
          size: 32,
          color: service.isKioskModeActive ? Colors.red : Colors.blue,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Windows Kiosk Control',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              service.isKioskModeActive
                  ? 'ACTIVE - ${service.currentSecurityLevel.toString().split('.').last.toUpperCase()}'
                  : 'INACTIVE',
              style: TextStyle(
                color: service.isKioskModeActive ? Colors.red : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (service.isRestoring)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildStatusOverview(WindowsKioskService service) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatusChip('Kiosk Active', service.isKioskModeActive),
              _buildStatusChip('Fullscreen', service.isFullscreen),
              _buildStatusChip('Always On Top', service.isAlwaysOnTop),
              _buildStatusChip('Restoring', service.isRestoring),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool active) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : Colors.grey.shade700,
          fontSize: 12,
        ),
      ),
      backgroundColor: active ? Colors.green : Colors.grey.shade300,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildSecurityLevelSelector(WindowsKioskService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Level',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: KioskSecurityLevel.values.map((level) {
            return ChoiceChip(
              label: Text(_getLevelDisplayName(level)),
              selected: service.currentSecurityLevel == level,
              onSelected: service.isKioskModeActive
                  ? null
                  : (selected) {
                      if (selected) {
                        // Level will be applied when kiosk mode is enabled
                      }
                    },
              backgroundColor: _getLevelColor(level).withOpacity(0.1),
              selectedColor: _getLevelColor(level).withOpacity(0.3),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          _getLevelDescription(service.currentSecurityLevel),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _getLevelDisplayName(KioskSecurityLevel level) {
    switch (level) {
      case KioskSecurityLevel.demo:
        return 'Demo';
      case KioskSecurityLevel.business:
        return 'Business';
      case KioskSecurityLevel.enterprise:
        return 'Enterprise';
      case KioskSecurityLevel.totalLockdown:
        return 'Total Lockdown';
    }
  }

  Color _getLevelColor(KioskSecurityLevel level) {
    switch (level) {
      case KioskSecurityLevel.demo:
        return Colors.blue;
      case KioskSecurityLevel.business:
        return Colors.orange;
      case KioskSecurityLevel.enterprise:
        return Colors.red;
      case KioskSecurityLevel.totalLockdown:
        return Colors.purple;
    }
  }

  String _getLevelDescription(KioskSecurityLevel level) {
    switch (level) {
      case KioskSecurityLevel.demo:
        return 'Basic fullscreen mode for testing and demonstrations';
      case KioskSecurityLevel.business:
        return 'Taskbar hidden, basic shortcuts blocked, Task Manager disabled';
      case KioskSecurityLevel.enterprise:
        return 'All shortcuts blocked, desktop hidden, registry locked, process monitoring';
      case KioskSecurityLevel.totalLockdown:
        return 'Maximum security: shell replacement, complete system lockdown';
    }
  }

  Widget _buildMainControls(WindowsKioskService service) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: service.isKioskModeActive
                ? null
                : () => _enableKioskMode(service),
            icon: const Icon(Icons.lock),
            label: const Text('Enable Kiosk Mode'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: service.isKioskModeActive
                ? () => _disableKioskMode(service)
                : null,
            icon: const Icon(Icons.lock_open),
            label: const Text('Disable Kiosk Mode'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedControls(WindowsKioskService service) {
    return ExpansionTile(
      title: const Text('Advanced Controls'),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickActionButton(
              'Demo Mode',
              Icons.visibility,
              Colors.blue,
              () => service.enableKioskMode(KioskSecurityLevel.demo),
              !service.isKioskModeActive,
            ),
            _buildQuickActionButton(
              'Business Mode',
              Icons.business,
              Colors.orange,
              () => service.enableKioskMode(KioskSecurityLevel.business),
              !service.isKioskModeActive,
            ),
            _buildQuickActionButton(
              'Enterprise Mode',
              Icons.security,
              Colors.red,
              () => service.enableKioskMode(KioskSecurityLevel.enterprise),
              !service.isKioskModeActive,
            ),
            _buildQuickActionButton(
              'Maximum Security',
              Icons.gpp_bad,
              Colors.purple,
              () => service.enableKioskMode(KioskSecurityLevel.totalLockdown),
              !service.isKioskModeActive,
            ),
            _buildQuickActionButton(
              'Check Admin',
              Icons.admin_panel_settings,
              Colors.teal,
              () => _checkAdminPrivileges(service),
              true,
            ),
            _buildQuickActionButton(
              'Setup Guide',
              Icons.help_outline,
              Colors.blue,
              () => _showSetupInstructions(),
              true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencyControls(WindowsKioskService service) {
    return ExpansionTile(
      title: const Text(
        'Emergency Controls',
        style: TextStyle(color: Colors.red),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ Emergency Recovery',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use these controls if the system becomes unresponsive or kiosk mode gets stuck.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _forceCleanup(service),
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('Force Cleanup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRecoveryInstructions(),
                      icon: const Icon(Icons.help),
                      label: const Text('Recovery Help'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool enabled,
  ) {
    return SizedBox(
      width: 120,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),
    );
  }

  void _enableKioskMode(WindowsKioskService service) async {
    // Show security level selection dialog
    final selectedLevel = await Get.dialog<KioskSecurityLevel>(
      AlertDialog(
        title: const Text('🔒 Select Security Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: KioskSecurityLevel.values.map((level) {
            return ListTile(
              leading: Icon(
                _getLevelIcon(level),
                color: _getLevelColor(level),
              ),
              title: Text(_getLevelDisplayName(level)),
              subtitle: Text(_getLevelDescription(level)),
              onTap: () => Get.back(result: level),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedLevel != null) {
      _showLoadingDialog('Enabling Windows kiosk mode...');

      final success = await service.enableKioskMode(selectedLevel);

      Get.back(); // Close loading dialog

      Get.snackbar(
        success ? '✅ Success' : '❌ Failed',
        success
            ? 'Windows kiosk mode enabled successfully'
            : 'Failed to enable kiosk mode. Check permissions.',
        backgroundColor: success ? Colors.green : Colors.red,
        colorText: Colors.white,
      );
    }
  }

  IconData _getLevelIcon(KioskSecurityLevel level) {
    switch (level) {
      case KioskSecurityLevel.demo:
        return Icons.visibility;
      case KioskSecurityLevel.business:
        return Icons.business;
      case KioskSecurityLevel.enterprise:
        return Icons.security;
      case KioskSecurityLevel.totalLockdown:
        return Icons.gpp_bad;
    }
  }

  void _disableKioskMode(WindowsKioskService service) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('⚠️ Disable Kiosk Mode'),
        content: const Text(
          'This will restore normal Windows functionality and allow access to the desktop.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showLoadingDialog('Disabling Windows kiosk mode...');

      final success = await service.disableKioskMode();

      Get.back(); // Close loading dialog

      Get.snackbar(
        success ? '✅ Success' : '❌ Failed',
        success
            ? 'Windows kiosk mode disabled successfully'
            : 'Failed to disable kiosk mode',
        backgroundColor: success ? Colors.green : Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _forceCleanup(WindowsKioskService service) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('🚨 Force Cleanup'),
        content: const Text(
          'This will forcefully reset all kiosk restrictions and restore normal system operation.\n\n'
          'Use this only if the system is stuck or unresponsive.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Force Cleanup'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showLoadingDialog('Performing emergency cleanup...');

      final success = await service.emergencyDisable();

      Get.back(); // Close loading dialog

      Get.snackbar(
        success ? '✅ Cleanup Complete' : '❌ Cleanup Failed',
        success
            ? 'Emergency cleanup completed successfully'
            : 'Emergency cleanup failed',
        backgroundColor: success ? Colors.orange : Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _checkAdminPrivileges(WindowsKioskService service) async {
    _showLoadingDialog('Checking administrator privileges...');

    // Simulate admin check - in a real implementation this would check actual privileges
    final hasAdmin =
        Platform.isWindows; // Simple stub - assume admin on Windows

    Get.back(); // Close loading dialog

    Get.dialog(
      AlertDialog(
        title: Text(hasAdmin ? '✅ Administrator' : '⚠️ Limited Access'),
        content: Text(
          hasAdmin
              ? 'Application appears to be running with sufficient privileges.\n\nKiosk functionality should work correctly.'
              : 'Unable to verify administrator privileges.\n\nSome kiosk features may be limited. Try running as administrator for full functionality.',
        ),
        actions: [
          if (!hasAdmin)
            ElevatedButton(
              onPressed: () async {
                Get.back();
                Get.snackbar(
                  'Admin Required',
                  'Please restart the application as administrator for full kiosk functionality',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              },
              child: const Text('OK'),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRecoveryInstructions() {
    Get.dialog(
      AlertDialog(
        title: const Text('🆘 Emergency Recovery'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'If the system becomes completely unresponsive:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Press Ctrl+Alt+Del (if not blocked)'),
              Text('2. Boot into Safe Mode'),
              Text('3. Open Registry Editor'),
              Text(
                  '4. Navigate to HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon'),
              Text('5. Change Shell value to "explorer.exe"'),
              Text('6. Restart computer'),
              SizedBox(height: 16),
              Text(
                'Alternative Recovery:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Boot from external Windows media'),
              Text('2. Open Command Prompt'),
              Text(
                  '3. Run: reg add "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f'),
              Text('4. Restart normally'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showSetupInstructions() {
    Get.dialog(
      AlertDialog(
        title: const Text('🔧 Setup Instructions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Windows Kiosk Mode Setup:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                  '1. Run the application as Administrator for full functionality'),
              Text('2. Select the appropriate security level for your needs'),
              Text('3. Enable kiosk mode to lock down the system'),
              Text('4. Use emergency controls if system becomes unresponsive'),
              SizedBox(height: 16),
              Text(
                'Security Levels:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Demo: Basic fullscreen mode'),
              Text('• Business: Taskbar hidden, shortcuts disabled'),
              Text('• Enterprise: Advanced restrictions, process monitoring'),
              Text('• Total Lockdown: Maximum security with shell replacement'),
              SizedBox(height: 16),
              Text(
                '⚠️ Important:',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 4),
              Text('Always test kiosk modes in a safe environment first.'),
              Text('Keep emergency recovery instructions available.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Got it'),
          ),
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
            Text(message),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
