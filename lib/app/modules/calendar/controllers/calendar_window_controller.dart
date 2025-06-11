import 'package:get/get.dart';
import '../../../services/window_manager_service.dart';
import '../controllers/calendar_controller.dart';

/// Calendar Window Controller for managing calendar as a floating window
/// Follows the standard KioskWindowController pattern like other widgets
class CalendarWindowController extends GetxController
    implements KioskWindowController {
  final String windowName;

  // Window state
  final RxBool isWindowVisible = false.obs;
  final RxDouble windowWidth = 400.0.obs;
  final RxDouble windowHeight = 500.0.obs;
  final RxDouble windowX = 100.0.obs;
  final RxDouble windowY = 100.0.obs;

  // Reference to the main calendar controller
  CalendarController? _calendarController;

  CalendarWindowController({this.windowName = 'calendar'});

  @override
  KioskWindowType get windowType => KioskWindowType.custom;

  CalendarController get calendarController {
    if (_calendarController == null) {
      try {
        _calendarController = Get.find<CalendarController>();
      } catch (e) {
        print('⚠️ CalendarController not found, creating new instance: $e');
        _calendarController = Get.put(CalendarController(), permanent: true);
      }
    }
    return _calendarController!;
  }

  @override
  void onInit() {
    super.onInit();

    try {
      // Ensure calendar controller is registered
      if (!Get.isRegistered<CalendarController>()) {
        print('📅 Registering new CalendarController');
        Get.put(CalendarController(), permanent: true);
      } else {
        print('📅 CalendarController already registered');
      }

      // Force initialization of calendar controller to ensure it's working
      final _ = calendarController;

      // Automatically show calendar content when window controller is created
      calendarController.showCalendar();

      // Register this controller with the window manager
      Get.find<WindowManagerService>().registerWindow(this);

      print('📅 Calendar window controller initialized for: $windowName');
    } catch (e) {
      print('❌ Error initializing calendar window controller: $e');
    }
  }

  @override
  void onClose() {
    disposeWindow();
    super.onClose();
  }

  @override
  void disposeWindow() {
    Get.find<WindowManagerService>().unregisterWindow(windowName);
    print('📅 Calendar window disposed: $windowName');
  }

  @override
  void handleCommand(String action, Map<String, dynamic>? payload) {
    try {
      print(
          '📅 Calendar window handling command: $action with payload: $payload');

      switch (action) {
        case 'show':
          showWindow();
          break;

        case 'hide':
          hideWindow();
          break;

        case 'toggle':
          toggleWindow();
          break;

        case 'set_position':
          final x = (payload?['x'] as num?)?.toDouble() ?? windowX.value;
          final y = (payload?['y'] as num?)?.toDouble() ?? windowY.value;
          updatePosition(x, y);
          break;

        case 'set_size':
          final width =
              (payload?['width'] as num?)?.toDouble() ?? windowWidth.value;
          final height =
              (payload?['height'] as num?)?.toDouble() ?? windowHeight.value;
          updateSize(width, height);
          break;

        case 'goto':
        case 'today':
          // Calendar-specific commands - show window and pass to calendar controller
          showWindow();
          calendarController.handleMqttCalendarCommand({
            'action': action,
            ...?payload,
          });
          break;

        default:
          print('❌ Unknown calendar window command: $action');
      }

      print('📅 Calendar window command processed: $action');
    } catch (e) {
      print('❌ Error processing calendar window command: $e');
    }
  }

  /// Show calendar window
  void showWindow() {
    print('📅 [DEBUG] showWindow() called');
    print('📅 [DEBUG] Before: isWindowVisible = ${isWindowVisible.value}');

    // Center the window on screen
    windowX.value = 200.0;
    windowY.value = 150.0;

    isWindowVisible.value = true;
    calendarController.showCalendar();

    print('📅 [DEBUG] After: isWindowVisible = ${isWindowVisible.value}');
    print('📅 [DEBUG] Window position: x=${windowX.value}, y=${windowY.value}');
    print('📅 Calendar window shown');

    // Force update
    update();
  }

  /// Hide calendar window
  void hideWindow() {
    isWindowVisible.value = false;
    calendarController.hideCalendar();
    print('📅 Calendar window hidden');
  }

  /// Toggle calendar window visibility
  void toggleWindow() {
    if (isWindowVisible.value) {
      hideWindow();
    } else {
      showWindow();
    }
  }

  /// Update window position
  void updatePosition(double x, double y) {
    windowX.value = x;
    windowY.value = y;
  }

  /// Update window size
  void updateSize(double width, double height) {
    windowWidth.value = width.clamp(300, 600);
    windowHeight.value = height.clamp(400, 700);
  }

  /// Get window status for MQTT reporting
  Map<String, dynamic> getWindowStatus() {
    return {
      'window_visible': isWindowVisible.value,
      'window_x': windowX.value,
      'window_y': windowY.value,
      'window_width': windowWidth.value,
      'window_height': windowHeight.value,
      'calendar_status': calendarController.getCalendarStatus(),
    };
  }
}
