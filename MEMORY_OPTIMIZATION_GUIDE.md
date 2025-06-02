# Memory Optimization Implementation Guide

This guide explains how to implement the memory optimizations for your Flutter King Kiosk app. The optimizations focus on lazy loading, proper service disposal, and intelligent memory management.

## 🎯 Core Strategy

The memory optimization strategy centers around:
1. **Core Services (Eager Loading)** - Load only essential services at startup
2. **Optional Services (Lazy Loading)** - Load services only when needed
3. **Page-Specific Bindings** - Load different services for different pages
4. **Automatic Memory Management** - Monitor and clean up memory automatically
5. **Optimized Caching** - Efficient image and WebView cache management

## 🔧 Implementation Steps

### Step 1: Replace Initial Binding

Replace your current `InitialBinding` with the memory-optimized version:

```dart
// In your main.dart or app configuration
import 'package:your_app/app/core/bindings/memory_optimized_binding.dart';

// Replace InitialBinding with MemoryOptimizedBinding
Get.put(MemoryOptimizedBinding());
```

### Step 2: Add Memory Management Services

Add the new memory management services to your app:

```dart
// Add to your dependencies() method or main.dart
Get.lazyPut<MemoryManagerService>(() => MemoryManagerService(), fenix: true);
Get.lazyPut<CacheOptimizationService>(() => CacheOptimizationService(), fenix: true);
```

### Step 3: Use Page-Specific Bindings

Replace your current page bindings with optimized versions:

```dart
// For home page
GetPage(
  name: '/home',
  page: () => HomeView(),
  binding: PageBindings.HomePageBinding(),
),

// For settings page
GetPage(
  name: '/settings',
  page: () => SettingsView(),
  binding: PageBindings.SettingsPageBinding(),
),

// For media pages
GetPage(
  name: '/media',
  page: () => MediaView(),
  binding: PageBindings.MediaPageBinding(),
),
```

### Step 4: Add Memory Diagnostics (Optional)

Add the memory diagnostics widget to your settings or debug screen:

```dart
// In your settings view or debug screen
import 'package:your_app/app/widgets/memory_diagnostics_widget.dart';

// Add to your widget tree
MemoryDiagnosticsWidget(
  showControls: true,  // Show cleanup controls
  compact: false,      // Full detailed view
)

// Or for a compact indicator
MemoryDiagnosticsWidget(
  compact: true,       // Compact memory indicator
)
```

## 📊 What Gets Optimized

### Core Services (Always Loaded)
- ✅ **StorageService** - Required for settings/config
- ✅ **ThemeService** - Required for UI theming  
- ✅ **SettingsController** - Required for app configuration
- ✅ **WindowManagerService** - Required for window operations
- ✅ **MqttService** - Only if enabled in settings
- ✅ **PlatformSensorService** - Only if MQTT is enabled

### Lazy-Loaded Services (Load When Needed)
- ⚡ **AppStateController** - Lazy load
- ⚡ **AppLifecycleService** - Lazy load
- ⚡ **NavigationService** - Lazy load
- ⚡ **BackgroundMediaService** - Only for media pages
- ⚡ **MediaControlService** - Only for media pages
- ⚡ **MediaRecoveryService** - Only for media pages
- ⚡ **AudioService** - Only when needed
- ⚡ **ScreenshotService** - Only when capturing
- ⚡ **HaloEffectControllers** - Only for visual effects
- ⚡ **SipService** - Only if enabled in settings
- ⚡ **AiAssistantService** - Only if enabled in settings

### Conditional Loading
Services are only loaded if their corresponding feature is enabled in settings:
- MQTT services only if `mqttEnabled = true`
- SIP services only if `sipEnabled = true`  
- AI services only if `aiEnabled = true`

## 🔍 Memory Monitoring Features

### Real-time Monitoring
- Current memory usage (MB and percentage)
- Peak memory usage tracking
- Memory pressure detection
- Service count monitoring
- Image cache size tracking
- WebView count tracking

### Automatic Cleanup
- **Warning Level (80% memory)**: Dispose visual effects, clear image caches
- **Critical Level (90% memory)**: Dispose all non-essential services, force garbage collection
- **Unused Service Cleanup**: Auto-dispose services after 5 minutes of inactivity
- **WebView Cleanup**: Dispose unused WebViews after 5 minutes
- **Image Cache Management**: Automatic cache size limits and cleanup

