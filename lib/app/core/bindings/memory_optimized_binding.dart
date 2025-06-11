import 'package:get/get.dart';
import '../../services/storage_service.dart';
import '../../services/platform_sensor_service.dart';
import '../../services/theme_service.dart';
import '../../services/mqtt_service_consolidated.dart';
import '../../services/sip_service.dart';
import '../../services/app_lifecycle_service.dart';
import '../../services/navigation_service.dart';
import '../../controllers/app_state_controller.dart';
import '../../services/background_media_service.dart';
import '../../modules/settings/controllers/settings_controller_compat.dart';
import '../../services/window_manager_service.dart';
import '../../services/screenshot_service.dart';
import '../../services/media_recovery_service.dart';
import '../../services/audio_service.dart';
import '../../services/window_close_handler.dart';
import '../../services/media_control_service.dart';
import '../../services/ai_assistant_service.dart';
import '../../controllers/halo_effect_controller.dart';
import '../../controllers/window_halo_controller.dart';
import '../../services/media_hardware_detection.dart';
import '../../services/service_initializer.dart';
import '../../services/person_detection_service.dart';
import '../../services/media_device_service.dart';
import '../../services/tts_service.dart';
import '../../core/utils/app_constants.dart';
import '../../modules/calendar/controllers/calendar_controller.dart';
import '../../modules/calendar/controllers/calendar_window_controller.dart';
import '../../modules/home/controllers/tiling_window_controller.dart';

