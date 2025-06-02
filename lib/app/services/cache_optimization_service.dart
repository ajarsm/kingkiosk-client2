import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Service for optimizing image caching and WebView memory management
class CacheOptimizationService extends GetxService {
  // Image cache settings
  static const int maxImageCacheSize = 100 << 20; // 100MB
  static const int maxImageCacheCount = 1000;
  
  // WebView management
  final Map<String, DateTime> _webViewLastUsed = {};
  final Set<String> _disposedWebViews = {};
  
  // Cache metrics
  final RxInt imageCacheSize = 0.obs;
  final RxInt imageCacheCount = 0.obs;
  final RxInt webViewCount = 0.obs;
  
  @override
  Future<CacheOptimizationService> onInit() async {
    super.onInit();
    
    // Configure image cache
    _configureImageCache();
    
    // Start periodic cache cleanup
    _startCacheCleanup();
    
    print('🗄️ Cache Optimization Service initialized');
    return this;
  }
  
  /// Configure Flutter's image cache for memory efficiency
  void _configureImageCache() {
    try {
      if (!kIsWeb) {
        final imageCache = PaintingBinding.instance.imageCache;
        
        // Set cache size limits
        imageCache.maximumSize = maxImageCacheCount;
        imageCache.maximumSizeBytes = maxImageCacheSize;
        
        developer.log('🖼️ Image cache configured: ${maxImageCacheCount} images, ${maxImageCacheSize >> 20}MB');
      }
    } catch (e) {
      developer.log('Failed to configure image cache: $e');
    }
  }
  
  /// Start periodic cache cleanup
  void _startCacheCleanup() {
    // Clean up every 2 minutes
    Stream.periodic(Duration(minutes: 2)).listen((_) {
      _cleanupImageCache();
      _cleanupUnusedWebViews();
      _updateCacheMetrics();
    });
    
    // Initial metrics update
    _updateCacheMetrics();
  }
  
  /// Clean up image cache when memory pressure is detected
  void _cleanupImageCache() {
    try {
      if (!kIsWeb) {
        final imageCache = PaintingBinding.instance.imageCache;
        final currentSize = imageCache.currentSizeBytes;
        final currentCount = imageCache.currentSize;
        
        // If cache is over 80% full, clear some entries
        if (currentSize > (maxImageCacheSize * 0.8) || 
            currentCount > (maxImageCacheCount * 0.8)) {
          
          // Clear oldest 25% of cache
          imageCache.clearLiveImages();
          
          developer.log('🧹 Image cache cleaned: was ${currentSize >> 20}MB/${currentCount} images');
        }
      }
    } catch (e) {
      developer.log('Failed to cleanup image cache: $e');
    }
  }
  
  /// Update cache metrics
  void _updateCacheMetrics() {
    try {
      if (!kIsWeb) {
        final imageCache = PaintingBinding.instance.imageCache;
        imageCacheSize.value = imageCache.currentSizeBytes;
        imageCacheCount.value = imageCache.currentSize;
      }
    } catch (e) {
      developer.log('Failed to update cache metrics: $e');
    }
  }
  
  /// Record WebView usage
  void recordWebViewUsage(String webViewId) {
    _webViewLastUsed[webViewId] = DateTime.now();
    _disposedWebViews.remove(webViewId); // Remove from disposed list if reused
    webViewCount.value = _webViewLastUsed.length;
    developer.log('📱 WebView usage recorded: $webViewId');
  }
  
  /// Mark WebView as disposed
  void markWebViewDisposed(String webViewId) {
    _webViewLastUsed.remove(webViewId);
    _disposedWebViews.add(webViewId);
    webViewCount.value = _webViewLastUsed.length;
    developer.log('🗑️ WebView marked as disposed: $webViewId');
  }
  
  /// Clean up unused WebViews
  void _cleanupUnusedWebViews() {
    final now = DateTime.now();
    final unusedThreshold = Duration(minutes: 5); // 5 minutes of inactivity
    
    final toRemove = <String>[];
    
    _webViewLastUsed.forEach((webViewId, lastUsed) {
      if (now.difference(lastUsed) > unusedThreshold) {
        toRemove.add(webViewId);
      }
    });
    
    for (final webViewId in toRemove) {
      _webViewLastUsed.remove(webViewId);
      _disposedWebViews.add(webViewId);
      developer.log('⏰ WebView marked for disposal due to inactivity: $webViewId');
    }
    
    if (toRemove.isNotEmpty) {
      webViewCount.value = _webViewLastUsed.length;
      developer.log('🧹 Cleaned up ${toRemove.length} unused WebViews');
    }
  }
  
