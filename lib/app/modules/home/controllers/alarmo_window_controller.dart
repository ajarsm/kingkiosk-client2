import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/window_manager_service.dart';
import '../../../services/mqtt_service_consolidated.dart';

/// Alarmo states as defined by Home Assistant
enum AlarmoState {
  disarmed,
  arming,
  armed_away,
  armed_home,
  armed_night,
  armed_vacation,
  armed_custom_bypass,
  pending,
  triggered,
  unavailable,
}

/// Alarmo arm modes
enum AlarmoArmMode {
  away,
  home,
  night,
  vacation,
  custom,
}

/// Alarmo window controller for handling Alarmo dialpad widgets
class AlarmoWindowController extends GetxController
    implements KioskWindowController {
  final String windowName;

  // Reactive properties
  final _isVisible = true.obs;
  final _isMinimized = false.obs;
  final _currentState = AlarmoState.disarmed.obs;
  final _enteredCode = ''.obs;
  final _errorMessage = RxnString();
  final _isLoading = false.obs;
  final _selectedArmMode = AlarmoArmMode.away.obs;
  final _showModeSelection = false.obs;
  final _availableModes = <AlarmoArmMode>[].obs;

  // Configuration
  final _alarmoEntity = 'alarm_control_panel.alarmo'.obs;
  final _requireCode = true.obs;
  final _codeLength = 4.obs;
  final _stateTopic = 'alarmo/state'.obs;
  final _commandTopic = 'alarmo/command'.obs;
  final _eventTopic = 'alarmo/event'.obs;

  // Getters
  bool get isVisible => _isVisible.value;
  bool get isMinimized => _isMinimized.value;
  AlarmoState get currentState => _currentState.value;
  String get enteredCode => _enteredCode.value;
  String? get errorMessage => _errorMessage.value;
  bool get isLoading => _isLoading.value;
  AlarmoArmMode get selectedArmMode => _selectedArmMode.value;
  bool get showModeSelection => _showModeSelection.value;
  List<AlarmoArmMode> get availableModes => _availableModes;
  String get alarmoEntity => _alarmoEntity.value;
  bool get requireCode => _requireCode.value;
  int get codeLength => _codeLength.value;
  String get stateTopic => _stateTopic.value;
  String get commandTopic => _commandTopic.value;
  String get eventTopic => _eventTopic.value;

  AlarmoWindowController({required this.windowName});

  @override
  KioskWindowType get windowType => KioskWindowType.custom;

  @override
  void onInit() {
    super.onInit();

    // Initialize available modes (all modes by default)
    _availableModes.addAll(AlarmoArmMode.values);

    // Register this controller with the window manager
    Get.find<WindowManagerService>().registerWindow(this);

    // Subscribe to MQTT topics
    _subscribeToAlarmoTopics();

    print('Alarmo window controller initialized for: $windowName');
  }

  @override
  void onClose() {
    disposeWindow();
    super.onClose();
  }

  @override
  void handleCommand(String action, Map<String, dynamic>? payload) {
    print('Alarmo window received command: $action with payload: $payload');

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
      case 'arm':
        final mode = payload?['mode'] as String?;
        final code = payload?['code'] as String?;
        if (mode != null) {
          final armMode = AlarmoArmMode.values.firstWhere(
            (m) => m.toString().split('.').last == mode,
            orElse: () => AlarmoArmMode.away,
          );
          arm(armMode, code: code);
        }
        break;
      case 'disarm':
        final code = payload?['code'] as String?;
        disarm(code: code);
        break;
      default:
        print('Unknown command for Alarmo window: $action');
    }
  }

  @override
  void disposeWindow() {
    try {
      // Unsubscribe from MQTT topics
      _unsubscribeFromAlarmoTopics();

      Get.find<WindowManagerService>().unregisterWindow(windowName);
      print('Alarmo window disposed: $windowName');
    } catch (e) {
      print('Error disposing Alarmo window: $e');
    }
  }

  /// Subscribe to Alarmo MQTT topics
  void _subscribeToAlarmoTopics() {
    try {
      final mqttService = Get.find<MqttService>();

      // Subscribe to state topic
      mqttService.subscribe(stateTopic, _handleStateUpdate);

      // Subscribe to event topic for additional feedback
      mqttService.subscribe(eventTopic, _handleEventUpdate);

      print('Subscribed to Alarmo MQTT topics: ${stateTopic}, ${eventTopic}');
    } catch (e) {
      print('Error subscribing to Alarmo MQTT topics: $e');
    }
  }

  /// Unsubscribe from Alarmo MQTT topics
  void _unsubscribeFromAlarmoTopics() {
    try {
      // Note: Unsubscribe functionality may not be available in current MQTT service
      // final mqttService = Get.find<MqttService>();
      // mqttService.unsubscribe(stateTopic);
      // mqttService.unsubscribe(eventTopic);

      print('Unsubscribed from Alarmo MQTT topics');
    } catch (e) {
      print('Error unsubscribing from Alarmo MQTT topics: $e');
    }
  }

  /// Handle state updates from MQTT
  void _handleStateUpdate(String topic, String payload) {
    print('Alarmo state update: $payload');

    // Parse state from payload
    final stateStr = payload.trim().toLowerCase();
    AlarmoState newState;

    switch (stateStr) {
      case 'disarmed':
        newState = AlarmoState.disarmed;
        break;
      case 'arming':
        newState = AlarmoState.arming;
        break;
      case 'armed_away':
        newState = AlarmoState.armed_away;
        break;
      case 'armed_home':
        newState = AlarmoState.armed_home;
        break;
      case 'armed_night':
        newState = AlarmoState.armed_night;
        break;
      case 'armed_vacation':
        newState = AlarmoState.armed_vacation;
        break;
      case 'armed_custom_bypass':
        newState = AlarmoState.armed_custom_bypass;
        break;
      case 'pending':
        newState = AlarmoState.pending;
        break;
      case 'triggered':
        newState = AlarmoState.triggered;
        break;
      default:
        newState = AlarmoState.unavailable;
    }

    _currentState.value = newState;

    // Clear loading state when state changes
    _isLoading.value = false;

    // Hide mode selection after successful arming
    if (newState != AlarmoState.disarmed) {
      _showModeSelection.value = false;
    }

    // Clear entered code after state change
    _enteredCode.value = '';
  }

  /// Handle event updates from MQTT
  void _handleEventUpdate(String topic, String payload) {
    print('Alarmo event update: $payload');

    try {
      final data = Map<String, dynamic>.from(payload.startsWith('{')
          ? Map<String, dynamic>.from(Map.from(Map.castFrom(Map.from({}))))
          : {'event': payload});

      final event = data['event'] as String?;

      switch (event) {
        case 'FAILED_TO_ARM':
          _errorMessage.value = 'Failed to arm: Check sensors';
          _isLoading.value = false;
          break;
        case 'COMMAND_NOT_ALLOWED':
          _errorMessage.value = 'Command not allowed';
          _isLoading.value = false;
          break;
        case 'NO_CODE_PROVIDED':
          _errorMessage.value = 'Code required';
          _isLoading.value = false;
          break;
        case 'INVALID_CODE_PROVIDED':
          _errorMessage.value = 'Invalid code';
          _isLoading.value = false;
          break;
        case 'ARM_AWAY':
        case 'ARM_HOME':
        case 'ARM_NIGHT':
        case 'ARM_VACATION':
        case 'ARM_CUSTOM_BYPASS':
          _errorMessage.value = null;
          break;
      }
    } catch (e) {
      print('Error parsing Alarmo event: $e');
    }
  }

  /// Configure the Alarmo widget
  void configure(Map<String, dynamic> config) {
    if (config.containsKey('entity')) {
      _alarmoEntity.value = config['entity'] as String;
    }
    if (config.containsKey('require_code')) {
      _requireCode.value = config['require_code'] as bool;
    }
    if (config.containsKey('code_length')) {
      _codeLength.value = config['code_length'] as int;
    }
    if (config.containsKey('state_topic')) {
      _stateTopic.value = config['state_topic'] as String;
    }
    if (config.containsKey('command_topic')) {
      _commandTopic.value = config['command_topic'] as String;
    }
    if (config.containsKey('event_topic')) {
      _eventTopic.value = config['event_topic'] as String;
    }
    if (config.containsKey('available_modes')) {
      final modes = (config['available_modes'] as List<dynamic>)
          .map((e) => e.toString())
          .map((modeStr) => AlarmoArmMode.values.firstWhere(
                (mode) => mode.toString().split('.').last == modeStr,
                orElse: () => AlarmoArmMode.away,
              ))
          .toList();
      _availableModes.assignAll(modes);
    }

    print('Alarmo widget configured: $config');
  }

  /// Add a digit to the entered code
  void addDigit(int digit) {
    if (_enteredCode.value.length < codeLength) {
      _enteredCode.value += digit.toString();
      _errorMessage.value = null;
    }
  }

  /// Remove the last digit from the entered code
  void removeDigit() {
    if (_enteredCode.value.isNotEmpty) {
      _enteredCode.value =
          _enteredCode.value.substring(0, _enteredCode.value.length - 1);
      _errorMessage.value = null;
    }
  }

  /// Clear the entered code
  void clearCode() {
    _enteredCode.value = '';
    _errorMessage.value = null;
  }

  /// Set the selected arm mode
  void setArmMode(AlarmoArmMode mode) {
    _selectedArmMode.value = mode;
  }

  /// Toggle mode selection visibility
  void toggleModeSelection() {
    _showModeSelection.value = !_showModeSelection.value;
  }

  /// Show mode selection
  void showArmModeSelection() {
    _showModeSelection.value = true;
  }

  /// Hide mode selection
  void hideModeSelection() {
    _showModeSelection.value = false;
  }

  /// Arm the alarm with the selected mode
  void arm(AlarmoArmMode mode, {String? code}) {
    _isLoading.value = true;
    _errorMessage.value = null;

    final codeToUse = code ?? (requireCode ? enteredCode : null);

    if (requireCode && (codeToUse == null || codeToUse.length != codeLength)) {
      _errorMessage.value = 'Enter ${codeLength}-digit code';
      _isLoading.value = false;
      return;
    }

    try {
      final mqttService = Get.find<MqttService>();

      final command = {
        'command': 'arm_${mode.toString().split('.').last}',
        if (codeToUse != null) 'code': codeToUse,
      };

      mqttService.publishJsonToTopic(commandTopic, command);

      print('Sent arm command: $command');

      // Set a timeout for loading state
      Timer(const Duration(seconds: 10), () {
        if (_isLoading.value) {
          _isLoading.value = false;
          _errorMessage.value = 'Command timeout';
        }
      });
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = 'Failed to send command';
      print('Error sending arm command: $e');
    }
  }

  /// Disarm the alarm
  void disarm({String? code}) {
    _isLoading.value = true;
    _errorMessage.value = null;

    final codeToUse = code ?? (requireCode ? enteredCode : null);

    if (requireCode && (codeToUse == null || codeToUse.length != codeLength)) {
      _errorMessage.value = 'Enter ${codeLength}-digit code';
      _isLoading.value = false;
      return;
    }

    try {
      final mqttService = Get.find<MqttService>();

      final command = {
        'command': 'disarm',
        if (codeToUse != null) 'code': codeToUse,
      };

      mqttService.publishJsonToTopic(commandTopic, command);

      print('Sent disarm command: $command');

      // Set a timeout for loading state
      Timer(const Duration(seconds: 10), () {
        if (_isLoading.value) {
          _isLoading.value = false;
          _errorMessage.value = 'Command timeout';
        }
      });
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = 'Failed to send command';
      print('Error sending disarm command: $e');
    }
  }

  /// Execute the current action (arm or disarm based on state)
  void executeAction() {
    if (currentState == AlarmoState.disarmed) {
      // If disarmed, show mode selection or arm with selected mode
      if (availableModes.length > 1 && !showModeSelection) {
        showArmModeSelection();
      } else {
        arm(selectedArmMode);
      }
    } else {
      // If armed/arming, disarm
      disarm();
    }
  }

  /// Minimize the window
  void minimize() {
    _isMinimized.value = true;
    print('Alarmo window minimized: $windowName');
  }

  /// Maximize/restore the window
  void maximize() {
    _isMinimized.value = false;
    print('Alarmo window maximized: $windowName');
  }

  /// Close the window
  void close() {
    _isVisible.value = false;
    print('Alarmo window closed: $windowName');
  }

  /// Get display text for current state
  String getStateDisplayText() {
    switch (currentState) {
      case AlarmoState.disarmed:
        return 'DISARMED';
      case AlarmoState.arming:
        return 'ARMING...';
      case AlarmoState.armed_away:
        return 'ARMED AWAY';
      case AlarmoState.armed_home:
        return 'ARMED HOME';
      case AlarmoState.armed_night:
        return 'ARMED NIGHT';
      case AlarmoState.armed_vacation:
        return 'ARMED VACATION';
      case AlarmoState.armed_custom_bypass:
        return 'ARMED CUSTOM';
      case AlarmoState.pending:
        return 'PENDING';
      case AlarmoState.triggered:
        return 'TRIGGERED';
      case AlarmoState.unavailable:
        return 'UNAVAILABLE';
    }
  }

  /// Get color for current state
  Color getStateColor() {
    switch (currentState) {
      case AlarmoState.disarmed:
        return Colors.green;
      case AlarmoState.arming:
        return Colors.orange;
      case AlarmoState.armed_away:
      case AlarmoState.armed_home:
      case AlarmoState.armed_night:
      case AlarmoState.armed_vacation:
      case AlarmoState.armed_custom_bypass:
        return Colors.red;
      case AlarmoState.pending:
        return Colors.orange;
      case AlarmoState.triggered:
        return Colors.red.shade700;
      case AlarmoState.unavailable:
        return Colors.grey;
    }
  }

  /// Get display text for arm mode
  String getArmModeDisplayText(AlarmoArmMode mode) {
    switch (mode) {
      case AlarmoArmMode.away:
        return 'Away';
      case AlarmoArmMode.home:
        return 'Home';
      case AlarmoArmMode.night:
        return 'Night';
      case AlarmoArmMode.vacation:
        return 'Vacation';
      case AlarmoArmMode.custom:
        return 'Custom';
    }
  }

  /// Get icon for arm mode
  IconData getArmModeIcon(AlarmoArmMode mode) {
    switch (mode) {
      case AlarmoArmMode.away:
        return Icons.home_outlined;
      case AlarmoArmMode.home:
        return Icons.home;
      case AlarmoArmMode.night:
        return Icons.bedtime;
      case AlarmoArmMode.vacation:
        return Icons.luggage;
      case AlarmoArmMode.custom:
        return Icons.tune;
    }
  }
}