/// Memory-optimized binding that loads only essential services at startup
/// and uses lazy loading for optional services
class MemoryOptimizedBinding extends Bindings {
  @override
  void dependencies() async {
    print('🚀 Initializing memory-optimized binding...');

    // Initialize ServiceInitializer for handling async service initialization
    Get.put<ServiceInitializer>(ServiceInitializer(), permanent: true);

    // ============================================================================
    // CORE SERVICES (IMMEDIATE LOADING) - Essential for basic functionality
    // ============================================================================

    // 1. Storage Service - Required immediately for settings/config
    print('📦 Loading Storage service...');
    final storageService = StorageService();
    await storageService.init();
    Get.put<StorageService>(storageService, permanent: true);

    // 2. Theme Service - Required for UI theming
    print('🎨 Loading Theme service...');
    final themeService = ThemeService();
    await themeService.init();
    Get.put<ThemeService>(themeService, permanent: true);

    // 3. Settings Controller - Required for app configuration
    print('⚙️ Loading Settings controller...');
    Get.put(SettingsControllerFixed(), permanent: true);

    // 4. Window Manager Service - Required for window operations
    print('🪟 Loading Window Manager service...');
    Get.put<WindowManagerService>(WindowManagerService(), permanent: true);

    // 5. TTS Service - Text-to-speech functionality (register before MQTT)
    print('🟢 [Init] Registering TTS service (memory-optimized)...');
    final ttsService = TtsService();
    Get.put<TtsService>(ttsService, permanent: true);
    await ttsService.onInit();
    print('🟢 [Init] TTS service initialized and ready');

    // 6. MQTT Service - Core communication service (if enabled)
    final mqttEnabled =
        storageService.read<bool>(AppConstants.keyMqttEnabled) ?? false;

    if (mqttEnabled) {
      print('📡 Loading MQTT service (enabled in settings)...');
      // Need sensor service for MQTT
      final sensorService = PlatformSensorService();
      await sensorService.init();
      Get.put<PlatformSensorService>(sensorService, permanent: true);

      final sensorServiceRef = Get.find<PlatformSensorService>();
      final mqttService = MqttService(storageService, sensorServiceRef);
      await mqttService.init();
      Get.put<MqttService>(mqttService, permanent: true);
      print('✅ MQTT service initialized successfully');
    } else {
      print('⏭️ MQTT disabled in settings, skipping MQTT service');
      // Still need sensor service for other functionality, but can be lazy
      Get.lazyPut<PlatformSensorService>(() {
        final service = PlatformSensorService();
        // Note: init() is async, so we'll handle it when the service is first accessed
        return service;
      }, fenix: true);
    }
    // ============================================================================
    // LAZY LOADING SERVICES - Loaded only when needed
    // ============================================================================

    print('⚡ Setting up lazy loading for optional services...');

    // App State Controller - Lazy load
    Get.lazyPut<AppStateController>(() => AppStateController(), fenix: true);

    // App Lifecycle Service - Lazy load
    Get.lazyPut<AppLifecycleService>(() {
      final service = AppLifecycleService();
      // Note: init() is async, handle when service is accessed
      return service;
    }, fenix: true);

    // Navigation Service - Lazy load
    Get.lazyPut<NavigationService>(() {
      final service = NavigationService();
      // Note: init() is async, handle when service is accessed
      return service;
    }, fenix: true);

    // Media Services - Lazy load (only when playing media)
    Get.lazyPut<BackgroundMediaService>(() => BackgroundMediaService(),
        fenix: true);
    Get.lazyPut<MediaControlService>(() {
      final service = MediaControlService();
      // Note: init() is async, handle when service is accessed
      return service;
    }, fenix: true);
    Get.lazyPut<MediaRecoveryService>(() {
      final service = MediaRecoveryService();
      // Note: init() is async, handle when service is accessed
      return service;
    }, fenix: true);
    Get.lazyPut<MediaHardwareDetectionService>(() {
      final service = MediaHardwareDetectionService();
      // Note: init() is async, handle when service is accessed
      return service;
    }, fenix: true);

    // Audio Service - Lazy load
    Get.lazyPut<AudioService>(() {
      final service = AudioService();
      // Note: init() is async, handle when service is accessed
      return service;
    }, fenix: true);

    // Screenshot Service - Lazy load
    Get.lazyPut<ScreenshotService>(() => ScreenshotService(), fenix: true);

    // Window Close Handler - Lazy load
    Get.lazyPut<WindowCloseHandler>(() {
      final service = WindowCloseHandler();
      // Note: init() is async, handle when service is accessed
      return service;
    }, fenix: true);

    // Halo Effect Controllers - Lazy load
    Get.lazyPut<HaloEffectControllerGetx>(() => HaloEffectControllerGetx(),
        fenix: true);
    Get.lazyPut<WindowHaloController>(() => WindowHaloController(),
        fenix: true);

    // Calendar Controllers - Lazy load
    Get.lazyPut<CalendarController>(() => CalendarController(), fenix: true);
    Get.lazyPut<CalendarWindowController>(() => CalendarWindowController(),
        fenix: true);

    // Home Module Controllers - Lazy load
    Get.lazyPut<TilingWindowController>(() => TilingWindowController(),
        fenix: true);

    // SIP Service - Conditional lazy loading based on settings
    _conditionallyLoadSipService(storageService);

    // Media Device Service - Always load for device enumeration (required for camera/audio)
    _loadMediaDeviceService();
    // AI Assistant - Lazy load with delayed initialization
    _conditionallyLoadAiAssistant(storageService);

    // Person Detection Service - Conditional lazy loading based on settings
    _conditionallyLoadPersonDetection(storageService);

    print('✅ Memory-optimized binding initialization complete');
    print('🔹 Core services loaded: ${_getCoreServiceCount()}');
    print('🔹 Lazy services configured: ${_getLazyServiceCount()}');
  }

  /// Conditionally load SIP service only if enabled in settings
  void _conditionallyLoadSipService(StorageService storageService) {
    // Always load SIP service for device enumeration, even if SIP calling is disabled
    // This ensures camera/audio device selection works in settings
    print(
        '📞 Loading SIP service for device enumeration (required for media devices)');
    Get.lazyPut<SipService>(() {
      final sipService = SipService(storageService);
      // Note: init() is async, handle when service is accessed
      return sipService;
    }, fenix: true);

    final sipEnabled =
        storageService.read<bool>(AppConstants.keySipEnabled) ?? false;
    if (sipEnabled) {
      print('📞 SIP calling is also enabled in settings');
    } else {
      print(
          '📞 SIP calling is disabled, but service loaded for device enumeration');
    }
  }