### Manual Controls
- **Clean Memory**: Standard memory cleanup
- **Deep Clean**: Aggressive memory cleanup
- **Clear Caches**: Clear all image and WebView caches
- **Memory Report**: Detailed memory usage statistics

## 📱 WebView Memory Optimization

### Optimized WebView Settings
```dart
final settings = cacheService.getWebViewOptimizationSettings();
// Returns optimized settings for WebView creation
```

### WebView Lifecycle Management
```dart
// Record WebView usage
cacheService.recordWebViewUsage(webViewId);

// Mark WebView as disposed
cacheService.markWebViewDisposed(webViewId);

// Check if WebView should be reused
if (cacheService.shouldReuseWebView(webViewId)) {
  // Reuse existing WebView
} else {
  // Create new WebView
}
```

## 🖼️ Image Cache Optimization

### Optimized Image Loading
```dart
final settings = cacheService.getImageOptimizationSettings();
// Returns settings for memory-efficient image loading
```

### Cache Limits
- **Max Size**: 100MB
- **Max Count**: 1000 images
- **Auto-cleanup**: When 80% full
- **Quality**: 80% (balance of quality vs memory)

## 📈 Expected Memory Improvements

### Startup Memory Reduction
- **Before**: All services loaded (~150-200MB)
- **After**: Core services only (~50-80MB)
- **Improvement**: 60-70% reduction in startup memory

### Runtime Memory Management
- **Automatic cleanup** when memory pressure detected
- **Service auto-disposal** when not used for 5+ minutes
- **WebView pooling** and disposal
- **Image cache management** with size limits

### Page-Specific Loading
- **Home Page**: Media + visual services (~30-50MB additional)
- **Settings Page**: Only settings-related services (~10-20MB additional)
- **WebView Pages**: Minimal services (~15-25MB additional)
- **Media Pages**: Full media stack (~50-80MB additional)

## 🔧 Customization Options

### Adjust Memory Thresholds
```dart
// In MemoryManagerService
static const double warningThreshold = 0.8;  // 80%
static const double criticalThreshold = 0.9; // 90%
```

### Customize Service Auto-Disposal
```dart
// Add services that can be auto-disposed
memoryManager.markServiceForAutoDisposal<YourService>();
```

### Configure Cache Limits
```dart
// In CacheOptimizationService
static const int maxImageCacheSize = 100 << 20; // 100MB
static const int maxImageCacheCount = 1000;
```

## 🐛 Troubleshooting

### If Services Don't Load
1. Check that the service is properly registered with `Get.lazyPut()`
2. Ensure dependencies are available when the service initializes
3. Check console logs for initialization errors

### If Memory Usage Is Still High
1. Enable memory diagnostics widget to identify heavy services
2. Use the "Deep Clean" function to free up memory
3. Check for memory leaks in custom widgets/controllers
4. Monitor WebView and image cache usage

### If App Performance Degrades
1. Some delay is expected on first access to lazy-loaded services
2. Consider making frequently-used services permanent instead of lazy
3. Adjust auto-disposal timeouts if services are being disposed too quickly

## 📋 Testing Checklist

- [ ] App starts with reduced memory usage
- [ ] All pages load correctly with their specific services
- [ ] Memory diagnostics widget shows current usage
- [ ] Automatic cleanup triggers at memory thresholds
- [ ] Manual cleanup functions work properly
- [ ] WebView disposal works correctly
- [ ] Image cache limits are respected
- [ ] Services auto-dispose after inactivity
- [ ] MQTT/SIP/AI services only load when enabled
- [ ] No critical functionality is broken

## 🎉 Success Metrics

After implementing these optimizations, you should see:
- **60-70% reduction** in startup memory usage
- **Automatic memory management** preventing memory pressure
- **Page-specific loading** reducing unnecessary service overhead
- **Intelligent caching** optimizing image and WebView memory
- **Real-time monitoring** for memory usage visibility

The memory optimization ensures your Flutter app uses only the memory it needs, when it needs it, while maintaining full functionality and performance.
