import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/platform_kiosk_service.dart';

/// Universal kiosk control widget that works across all platforms
/// Shows platform-specific capabilities and controls
class UniversalKioskWidget extends StatelessWidget {
  const UniversalKioskWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlatformKioskService>(
      init: PlatformKioskService(),
      builder: (service) {
        return Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform header
                Row(
                  children: [
                    Icon(_getPlatformIcon(),
                        size: 32, color: _getPlatformColor()),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${service.platformName} Kiosk Mode',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${service.controlLevel}% Control (${service.controlLevelDescription})',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Control level indicator
                LinearProgressIndicator(
                  value: service.controlLevel / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _getControlColor(service.controlLevel)),
                ),
                SizedBox(height: 16),

                // Status
                Obx(() => Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: service.isKioskModeActive
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.isKioskModeActive
                            ? '🔒 Kiosk Mode Active'
                            : '🔓 Kiosk Mode Inactive',
                        style: TextStyle(
                          color: service.isKioskModeActive
                              ? Colors.green[800]
                              : Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )),
                SizedBox(height: 16),

                // Platform-specific status details
                _buildPlatformStatus(service),
                SizedBox(height: 16),

                // Control buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: service.isKioskModeActive
                            ? null
                            : () => service.enableKioskMode(),
                        icon: Icon(Icons.lock),
                        label: Text('Enable Kiosk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: service.isKioskModeActive
                            ? () => service.disableKioskMode()
                            : null,
                        icon: Icon(Icons.lock_open),
                        label: Text('Disable Kiosk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Info button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => service.showSetupInstructions(),
                    icon: Icon(Icons.info_outline),
                    label: Text('Platform Info & Setup'),
                  ),
                ),

                // Platform-specific additional controls
                _buildPlatformSpecificControls(service),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getPlatformIcon() {
    if (Platform.isAndroid) return Icons.android;
    if (Platform.isWindows) return Icons.desktop_windows;
    if (Platform.isMacOS) return Icons.desktop_mac;
    if (Platform.isIOS) return Icons.phone_iphone;
    return Icons.device_unknown;
  }

  Color _getPlatformColor() {
    if (Platform.isAndroid) return Colors.green;
    if (Platform.isWindows) return Colors.blue;
    if (Platform.isMacOS) return Colors.grey;
    if (Platform.isIOS) return Colors.blue;
    return Colors.grey;
  }

  Color _getControlColor(int level) {
    if (level >= 90) return Colors.green;
    if (level >= 70) return Colors.lightGreen;
    if (level >= 50) return Colors.orange;
    if (level >= 30) return Colors.deepOrange;
    return Colors.red;
  }

  Widget _buildPlatformStatus(PlatformKioskService service) {
    if (Platform.isAndroid) {
      return _buildAndroidStatus(service);
    } else if (Platform.isWindows) {
      return _buildWindowsStatus(service);
    } else if (Platform.isMacOS) {
      return _buildMacOSStatus(service);
    } else if (Platform.isIOS) {
      return _buildIOSStatus(service);
    }
    return SizedBox.shrink();
  }

  Widget _buildAndroidStatus(PlatformKioskService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Android Status:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        _buildStatusItem(
            'Home Launcher', true, 'App can become default launcher'),
        _buildStatusItem(
            'System UI Hidden', true, 'Navigation and status bars hidden'),
        _buildStatusItem(
            'Hardware Buttons', true, 'Home, back, recent buttons blocked'),
        _buildStatusItem(
            'Device Admin', true, 'System-level restrictions active'),
      ],
    );
  }

  Widget _buildWindowsStatus(PlatformKioskService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Windows Status:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        _buildStatusItem('Fullscreen', true, 'App in fullscreen mode'),
        _buildStatusItem(
            'Taskbar Hidden', false, 'Taskbar hiding (requires admin)'),
        _buildStatusItem(
            'Shortcuts Blocked', false, 'Alt+Tab, Win key blocked'),
        _buildStatusItem('Task Manager', false, 'Task Manager disabled'),
      ],
    );
  }

  Widget _buildMacOSStatus(PlatformKioskService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('macOS Status:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        _buildStatusItem('Fullscreen', true, 'App in fullscreen mode'),
        _buildStatusItem('Dock Hidden', false, 'Dock hiding active'),
        _buildStatusItem('Menu Bar Hidden', false, 'Menu bar hidden'),
        _buildStatusItem('Shortcuts Limited', false, 'Some shortcuts blocked'),
      ],
    );
  }

  Widget _buildIOSStatus(PlatformKioskService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('iOS Status:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        _buildStatusItem('Fullscreen', true, 'App in fullscreen mode'),
        _buildStatusItem('Status Bar Hidden', true, 'Status bar hidden'),
        _buildStatusItem('Guided Access', false, 'User must enable manually'),
        Text(
          'Note: iOS requires manual Guided Access activation for full kiosk mode.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange[700],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(String label, bool active, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: active ? Colors.green : Colors.red,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSpecificControls(PlatformKioskService service) {
    if (Platform.isIOS) {
      return Column(
        children: [
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Show iOS Guided Access instructions
                Get.dialog(
                  AlertDialog(
                    title: Text('Enable Guided Access'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('To enable full kiosk mode on iOS:'),
                        SizedBox(height: 12),
                        Text(
                            '1. Go to Settings > Accessibility > Guided Access'),
                        Text('2. Turn on Guided Access'),
                        Text('3. Set a passcode'),
                        Text('4. Return to this app'),
                        Text('5. Triple-click the Home/Side button'),
                        Text('6. Tap "Start"'),
                        SizedBox(height: 12),
                        Text('This will lock the device to this app only.'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.accessibility),
              label: Text('Setup Guided Access'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox.shrink();
  }
}