  /// Conditionally load AI Assistant service with proper dependencies
  void _conditionallyLoadAiAssistant(StorageService storageService) {
    final aiEnabled =
        storageService.read<bool>(AppConstants.keyAiEnabled) ?? false;

    if (aiEnabled) {
      print('🤖 AI enabled - setting up lazy loading for AI Assistant');
      Get.lazyPut<AiAssistantService>(() {
        // Ensure SIP service is available first
        if (!Get.isRegistered<SipService>()) {
          final sipService = SipService(storageService);
          // Note: init() is async, handle when service is accessed
          Get.put<SipService>(sipService, permanent: true);
        }

        final sipService = Get.find<SipService>();
        final aiAssistantService =
            AiAssistantService(sipService, storageService);
        // Note: init() is async, handle when service is accessed
        return aiAssistantService;
      }, fenix: true);
    } else {
      print('⏭️ AI disabled in settings, skipping AI Assistant service');
    }
  }

  /// Conditionally load Person Detection service with proper dependencies
  void _conditionallyLoadPersonDetection(StorageService storageService) {
    // Always register PersonDetectionService, but only initialize when enabled
    print('👤 Registering PersonDetectionService (lazy loading)');

    Get.lazyPut<PersonDetectionService>(() {
      final personDetectionService = PersonDetectionService();
      // Note: init() is async, handle when service is accessed
      return personDetectionService;
    }, fenix: true);

    final personDetectionEnabled =
        storageService.read<bool>(AppConstants.keyPersonDetectionEnabled) ??
            false;

    if (personDetectionEnabled) {
      print('👤 Person detection enabled - starting service initialization');

      // Trigger immediate access to start the service since it's enabled
      Future.delayed(Duration(seconds: 2), () {
        try {
          // Initialize person detection with direct video track capture
          Get.find<PersonDetectionService>();
          print(
              '👤 Person detection service initialized with direct video track capture');
        } catch (e) {
          print('❌ Error initializing PersonDetectionService: $e');
        }
      });
    } else {
      print(
          '⏭️ Person detection disabled in settings but service is registered for later use');
    }
  }

  /// Load MediaDeviceService - Always available for device enumeration
  void _loadMediaDeviceService() {
    print(
        '🎥 Loading MediaDeviceService for device enumeration (always available)');
    Get.putAsync<MediaDeviceService>(() async {
      final mediaDeviceService = MediaDeviceService();
      await mediaDeviceService.init();
      return mediaDeviceService;
    }, permanent: true);

    print('✅ MediaDeviceService setup complete - devices will be enumerated');
  }

  int _getCoreServiceCount() {
    int count = 4; // Storage, Theme, Settings, WindowManager
    if (Get.isRegistered<MqttService>()) count++;
    if (Get.isRegistered<PlatformSensorService>()) count++;
    return count;
  }

  int _getLazyServiceCount() {
    return 10; // Approximate count of lazy services
  }
}

/// Utility class for safe service access
class ServiceHelpers {
  /// Safely get a service that might be lazy-loaded
  static T? findOrNull<T>() {
    try {
      return Get.find<T>();
    } catch (e) {
      return null;
    }
  }

  /// Check if a service is registered
  static bool isRegistered<T>() {
    return Get.isRegistered<T>();
  }

  /// Get a service and log if it's not available
  static T? findSafely<T>(String serviceName) {
    try {
      return Get.find<T>();
    } catch (e) {
      print('⚠️ Service $serviceName not available: $e');
      return null;
    }
  }

  /// Get a service and ensure it's properly initialized
  static Future<T> findInitialized<T>(String serviceName) async {
    try {
      final service = Get.find<T>();
      await ServiceInitializer.instance.initializeService<T>(service);
      return service;
    } catch (e) {
      print('❌ Failed to get initialized service $serviceName: $e');
      rethrow;
    }
  }

  /// Get service initialization status
  static Map<String, bool> getServiceStatus() {
    try {
      return ServiceInitializer.instance.getInitializationStatus();
    } catch (e) {
      print('⚠️ ServiceInitializer not available: $e');
      return {};
    }
  }
}
