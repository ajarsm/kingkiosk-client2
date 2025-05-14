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

  /// For debugging: list all open windows
  List<String> get openWindowNames => _windows.keys.toList();
}
