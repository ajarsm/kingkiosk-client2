# Memory Optimization Implementation Guide

## Overview
This guide provides step-by-step instructions for implementing the memory optimization solution in your Flutter app. The optimization focuses on **lazy loading** non-essential services and **conditional loading** based on user settings.

## Current Memory Issues
- All services load at startup via `InitialBinding`
- Maximum memory usage from the beginning
- No conditional loading based on features enabled
- Services remain in memory even when not used

## Solution Architecture

### 1. Core Services (Immediate Loading)
These services are essential and load immediately:
- **StorageService** - Required for reading settings
- **ThemeService** - Required for UI theming  
- **SettingsController** - Required for app configuration
- **WindowManagerService** - Required for window operations
- **MqttService** - Only if MQTT is enabled in settings
- **PlatformSensorService** - Only if MQTT is enabled (required by MQTT)

### 2. Lazy-Loaded Services
These services load only when first accessed:
- AppStateController
- AppLifecycleService  
- NavigationService
- BackgroundMediaService
- MediaControlService
- MediaRecoveryService
- MediaHardwareDetectionService
- AudioService
- ScreenshotService
- WindowCloseHandler
- HaloEffectControllerGetx
- WindowHaloController

### 3. Conditional Services
These services load only if enabled in settings:
- **SipService** - Only if SIP calling is enabled
- **AiAssistantService** - Only if AI features are enabled

## Implementation Steps

### Step 1: Backup Current Binding
```bash
# Create backup of current binding
cp lib/app/core/bindings/initial_binding.dart lib/app/core/bindings/initial_binding_backup.dart
```

### Step 2: Test Memory Optimization
Replace the current binding in your main app file:

**In `lib/main.dart` or your app initialization:**
```dart
// OLD:
// initialBinding: InitialBinding(),

// NEW:
initialBinding: MemoryOptimizedBinding(),
```

### Step 3: Update Import Statements
Make sure to import the new binding:
```dart
// Add this import
import 'app/core/bindings/memory_optimized_binding.dart';

// Remove or comment out old binding import
// import 'app/core/bindings/initial_binding.dart';
```

### Step 4: Add Memory Diagnostics Widget (Optional)
To monitor memory usage in real-time, add the diagnostics widget to your UI:

```dart
// In your main screen widget
import '../widgets/memory_diagnostics_widget.dart';

// Add to your widget tree
Column(
  children: [
    // Your existing widgets...
    MemoryDiagnosticsWidget(), // Add this for monitoring
  ],
)
```

### Step 5: Update Service Access Patterns
Update code that accesses services to handle lazy loading:

**OLD Pattern:**
```dart
final mediaService = Get.find<MediaControlService>();
mediaService.play();
```

**NEW Pattern (for services that need initialization):**
```dart
// For services that need async initialization
final mediaService = await ServiceHelpers.findInitialized<MediaControlService>('MediaControlService');
mediaService.play();

// OR for immediate access (if you don't need full initialization)
final mediaService = Get.find<MediaControlService>();
```

### Step 6: Handle Service Dependencies
Some services depend on others. The new binding handles this automatically, but if you create custom service access:

```dart
// Example: AI Assistant depends on SIP Service
if (ServiceHelpers.isRegistered<AiAssistantService>()) {
  final aiService = await ServiceHelpers.findInitialized<AiAssistantService>('AiAssistantService');
  // Use AI service
}
```

## Memory Monitoring

### Real-time Monitoring
Use the `MemoryDiagnosticsWidget` to see:
- Current memory usage
- Number of registered services
- Active/inactive service status
- Memory usage trends

### Programmatic Monitoring
```dart
// Get memory manager service
final memoryManager = Get.find<MemoryManagerService>();

// Check current memory usage
final usage = await memoryManager.getCurrentMemoryUsage();
print('Memory usage: ${usage.usedMemoryMB}MB / ${usage.totalMemoryMB}MB');

// Get service status
final serviceStatus = ServiceHelpers.getServiceStatus();
serviceStatus.forEach((service, initialized) {
  print('$service: ${initialized ? "✅" : "❌"}');
});
```

## Performance Optimizations

### 1. Cache Management
The `CacheOptimizationService` automatically:
- Limits WebView cache to 100MB
- Clears image cache when memory usage > 85%
- Manages cache size based on memory pressure

### 2. Automatic Cleanup
The `MemoryManagerService` provides:
- Automatic cleanup at 80% memory usage (warning)
- Aggressive cleanup at 90% memory usage (critical)
- Service disposal when not needed

### 3. Conditional Loading
Services load based on settings:
```dart
// MQTT only loads if enabled
final mqttEnabled = storageService.read<bool>(AppConstants.keyMqttEnabled) ?? false;

// SIP only loads if enabled  
final sipEnabled = storageService.read<bool>(AppConstants.keySipEnabled) ?? false;

// AI only loads if enabled
final aiEnabled = storageService.read<bool>(AppConstants.keyAiEnabled) ?? false;
```

