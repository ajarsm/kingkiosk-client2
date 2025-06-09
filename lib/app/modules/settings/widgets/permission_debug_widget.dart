import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/permissions_manager.dart';

/// A debug widget to help diagnose permission issues
/// This can be temporarily added to settings to troubleshoot iOS permission problems
class PermissionDebugWidget extends StatefulWidget {
  const PermissionDebugWidget({Key? key}) : super(key: key);

  @override
  State<PermissionDebugWidget> createState() => _PermissionDebugWidgetState();
}

class _PermissionDebugWidgetState extends State<PermissionDebugWidget> {
  Map<String, String>? _debugStatuses;
  bool _isLoading = false;
  String _lastTestResult = '';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statuses = await PermissionsManager.debugPermissionStatuses();
      setState(() {
        _debugStatuses = statuses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugStatuses = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  Future<void> _testCameraPermission() async {
    setState(() => _isLoading = true);

    try {
      print('🐛 [DEBUG] Testing camera permission...');

      // Check initial status
      final initialStatuses =
          await PermissionsManager.debugPermissionStatuses();
      print('🐛 [DEBUG] Initial camera status: ${initialStatuses['Camera']}');

      final result = await PermissionsManager.requestCameraPermission();

      print('🐛 [DEBUG] Camera permission result:');
      print('  - granted: ${result.granted}');
      print('  - permanentlyDenied: ${result.permanentlyDenied}');
      print('  - status: ${result.status}');

      // Check final status
      final finalStatuses = await PermissionsManager.debugPermissionStatuses();
      print('🐛 [DEBUG] Final camera status: ${finalStatuses['Camera']}');

      setState(() {
        _lastTestResult = '''
Camera Test Results:
• Initial: ${initialStatuses['Camera']}
• Final: ${finalStatuses['Camera']}
• Granted: ${result.granted}
• Permanently Denied: ${result.permanentlyDenied}
• Status: ${result.status}

Expected: System dialog should appear on first request.
If no dialog appears and status goes to permanentlyDenied,
the app may have cached permission state.
        ''';
        _isLoading = false;
      });

      await _loadDebugInfo();
    } catch (e) {
      print('🐛 [DEBUG] Camera permission test error: $e');
      setState(() {
        _lastTestResult = 'Camera test error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testMicrophonePermission() async {
    setState(() => _isLoading = true);

    try {
      print('🐛 [DEBUG] Testing microphone permission...');

      final initialStatuses =
          await PermissionsManager.debugPermissionStatuses();
      print(
          '🐛 [DEBUG] Initial microphone status: ${initialStatuses['Microphone']}');

      final result = await PermissionsManager.requestMicrophonePermission();

      print('🐛 [DEBUG] Microphone permission result:');
      print('  - granted: ${result.granted}');
      print('  - permanentlyDenied: ${result.permanentlyDenied}');
      print('  - status: ${result.status}');

      final finalStatuses = await PermissionsManager.debugPermissionStatuses();
      print(
          '🐛 [DEBUG] Final microphone status: ${finalStatuses['Microphone']}');

      setState(() {
        _lastTestResult = '''
Microphone Test Results:
• Initial: ${initialStatuses['Microphone']}
• Final: ${finalStatuses['Microphone']}
• Granted: ${result.granted}
• Permanently Denied: ${result.permanentlyDenied}
• Status: ${result.status}
        ''';
        _isLoading = false;
      });

      await _loadDebugInfo();
    } catch (e) {
      print('🐛 [DEBUG] Microphone permission test error: $e');
      setState(() {
        _lastTestResult = 'Microphone test error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Permission Debug Info',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _loadDebugInfo,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Refresh permission status',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current Status
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_debugStatuses != null) ...[
              const Text(
                'Current Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _debugStatuses!.entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    '${entry.key}:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Test Buttons
              const Text(
                'Test Permissions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCameraPermission,
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Test Camera'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testMicrophonePermission,
                    icon: const Icon(Icons.mic, size: 16),
                    label: const Text('Test Mic'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await PermissionsManager.openAppSettings();
                    },
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Settings'),
                  ),
                ],
              ),

              // Test Results
              if (_lastTestResult.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Last Test Result:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: SelectableText(
                    _lastTestResult,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],

              // Instructions
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Troubleshooting:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Reset permissions: Run ./reset_ios_permissions.sh\n'
                      '• Check iOS Settings > Privacy & Security\n'
                      '• Watch for system permission dialogs\n'
                      '• Check Xcode console for detailed logs',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ] else
              const Text('No debug information available'),
          ],
        ),
      ),
    );
  }
}
