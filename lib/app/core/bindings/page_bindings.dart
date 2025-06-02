import 'package:get/get.dart';
import '../../services/audio_service.dart';
import '../../services/background_media_service.dart';
import '../../services/media_control_service.dart';
import '../../services/media_recovery_service.dart';
import '../../services/screenshot_service.dart';
import '../../controllers/halo_effect_controller.dart';
import '../../controllers/window_halo_controller.dart';
import '../../services/sip_service.dart';
import '../../services/ai_assistant_service.dart';

import '../../services/memory_manager_service.dart';
import '../../services/service_initializer.dart';

/// Binding for home page - loads media and window services
class HomePageBinding extends Bindings {
  @override
  void dependencies() {
    print('🏠 Loading Home page services...');
    
    // Memory manager (if not already loaded)
    Get.lazyPut<MemoryManagerService>(() => MemoryManagerService(), fenix: true);
    
    // Media services for home page media tiles
    Get.lazyPut<BackgroundMediaService>(() => BackgroundMediaService(), fenix: true);
    Get.lazyPut<MediaControlService>(() => MediaControlService()..init(), fenix: true);
    Get.lazyPut<MediaRecoveryService>(() => MediaRecoveryService()..init(), fenix: true);
    
    // Audio service for sound effects
    Get.lazyPut<AudioService>(() => AudioService()..init(), fenix: true);
    
    // Halo effects for visual feedback
    Get.lazyPut<HaloEffectControllerGetx>(() => HaloEffectControllerGetx(), fenix: true);
    Get.lazyPut<WindowHaloController>(() => WindowHaloController(), fenix: true);
    
    // Screenshot service for capture functionality
    Get.lazyPut<ScreenshotService>(() => ScreenshotService(), fenix: true);
    
    print('✅ Home page services configured');
  }
}

/// Binding for settings page - loads only settings-related services
class SettingsPageBinding extends Bindings {
  @override
  void dependencies() {
    print('⚙️ Loading Settings page services...');
    
    // Memory manager for memory usage display
    Get.lazyPut<MemoryManagerService>(() => MemoryManagerService(), fenix: true);
    
    // Service initializer for async initialization
    Get.lazyPut<ServiceInitializer>(() => ServiceInitializer(), fenix: true);
    
    print('✅ Settings page services configured');
  }
}

/// Binding for media playback pages - loads all media-related services
class MediaPageBinding extends Bindings {
  @override
  void dependencies() {
    print('🎬 Loading Media page services...');
    
    // Memory manager
    Get.lazyPut<MemoryManagerService>(() => MemoryManagerService(), fenix: true);
    
    // All media services
    Get.lazyPut<BackgroundMediaService>(() => BackgroundMediaService(), fenix: true);
    Get.lazyPut<MediaControlService>(() => MediaControlService()..init(), fenix: true);
    Get.lazyPut<MediaRecoveryService>(() => MediaRecoveryService()..init(), fenix: true);
    Get.lazyPut<AudioService>(() => AudioService()..init(), fenix: true);
    
    // Visual effects for media feedback
    Get.lazyPut<HaloEffectControllerGetx>(() => HaloEffectControllerGetx(), fenix: true);
    Get.lazyPut<WindowHaloController>(() => WindowHaloController(), fenix: true);
    
    print('✅ Media page services configured');
  }
}

/// Binding for web view pages - minimal services needed
class WebViewPageBinding extends Bindings {
  @override
  void dependencies() {
    print('🌐 Loading WebView page services...');
    
    // Memory manager
    Get.lazyPut<MemoryManagerService>(() => MemoryManagerService(), fenix: true);
    
    // Screenshot service for web page captures
    Get.lazyPut<ScreenshotService>(() => ScreenshotService(), fenix: true);
    
    // Minimal audio for notification sounds
    Get.lazyPut<AudioService>(() => AudioService()..init(), fenix: true);
    
    print('✅ WebView page services configured');
  }
}

/// Binding for communication pages (SIP/AI) - loads communication services
class CommunicationPageBinding extends Bindings {
  @override
  void dependencies() {
    print('📞 Loading Communication page services...');
    
    // Memory manager
    Get.lazyPut<MemoryManagerService>(() => MemoryManagerService(), fenix: true);
    
    // Service initializer for async initialization
    Get.lazyPut<ServiceInitializer>(() => ServiceInitializer(), fenix: true);
    
    print('✅ Communication page services configured');
  }
}

/// Minimal binding for lightweight pages
class MinimalPageBinding extends Bindings {
  @override
  void dependencies() {
    print('⚡ Loading minimal page services...');
    
    // Only memory manager for monitoring
    Get.lazyPut<MemoryManagerService>(() => MemoryManagerService(), fenix: true);
    
    print('✅ Minimal page services configured');
  }
}

/// Helper class for page-specific service management
class PageBindingUtils {
  /// Helper method to clean up page-specific services when leaving a page
  static void cleanupPageServices(List<Type> serviceTypes) {
    print('🧹 Cleaning up page services...');
    
    for (final serviceType in serviceTypes) {
      try {
        // Only dispose if it's not a permanent service
        if (Get.isRegistered(tag: serviceType.toString())) {
          Get.delete(tag: serviceType.toString());
          print('🗑️ Disposed $serviceType');
        }
      } catch (e) {
        print('Failed to dispose $serviceType: $e');
      }
    }
    
    // Trigger memory cleanup
    try {
      final memoryManager = Get.find<MemoryManagerService>();
      memoryManager.manualCleanup();
    } catch (e) {
      print('Memory manager not available for cleanup: $e');
    }
  }
  
  /// Clean up media services when leaving media pages
  static void cleanupMediaServices() {
    cleanupPageServices([
      BackgroundMediaService,
      MediaControlService,
      MediaRecoveryService,
      HaloEffectControllerGetx,
      WindowHaloController,
    ]);
  }
  
  /// Clean up communication services when leaving communication pages
  static void cleanupCommunicationServices() {
    cleanupPageServices([
      SipService,
      AiAssistantService,
    ]);
  }
  
  /// Clean up visual effect services when leaving pages that use them
  static void cleanupVisualServices() {
    cleanupPageServices([
      HaloEffectControllerGetx,
      WindowHaloController,
      ScreenshotService,
    ]);
  }
}
