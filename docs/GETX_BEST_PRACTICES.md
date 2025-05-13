# GetX Best Practices

This document outlines best practices when using the GetX state management library in Flutter, specifically as implemented in the Flutter GetX Kiosk project.

## Dependency Injection

### 1. Initialization Order

The order of dependency initialization is critical. Follow this pattern:

```dart
// 1. Core services that don't depend on other services
Get.put<StorageService>(StorageService().init(), permanent: true);
Get.put<ThemeService>(ThemeService().init(), permanent: true);

// 2. Services that depend on core services
Get.put<PlatformSensorService>(PlatformSensorService().init(), permanent: true);

// 3. Controllers that orchestrate services
Get.put(AppStateController(), permanent: true);

// 4. Feature-specific services
Get.put<WebSocketService>(WebSocketService().init(), permanent: true);
Get.put<MqttService>(MqttService(storageService, sensorService).init(), permanent: true);
```

### 2. Service Registration Methods

- **`Get.put()`**: Use for immediate initialization and when the dependency is required right away.
- **`Get.lazyPut()`**: Use when the dependency might not be needed immediately.
- **`Get.putAsync()`**: Use for services that require async initialization.

### 3. Service Options

- **`permanent: true`**: Use for services that should persist throughout the entire app lifecycle.
- **`fenix: true`**: Use for controllers that should be recreated when accessed after being removed.

## Controllers and Reactivity

### 1. Controller Lifecycle

Always handle controller lifecycle properly:

```dart
@override
void onInit() {
  super.onInit();
  // Initialize resources, subscribe to streams
}

@override
void onClose() {
  // Dispose resources, cancel subscriptions
  textController.dispose();
  timer?.cancel();
  super.onClose();
}
```

### 2. Reactive Programming

Use reactive programming for UI updates:

```dart
// Define observable
final RxInt count = 0.obs;

// Listen for changes
ever(count, (value) {
  // React to changes
  updateUI();
});

// Worker for multiple observables
workers = [
  ever(count, (_) => print('Count changed')),
  ever(name, (_) => print('Name changed')),
];

@override
void onClose() {
  // Dispose workers if stored in a list
  workers.forEach((worker) => worker.dispose());
  super.onClose();
}
```

### 3. Safe Dependency Access

Always handle potential missing dependencies:

```dart
late final MqttService _mqttService;

@override
void onInit() {
  super.onInit();
  _initDependencies();
}

void _initDependencies() {
  try {
    _mqttService = Get.find<MqttService>();
  } catch (e) {
    print('MqttService not found: $e');
    // Provide fallback or notify user
  }
}
```

## UI and Bindings

### 1. Binding Structure

Create proper bindings for each page:

```dart
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
  }
}
```

### 2. GetView Usage

Use GetView for type-safe controller access:

```dart
class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Obx(() => Text('Count: ${controller.count.value}')),
    );
  }
}
```

### 3. GetX vs Obx

- Use `Obx` for simple reactive UI updates.
- Use `GetX` when you need more control over when rebuilds happen.

```dart
// Simple case
Obx(() => Text('Count: ${controller.count.value}'))

// More control
GetX<HomeController>(
  builder: (controller) => Text('Count: ${controller.count.value}'),
  init: HomeController(),
  initState: (_) => print('Widget initialized'),
  dispose: (_) => print('Widget disposed'),
)
```

## Routing

### 1. Named Routes

Use named routes for navigation:

```dart
// Definition
static final routes = [
  GetPage(
    name: Routes.HOME,
    page: () => const HomeView(),
    binding: HomeBinding(),
  ),
];

// Navigation
Get.toNamed(Routes.HOME);
```

### 2. Route Arguments

Pass and retrieve arguments:

```dart
// Passing arguments
Get.toNamed(Routes.DETAILS, arguments: {'id': 1, 'name': 'Item'});

// Retrieving arguments
final args = Get.arguments;
final id = args['id'];
```

## Error Handling

### 1. Try-Catch for Service Calls

Always wrap service calls in try-catch blocks:

```dart
Future<void> fetchData() async {
  try {
    final result = await apiService.getData();
    data.value = result;
  } catch (e) {
    print('Error fetching data: $e');
    error.value = e.toString();
    // Show error to user
    Get.snackbar('Error', 'Failed to load data');
  }
}
```

### 2. Safe Controller Access

Check if controllers are available before accessing them:

```dart
void someFunction() {
  if (Get.isRegistered<HomeController>()) {
    final controller = Get.find<HomeController>();
    controller.doSomething();
  }
}
```

## Testing

### 1. Service Mocking

Create mock versions of your services for testing:

```dart
class MockStorageService extends Mock implements StorageService {}

void main() {
  late HomeController controller;
  late MockStorageService mockStorageService;
  
  setUp(() {
    mockStorageService = MockStorageService();
    Get.put<StorageService>(mockStorageService);
    controller = HomeController();
  });
  
  tearDown(() {
    Get.reset();
  });
  
  test('should save data', () {
    // Test controller with mock service
  });
}
```

### 2. Reset GetX Between Tests

Always reset GetX between tests:

```dart
tearDown(() {
  Get.reset();
});
```

## Performance

### 1. Avoid Rebuilding Entire Trees

Use selective rebuilds with `GetBuilder` when needed:

```dart
GetBuilder<HomeController>(
  id: 'counter',
  builder: (controller) => Text('Count: ${controller.count}'),
)

// In controller
update(['counter']); // Only widgets with id='counter' will update
```

### 2. Debounce User Input

Use debounce for performance-heavy operations:

```dart
final searchQuery = ''.obs;
late Worker debounceWorker;

@override
void onInit() {
  super.onInit();
  
  debounceWorker = debounce(
    searchQuery,
    (_) => search(),
    time: Duration(milliseconds: 500),
  );
}

@override
void onClose() {
  debounceWorker.dispose();
  super.onClose();
}
```

## General Tips

1. Keep controllers focused on a single responsibility
2. Prefer composition over inheritance for reusing functionality
3. Document your code, especially complex reactive patterns
4. Use `permanent: true` sparingly, only for services that truly need to persist
5. Consider using GetStorage for simple persistent storage needs
6. Structure your project with a clear separation of concerns