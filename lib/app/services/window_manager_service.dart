import 'package:get/get.dart';

/// Enum for window types
enum KioskWindowType { web, media, conferencing, custom }

/// Abstract base class for window controllers
abstract class KioskWindowController {
  String get windowName;
  KioskWindowType get windowType;
  void handleCommand(String action, Map<String, dynamic>? payload);
  void disposeWindow();
}

/// Service to manage all open windows and route commands
class WindowManagerService extends GetxService {
  // Map of window name to controller
  final Map<String, KioskWindowController> _windows = {};

  void registerWindow(KioskWindowController controller) {
    _windows[controller.windowName] = controller;
  }

  void unregisterWindow(String windowName) {
    _windows.remove(windowName);
  }

  KioskWindowController? getWindow(String windowName) => _windows[windowName];

  /// Called by MqttService when a command is received
  void handleWindowCommand(String windowName, String action, Map<String, dynamic>? payload) {
    final controller = _windows[windowName];
    if (controller != null) {
      controller.handleCommand(action, payload);
    } else {
      print('No window registered with name: $windowName');
    }
  }

  /// Called by MqttService or other sources when a command is received
  /// Now supports window_id in payload for more robust routing
  void handleWindowCommandWithId(String action, Map<String, dynamic>? payload) {
    final windowId = payload != null && payload['window_id'] is String
        ? payload['window_id'] as String
        : null;
    if (windowId != null && _windows.containsKey(windowId)) {
      _windows[windowId]?.handleCommand(action, payload);
    } else {
      print('No window registered with id: '
          '[33m$windowId[0m (action: $action)');
    }
  }

  /// For debugging: list all open windows
  List<String> get openWindowNames => _windows.keys.toList();
}