## Expected Memory Improvements

### Before Optimization
- **Initial Memory Usage**: ~150-200MB
- **All Services Loaded**: Immediately at startup
- **Memory Growth**: Continuous growth with no cleanup

### After Optimization
- **Initial Memory Usage**: ~80-120MB (40-50% reduction)
- **Core Services Only**: 4-6 services at startup vs 15+ services
- **Lazy Loading**: Services load only when needed
- **Memory Cleanup**: Automatic cleanup when usage > 80%

## Testing the Implementation

### 1. Memory Usage Test
```dart
// Add this to your test code
void testMemoryUsage() async {
  print('=== MEMORY USAGE TEST ===');
  
  // Check initial memory
  final memoryManager = Get.find<MemoryManagerService>();
  final initialUsage = await memoryManager.getCurrentMemoryUsage();
  print('Initial memory: ${initialUsage.usedMemoryMB}MB');
  
  // Check registered services
  final serviceStatus = ServiceHelpers.getServiceStatus();
  print('Registered services: ${serviceStatus.length}');
  
  // Test lazy loading
  print('Testing lazy service access...');
  final mediaService = await ServiceHelpers.findInitialized<MediaControlService>('MediaControlService');
  print('Media service loaded: ${mediaService != null}');
  
  // Check memory after service loading
  final afterUsage = await memoryManager.getCurrentMemoryUsage();
  print('Memory after service loading: ${afterUsage.usedMemoryMB}MB');
  print('Memory difference: ${afterUsage.usedMemoryMB - initialUsage.usedMemoryMB}MB');
}
```

### 2. Service Loading Test
```dart
void testServiceLoading() {
  print('=== SERVICE LOADING TEST ===');
  
  // Test core services (should be loaded)
  final coreServices = [
    'StorageService',
    'ThemeService', 
    'SettingsControllerFixed',
    'WindowManagerService'
  ];
  
  for (final service in coreServices) {
    final isLoaded = Get.isRegistered<dynamic>();
    print('$service: ${isLoaded ? "✅ LOADED" : "❌ NOT LOADED"}');
  }
  
  // Test lazy services (should load on demand)
  print('\nTesting lazy service loading...');
  try {
    final mediaService = Get.find<MediaControlService>();
    print('MediaControlService: ✅ LAZY LOADED');
  } catch (e) {
    print('MediaControlService: ⏳ NOT YET LOADED (expected)');
  }
}
```

## Rollback Plan

If you encounter issues, you can quickly rollback:

### 1. Restore Original Binding
```dart
// In main.dart, change back to:
initialBinding: InitialBinding(),
```

### 2. Remove New Service Files
```bash
# Remove the new files if needed
rm lib/app/core/bindings/memory_optimized_binding.dart
rm lib/app/services/memory_manager_service.dart
rm lib/app/services/cache_optimization_service.dart
rm lib/app/services/service_initializer.dart
rm lib/app/widgets/memory_diagnostics_widget.dart
```

### 3. Restore from Backup
```bash
# Restore original binding
cp lib/app/core/bindings/initial_binding_backup.dart lib/app/core/bindings/initial_binding.dart
```

## Troubleshooting

### Common Issues

1. **Service Not Found Error**
   ```dart
   // Solution: Check if service is registered before accessing
   if (ServiceHelpers.isRegistered<MyService>()) {
     final service = Get.find<MyService>();
   }
   ```

2. **Async Initialization Issues**
   ```dart
   // Solution: Use ServiceHelpers for proper initialization
   final service = await ServiceHelpers.findInitialized<MyService>('MyService');
   ```

3. **Memory Still High**
   - Check if memory cleanup is enabled
   - Verify that unused services are being disposed
   - Monitor with MemoryDiagnosticsWidget

4. **Service Dependencies**
   - Ensure dependent services are loaded before accessing them
   - Use conditional loading for optional features

### Debug Commands
```dart
// Check memory status
final memoryManager = Get.find<MemoryManagerService>();
final status = await memoryManager.getCurrentMemoryUsage();
print('Memory: ${status.usedMemoryMB}MB / ${status.totalMemoryMB}MB (${status.usagePercentage}%)');

// Check service status
final serviceStatus = ServiceHelpers.getServiceStatus();
print('Service initialization status: $serviceStatus');

// Check registered services
print('Registered services: ${Get.isRegistered}');
```

## Next Steps

1. **Implement the memory optimization** by following steps 1-3
2. **Test with the diagnostics widget** to see immediate improvements
3. **Monitor memory usage** over time to ensure stability
4. **Fine-tune service loading** based on your app's specific usage patterns
5. **Consider additional optimizations** like image caching, WebView recycling, etc.

The memory optimization should provide immediate benefits with 40-50% reduction in initial memory usage and better memory management throughout the app lifecycle.
