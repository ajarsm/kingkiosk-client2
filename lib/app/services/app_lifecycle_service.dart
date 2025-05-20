import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'dart:developer' as developer;
import 'storage_service.dart';
import 'mqtt_service_consolidated.dart';
import 'sip_service.dart';
import '../core/utils/app_constants.dart';

/// Simple service to handle MQTT connection on app lifecycle events
class AppLifecycleService extends GetxService with WidgetsBindingObserver {
  // Dependencies
  final StorageService _storageService = Get.find<StorageService>();

  // Track whether MQTT is enabled
  final RxBool mqttEnabled = false.obs;

  // Constructor
  AppLifecycleService();

  /// Initialize the service
  AppLifecycleService init() {
    // Register as an observer of app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Check if MQTT is enabled
    mqttEnabled.value =
        _storageService.read<bool>(AppConstants.keyMqttEnabled) ?? false;

    // Auto-connect if enabled - use a shorter delay
    if (mqttEnabled.value) {
      developer.log('MQTT is enabled, scheduling auto-connect at startup');
      // A shorter delay is usually sufficient
      Future.delayed(Duration(milliseconds: 500), () {
        connectMqttIfAvailable();
      });
    } else {
      developer.log('MQTT is not enabled at startup');
    }

    return this;
  }

  /// Called when app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log('App lifecycle state changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App is visible and responding to user input
        if (mqttEnabled.value) {
          // Try to reconnect if needed
          connectMqttIfAvailable();
        }
        break;

      case AppLifecycleState.inactive:
        // App is in an inactive state (transitions)
        break;

      case AppLifecycleState.paused:
        // App not visible, running in background
        // MQTT will handle this with Last Will and Testament
        break;
      case AppLifecycleState.detached:
        // App will be terminated, perform clean shutdown
        performCleanShutdown();
        break;

      default:
        // Handle any future lifecycle states
        break;
    }
  }

  /// Connect to MQTT if a service is available
  void connectMqttIfAvailable() {
    try {
      // Check if MQTT is enabled in settings
      final enabled =
          _storageService.read<bool>(AppConstants.keyMqttEnabled) ?? false;
      if (!enabled) {
        developer.log('MQTT is disabled in settings, skipping connection');
        return;
      }

      // Get broker settings
      final brokerUrl =
          _storageService.read<String>(AppConstants.keyMqttBrokerUrl) ?? '';
      final brokerPort =
          _storageService.read<int>(AppConstants.keyMqttBrokerPort) ?? 1883;
      final username =
          _storageService.read<String>(AppConstants.keyMqttUsername) ?? '';
      final password =
          _storageService.read<String>(AppConstants.keyMqttPassword) ?? '';

      if (brokerUrl.isEmpty) {
        developer.log('MQTT broker URL is empty, skipping connection');
        return;
      }

      // Check if MqttService is registered
      if (Get.isRegistered<MqttService>()) {
        final mqttService = Get.find<MqttService>();

        // Connect if not already connected
        if (!mqttService.isConnected.value) {
          developer.log('Connecting to MQTT broker: $brokerUrl:$brokerPort');
          mqttService
              .connect(
            brokerUrl: brokerUrl,
            port: brokerPort,
            username: username.isNotEmpty ? username : null,
            password: password.isNotEmpty ? password : null,
          )
              .then((success) {
            if (success) {
              developer.log('Successfully connected to MQTT broker');
            } else {
              developer.log('Failed to connect to MQTT broker');
            }
          });
        } else {
          developer.log('MQTT already connected, skipping connection attempt');
        }
      } else {
        developer.log('MqttService not found, cannot connect to MQTT');
      }
    } catch (e) {
      developer.log('Error connecting to MQTT: $e', error: e);
    }
  }

  /// Disconnect from MQTT if connected
  Future<void> disconnectMqttIfConnected() async {
    try {
      // Check if MqttService is registered
      if (Get.isRegistered<MqttService>()) {
        final mqttService = Get.find<MqttService>();

        // Disconnect if connected
        if (mqttService.isConnected.value) {
          developer.log('Disconnecting from MQTT broker');
          await mqttService.disconnect();
          developer
              .log('MQTT disconnection completed in disconnectMqttIfConnected');
        }
      }
    } catch (e) {
      developer.log('Error disconnecting from MQTT: $e', error: e);
    }
  }

  /// Safely disconnect from MQTT service with better error handling and awaiting the disconnect
  Future<void> _safeDisconnectMqtt() async {
    try {
      // Check if MqttService is registered
      if (Get.isRegistered<MqttService>()) {
        final mqttService = Get.find<MqttService>();

        // Disconnect if connected
        if (mqttService.isConnected.value) {
          developer.log('Safely disconnecting from MQTT broker');
          await mqttService.disconnect();
          developer.log('MQTT disconnection completed');
        } else {
          developer.log('MQTT already disconnected');
        }
      } else {
        developer.log('MQTT service not found during shutdown');
      }
    } catch (e) {
      developer.log('Error disconnecting from MQTT: $e', error: e);
    }
  }

  /// Perform a clean shutdown, unregistering from all services
  Future<void> performCleanShutdown() async {
    developer.log('Performing clean shutdown of all services');

    // Unregister from SIP if available
    if (Get.isRegistered<SipService>()) {
      try {
        final sipService = Get.find<SipService>();
        developer.log('Unregistering SIP service before exit');
        await sipService.unregister();
        developer.log('SIP service unregistration completed');
      } catch (e) {
        developer.log('Error unregistering SIP: $e', error: e);
      }
    } else {
      developer.log('SIP service not found during shutdown');
    }

    // Disconnect from MQTT
    await _safeDisconnectMqtt();

    // Small delay to ensure cleanup completes
    await Future.delayed(Duration(milliseconds: 200));
    developer.log('Clean shutdown completed');
  }

  /// Clean up when service is closed
  @override
  void onClose() {
    // Unregister from app lifecycle events
    WidgetsBinding.instance.removeObserver(this);

    // Perform clean shutdown
    performCleanShutdown();

    super.onClose();
  }
}