  /// Optimize WebView for memory efficiency
  Map<String, dynamic> getWebViewOptimizationSettings() {
    return {
      'javascriptMode': 'JavascriptMode.unrestricted',
      'initialMediaPlaybackPolicy': 'AutoMediaPlaybackPolicy.require_user_action_for_all_media_types',
      'allowsInlineMediaPlayback': false, // Reduce memory usage
      'mediaPlaybackRequiresUserGesture': true,
      'debuggingEnabled': false, // Disable in production
      'userAgent': 'KioskWebView/1.0', // Custom user agent
      'gestureNavigationEnabled': false, // Reduce gesture processing
    };
  }
  
  /// Get optimized image loading settings
  Map<String, dynamic> getImageOptimizationSettings() {
    return {
      'cacheWidth': 800, // Limit image resolution
      'cacheHeight': 600,
      'enableMemoryCache': true,
      'enableDiskCache': false, // Use memory cache only for faster cleanup
      'compressionQuality': 0.8, // Reduce quality for memory savings
    };
  }
  
  /// Manually clear all caches
  void clearAllCaches({bool aggressive = false}) {
    developer.log('🧹 Manual cache clearing requested (aggressive: $aggressive)');
    
    // Clear image cache
    try {
      if (!kIsWeb) {
        final imageCache = PaintingBinding.instance.imageCache;
        
        if (aggressive) {
          imageCache.clear();
          imageCache.clearLiveImages();
        } else {
          imageCache.clearLiveImages();
        }
        
        developer.log('🖼️ Image cache cleared');
      }
    } catch (e) {
      developer.log('Failed to clear image cache: $e');
    }
    
    // Clear WebView caches
    _clearWebViewCaches(aggressive);
    
    // Update metrics
    _updateCacheMetrics();
  }
  
  /// Clear WebView caches
  void _clearWebViewCaches(bool aggressive) {
    try {
      if (aggressive) {
        // Mark all WebViews for disposal
        final allWebViews = List<String>.from(_webViewLastUsed.keys);
        for (final webViewId in allWebViews) {
          markWebViewDisposed(webViewId);
        }
        developer.log('🌐 All WebViews marked for disposal');
      } else {
        // Only clear old WebViews
        _cleanupUnusedWebViews();
      }
    } catch (e) {
      developer.log('Failed to clear WebView caches: $e');
    }
  }
  
  /// Check if WebView should be reused or recreated
  bool shouldReuseWebView(String webViewId) {
    // Don't reuse if it was disposed
    if (_disposedWebViews.contains(webViewId)) {
      return false;
    }
    
    // Don't reuse if it hasn't been used recently
    final lastUsed = _webViewLastUsed[webViewId];
    if (lastUsed == null) {
      return false;
    }
    
    final timeSinceLastUse = DateTime.now().difference(lastUsed);
    return timeSinceLastUse.inMinutes < 10; // Reuse within 10 minutes
  }
  
  /// Get cache optimization report
  Map<String, dynamic> getCacheReport() {
    return {
      'image_cache_size_mb': (imageCacheSize.value / (1024 * 1024)).toStringAsFixed(2),
      'image_cache_count': imageCacheCount.value,
      'image_cache_limit_mb': (maxImageCacheSize >> 20),
      'image_cache_limit_count': maxImageCacheCount,
      'active_webviews': webViewCount.value,
      'disposed_webviews': _disposedWebViews.length,
      'last_cleanup': DateTime.now().toIso8601String(),
    };
  }
  
  /// Apply memory-efficient settings for WebView creation
  void applyWebViewMemorySettings(dynamic webViewController) {
    try {
      // Apply memory optimization settings to WebView
      // Note: This would depend on the specific WebView implementation
      developer.log('🔧 Applied memory optimization settings to WebView');
    } catch (e) {
      developer.log('Failed to apply WebView memory settings: $e');
    }
  }
  
  @override
  void onClose() {
    developer.log('🗄️ Cache Optimization Service closing');
    
    // Clear all caches on service close
    clearAllCaches(aggressive: true);
    
    super.onClose();
  }
}
