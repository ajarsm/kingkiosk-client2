import 'package:get/get.dart';
import '../../../services/window_manager_service.dart';

/// Clock display modes
enum ClockMode { analog, digital }

/// Clock window controller for handling clock widgets
class ClockWindowController extends GetxController
    implements KioskWindowController {
  final String windowName;

  // Reactive properties
  final _clockMode = ClockMode.analog.obs;
  final _isVisible = true.obs;
  final _isMinimized = false.obs;
  final _networkImageUrl = RxnString(); // Network image URL for background
  final _showNumbers = true.obs; // Show numbers on analog clock
  final _showSecondHand = true.obs; // Show second hand on analog clock
  final _theme = 'auto'.obs; // Theme: 'auto', 'light', 'dark'

  // Clock configuration
  ClockMode get clockMode => _clockMode.value;
  bool get isVisible => _isVisible.value;
  bool get isMinimized => _isMinimized.value;
  String? get networkImageUrl => _networkImageUrl.value;
  bool get showNumbers => _showNumbers.value;
  bool get showSecondHand => _showSecondHand.value;
  String get theme => _theme.value;

  ClockWindowController({required this.windowName});

  @override
  KioskWindowType get windowType => KioskWindowType.custom;

  @override
  void onInit() {
    super.onInit();
    // Register this controller with the window manager
    Get.find<WindowManagerService>().registerWindow(this);
    print('Clock window controller initialized for: $windowName');
  }

  @override
  void onClose() {
    disposeWindow();
    super.onClose();
  }

  @override
  void handleCommand(String action, Map<String, dynamic>? payload) {
    print('Clock window received command: $action with payload: $payload');

    switch (action) {
      case 'minimize':
        minimize();
        break;
      case 'maximize':
      case 'restore':
        maximize();
        break;
      case 'close':
        close();
        break;
      case 'configure':
        configure(payload ?? {});
        break;
      case 'set_mode':
        final mode = payload?['mode'] as String?;
        if (mode != null) {
          setClockMode(mode);
        }
        break;
      default:
        print('Unknown command for clock window: $action');
    }
  }

  @override
  void disposeWindow() {
    try {
      Get.find<WindowManagerService>().unregisterWindow(windowName);
      print('Clock window disposed: $windowName');
    } catch (e) {
      print('Error disposing clock window: $e');
    }
  }

  /// Set the clock display mode
  void setClockMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'analog':
        _clockMode.value = ClockMode.analog;
        print('Clock mode set to analog for window: $windowName');
        break;
      case 'digital':
        _clockMode.value = ClockMode.digital;
        print('Clock mode set to digital for window: $windowName');
        break;
      default:
        print('Unknown clock mode: $mode');
    }
  }

  /// Configure clock settings
  void configure(Map<String, dynamic> config) {
    // Handle clock mode
    final mode = config['mode'] as String?;
    if (mode != null) {
      setClockMode(mode);
    }

    // Handle network image URL
    final imageUrl = config['image_url'] as String?;
    if (imageUrl != null) {
      _networkImageUrl.value = imageUrl;
      print(
          'Clock network image URL set to: $imageUrl for window: $windowName');
    }

    // Handle show numbers configuration
    final showNums = config['show_numbers'];
    if (showNums != null) {
      _showNumbers.value =
          showNums == true || showNums.toString().toLowerCase() == 'true';
      print(
          'Clock show numbers set to: ${_showNumbers.value} for window: $windowName');
    }

    // Handle show second hand configuration
    final showSecond = config['show_second_hand'];
    if (showSecond != null) {
      _showSecondHand.value =
          showSecond == true || showSecond.toString().toLowerCase() == 'true';
      print(
          'Clock show second hand set to: ${_showSecondHand.value} for window: $windowName');
    }

    // Handle theme configuration
    final themeStr = config['theme'] as String?;
    if (themeStr != null) {
      _theme.value = themeStr;
      print('Clock theme set to: $themeStr for window: $windowName');
    }

    // Handle visibility
    final visible = config['visible'] as bool?;
    if (visible != null) {
      _isVisible.value = visible;
    }

    print('Clock configured for window $windowName: $config');
  }

  /// Minimize the clock window
  void minimize() {
    _isMinimized.value = true;
    _isVisible.value = false;
    print('Clock window minimized: $windowName');
  }

  /// Maximize/restore the clock window
  void maximize() {
    _isMinimized.value = false;
    _isVisible.value = true;
    print('Clock window maximized: $windowName');
  }

  /// Close the clock window
  void close() {
    _isVisible.value = false;
    disposeWindow();
    // Note: The actual window removal should be handled by the parent container
    print('Clock window closed: $windowName');
  }

  /// Toggle between analog and digital modes
  void toggleMode() {
    _clockMode.value =
        clockMode == ClockMode.analog ? ClockMode.digital : ClockMode.analog;
    final modeString = clockMode == ClockMode.analog ? 'analog' : 'digital';
    print('Clock mode toggled to $modeString for window: $windowName');
  }
}
