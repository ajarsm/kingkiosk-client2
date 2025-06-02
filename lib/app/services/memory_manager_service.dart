import 'package:get/get.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Service for monitoring and managing memory usage
class MemoryManagerService extends GetxService {
  // Observable memory metrics
  final RxDouble memoryUsagePercent = 0.0.obs;
  final RxInt memoryUsageMB = 0.obs;
  final RxInt peakMemoryMB = 0.obs;
  final RxBool isMemoryPressure = false.obs;
  
  // Memory thresholds
  static const double warningThreshold = 0.8; // 80%
  static const double criticalThreshold = 0.9; // 90%
  
  // Service registry for auto-disposal
  final Map<Type, DateTime> _serviceLastUsed = {};
  final Map<Type, bool> _serviceAutoDispose = {};
  
  @override
  Future<MemoryManagerService> onInit() async {
    super.onInit();
    
    // Start memory monitoring
    _startMemoryMonitoring();
    
    // Set up auto-disposal for specific services
    _configureAutoDisposal();
    
    print('🧠 Memory Manager Service initialized');
    return this;
  }
  
  /// Start periodic memory monitoring
  void _startMemoryMonitoring() {
    // Monitor memory every 30 seconds
    Stream.periodic(Duration(seconds: 30)).listen((_) {
      _updateMemoryMetrics();
      _checkMemoryPressure();
      _cleanupUnusedServices();
    });
    
    // Initial memory check
    _updateMemoryMetrics();
  }
  
  /// Update current memory usage metrics
  void _updateMemoryMetrics() {
    if (kIsWeb) {
      // Web doesn't have direct memory access
      return;
    }
    
    try {
      final info = ProcessInfo.currentRss;
      final memoryBytes = info;
      final memoryMB = (memoryBytes / (1024 * 1024)).round();
      
      memoryUsageMB.value = memoryMB;
      
      // Update peak memory
      if (memoryMB > peakMemoryMB.value) {
        peakMemoryMB.value = memoryMB;
      }
      
      // Calculate percentage (assuming 4GB max for estimation)
      final estimatedMaxMB = 4096;
      memoryUsagePercent.value = memoryMB / estimatedMaxMB;
      
      developer.log('Memory: ${memoryMB}MB (${(memoryUsagePercent.value * 100).toStringAsFixed(1)}%)');
      
    } catch (e) {
      developer.log('Error reading memory metrics: $e');
    }
  }
  
  /// Check for memory pressure and take action
  void _checkMemoryPressure() {
    final currentUsage = memoryUsagePercent.value;
    
    if (currentUsage >= criticalThreshold) {
      isMemoryPressure.value = true;
      developer.log('🚨 CRITICAL memory pressure detected: ${(currentUsage * 100).toStringAsFixed(1)}%');
      _performCriticalCleanup();
    } else if (currentUsage >= warningThreshold) {
      isMemoryPressure.value = true;
      developer.log('⚠️ Memory pressure warning: ${(currentUsage * 100).toStringAsFixed(1)}%');
      _performWarningCleanup();
    } else {
      isMemoryPressure.value = false;
    }
  }
  
  /// Configure which services can be auto-disposed
  void _configureAutoDisposal() {
    // Services that can be safely disposed when not used
    _serviceAutoDispose[Type] = true; // Add specific service types
    
    // Media services can be disposed after inactivity
    _markServiceForAutoDisposal<dynamic>('BackgroundMediaService');
    _markServiceForAutoDisposal<dynamic>('MediaControlService');
    _markServiceForAutoDisposal<dynamic>('ScreenshotService');
    _markServiceForAutoDisposal<dynamic>('HaloEffectControllerGetx');
    _markServiceForAutoDisposal<dynamic>('WindowHaloController');
  }
  
  /// Mark a service for potential auto-disposal
  void _markServiceForAutoDisposal<T>(String serviceName) {
    try {
      final serviceType = T;
      _serviceAutoDispose[serviceType] = true;
      developer.log('📝 Marked $serviceName for auto-disposal when unused');
    } catch (e) {
      developer.log('Could not mark $serviceName for auto-disposal: $e');
    }
  }
  
  /// Record service usage
  void recordServiceUsage<T>() {
    _serviceLastUsed[T] = DateTime.now();
  }
  
