# GetX Best Practices and State Management

## Common Error: setState() or markNeedsBuild() called during build

This document provides solutions to the common issue of setState/markNeedsRebuild being called during build when using GetX.

### Root Causes

1. **Controller Lookups During Build**: Using `Get.find()` inside a build method can sometimes trigger controller initialization, which might call methods that update the UI

2. **Cascading State Changes**: Theme changes or other global state changes can trigger cascading updates that conflict with the build cycle

3. **Reactive UI Updates**: GetX's reactive system sometimes attempts to update the UI while it's still being built

### Solutions We've Implemented

#### 1. Cache Controllers in State Objects

```dart
class MyWidgetState extends State<MyWidget> {
  // Cache controllers in state class
  late final MyController controller;
  
  @override
  void initState() {
    super.initState();
    // Initialize in initState, not during build
    controller = Get.find<MyController>();
  }
}
```

#### 2. Use Future.microtask() for UI Updates

```dart
void setTheme(ThemeData theme) {
  // Defer UI updates until after current build cycle
  Future.microtask(() {
    Get.changeTheme(theme);
  });
}
```

#### 3. Prefer Obx() Over Direct Controller Access

```dart
// Better approach - isolates reactivity
Obx(() => Text(controller.value.toString()))

// Rather than:
Text(Get.find<MyController>().value.toString())
```

#### 4. Use Conditional Updates

```dart
void updateBounds(Rect newBounds) {
  // Only update if actually changed
  if (_bounds != newBounds) {
    _bounds = newBounds;
    update();
  }
}
```

### GetX Controller Guidelines

1. **Initialize Early**: Register all controllers in bindings
2. **Lazy Loading**: Use `lazyPut` for controllers not needed immediately
3. **Scoped Controllers**: Use `put` with appropriate tags for scoped controllers
4. **Clean Up**: Handle proper controller disposal

### Avoiding Rebuild Loops

1. **One-way Data Flow**: Controllers update state, UI reacts to state changes
2. **Batch Updates**: Group multiple state changes together
3. **State Normalization**: Avoid derived or duplicate state
4. **Strategic Updates**: Use IDs to only update affected components

### Examples from Our Codebase

#### InitialBinding:
```dart
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services first
    Get.put<StorageService>(StorageService().init(), permanent: true);
    
    // Secondary services with dependency on core services
    Get.put<ThemeService>(ThemeService().init(), permanent: true);
    
    // Controllers dependent on services
    Get.lazyPut<AppStateController>(() => AppStateController(), fenix: true);
  }
}
```

#### Deferred Theme Updates:
```dart
void setDarkMode(bool isDark) {
  _isDarkMode.value = isDark;
  _storage.write('isDarkMode', isDark);
  
  // Theme changes deferred to avoid setState during build
  Future.microtask(() {
    Get.changeThemeMode(getThemeMode());
  });
}
```

By following these practices, we've eliminated the "setState() or markNeedsBuild() called during build" errors and improved the overall stability of the app.