import 'package:get/get.dart';
import 'platform_sensor_service.dart';
import 'app_lifecycle_service.dart';
import 'navigation_service.dart';
import 'media_control_service.dart';
import 'media_recovery_service.dart';
import 'media_hardware_detection.dart';
import 'audio_service.dart';
import 'window_close_handler.dart';
import 'sip_service.dart';
import 'ai_assistant_service.dart';

/// Service to handle async initialization of lazy-loaded services
/// This ensures that services with async init() methods are properly initialized
/// when they're first accessed from lazy loading
class ServiceInitializer extends GetxService {
  static ServiceInitializer get instance => Get.find<ServiceInitializer>();
  
  final Map<Type, bool> _initializationStatus = {};
  final Map<Type, Future<void>> _initializationFutures = {};
  
  /// Initialize a service asynchronously if not already initialized
  Future<void> initializeService<T>(T service) async {
    final serviceType = T;
    
    // Check if already initialized or in progress
    if (_initializationStatus[serviceType] == true) {
      return;
    }
    
    // Check if initialization is already in progress
    if (_initializationFutures.containsKey(serviceType)) {
      await _initializationFutures[serviceType];
      return;
    }
    
    // Start initialization
    print('🔄 Initializing ${serviceType.toString()}...');
    
    Future<void> initFuture;    switch (serviceType) {
      case PlatformSensorService:
        // PlatformSensorService.init() returns PlatformSensorService, not Future
        (service as PlatformSensorService).init();
        _initializationStatus[serviceType] = true;
        return;
      case AppLifecycleService:
        // AppLifecycleService.init() returns AppLifecycleService, not Future
        (service as AppLifecycleService).init();
        _initializationStatus[serviceType] = true;
        return;
      case NavigationService:
        // NavigationService.init() returns NavigationService, not Future  
        (service as NavigationService).init();
        _initializationStatus[serviceType] = true;
        return;
      case MediaControlService:
        initFuture = (service as MediaControlService).init();
        break;
      case MediaRecoveryService:
        initFuture = (service as MediaRecoveryService).init();
        break;
      case MediaHardwareDetectionService:
        initFuture = (service as MediaHardwareDetectionService).init().then((_) {});
        break;
      case AudioService:
        initFuture = (service as AudioService).init();
        break;
      case WindowCloseHandler:
        initFuture = (service as WindowCloseHandler).init();
        break;
      case SipService:
        initFuture = (service as SipService).init().then((_) {});
        break;
      case AiAssistantService:
        initFuture = (service as AiAssistantService).init().then((_) {});
        break;
      default:
        // Service doesn't need async initialization
        _initializationStatus[serviceType] = true;
        return;
    }
    
    _initializationFutures[serviceType] = initFuture;
    
    try {
      await initFuture;
      _initializationStatus[serviceType] = true;
      print('✅ ${serviceType.toString()} initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize ${serviceType.toString()}: $e');
      _initializationStatus[serviceType] = false;
    } finally {
      _initializationFutures.remove(serviceType);
    }
  }
  
  /// Get a service and ensure it's initialized
  Future<T> getInitializedService<T>() async {
    final service = Get.find<T>();
    await initializeService<T>(service);
    return service;
  }
  
  /// Check if a service is initialized
  bool isServiceInitialized<T>() {
    return _initializationStatus[T] == true;
  }
  
  /// Get initialization status of all services
  Map<String, bool> getInitializationStatus() {
    return _initializationStatus.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  
  @override
  void onClose() {
    _initializationStatus.clear();
    _initializationFutures.clear();
    super.onClose();
  }
}

/// Extension to provide easy access to initialized services
extension ServiceAccess on GetInterface {
  /// Get a service and ensure it's properly initialized
  Future<T> findInitialized<T>() async {
    final service = Get.find<T>();
    await ServiceInitializer.instance.initializeService<T>(service);
    return service;
  }
  
  /// Get a service without waiting for initialization (returns immediately)
  /// Use this when you need the service instance but don't need it to be fully initialized
  T findImmediate<T>() {
    return Get.find<T>();
  }
}