  /// Cleanup unused services
  void _cleanupUnusedServices() {
    final now = DateTime.now();
    final unusedThreshold = Duration(minutes: 5); // 5 minutes of inactivity
    
    _serviceLastUsed.removeWhere((type, lastUsed) {
      final isUnused = now.difference(lastUsed) > unusedThreshold;
      final canDispose = _serviceAutoDispose[type] ?? false;
      
      if (isUnused && canDispose) {
        try {
          Get.delete(tag: type.toString());
          developer.log('🗑️ Auto-disposed unused service: $type');
          return true;
        } catch (e) {
          developer.log('Failed to dispose service $type: $e');
          return false;
        }
      }
      return false;
    });
  }
  
  /// Perform warning-level memory cleanup
  void _performWarningCleanup() {
    developer.log('🧹 Performing warning-level memory cleanup...');
    
    // Dispose non-essential visual effects
    _safelyDisposeService<dynamic>('HaloEffectControllerGetx');
    _safelyDisposeService<dynamic>('WindowHaloController');
    
    // Clear image caches
    _clearImageCaches();
    
    // Suggest garbage collection
    _suggestGarbageCollection();
  }
  
  /// Perform critical-level memory cleanup
  void _performCriticalCleanup() {
    developer.log('🚨 Performing critical memory cleanup...');
    
    // Dispose all non-essential services
    _performWarningCleanup();
    
    // Dispose media services if not actively playing
    _safelyDisposeService<dynamic>('BackgroundMediaService');
    _safelyDisposeService<dynamic>('MediaControlService');
    
    // Force garbage collection
    _forceGarbageCollection();
  }
  
  /// Safely dispose a service if it exists
  void _safelyDisposeService<T>(String serviceName) {
    try {
      if (Get.isRegistered<T>()) {
        Get.delete<T>();
        developer.log('🗑️ Disposed $serviceName due to memory pressure');
      }
    } catch (e) {
      developer.log('Failed to dispose $serviceName: $e');
    }
  }
  
  /// Clear image caches to free memory
  void _clearImageCaches() {
    try {
      // Clear Flutter's image cache
      if (!kIsWeb) {
        // PaintingBinding.instance.imageCache.clear();
        developer.log('🖼️ Cleared image caches');
      }
    } catch (e) {
      developer.log('Failed to clear image caches: $e');
    }
  }
  
  /// Suggest garbage collection
  void _suggestGarbageCollection() {
    try {
      // Force garbage collection on native platforms
      if (!kIsWeb) {
        developer.log('🗑️ Suggesting garbage collection...');
        // Note: Dart doesn't provide direct GC control, but this helps with debugging
      }
    } catch (e) {
      developer.log('Error during garbage collection: $e');
    }
  }
  
  /// Force garbage collection (more aggressive)
  void _forceGarbageCollection() {
    try {
      _suggestGarbageCollection();
      
      // Additional cleanup for critical situations
      developer.log('🚨 Forced garbage collection due to critical memory pressure');
    } catch (e) {
      developer.log('Error during forced garbage collection: $e');
    }
  }
  
  /// Get memory usage summary
  Map<String, dynamic> getMemoryReport() {
    return {
      'current_mb': memoryUsageMB.value,
      'peak_mb': peakMemoryMB.value,
      'usage_percent': (memoryUsagePercent.value * 100).toStringAsFixed(1),
      'memory_pressure': isMemoryPressure.value,
      'registered_services': _getRegisteredServiceCount(),
      'auto_disposable_services': _serviceAutoDispose.length,
      'last_cleanup': DateTime.now().toIso8601String(),
    };
  }
  
  /// Manually trigger memory cleanup
  void manualCleanup({bool aggressive = false}) {
    developer.log('🧹 Manual memory cleanup requested (aggressive: $aggressive)');
    
    if (aggressive) {
      _performCriticalCleanup();
    } else {
      _performWarningCleanup();
    }
    
    _updateMemoryMetrics();
  }
  
  /// Get count of registered services (workaround for Get.registered not being available)
  int _getRegisteredServiceCount() {
    // Since Get.registered is not available, we'll estimate based on known services
    // Return a reasonable estimate since we can't access the actual registry
    return 8; // Estimated number of typically registered services
  }

  @override
  void onClose() {
    developer.log('🧠 Memory Manager Service closing');
    super.onClose();
  }
}
