# Flutter GetX Kiosk - Migration Guide

This guide helps you migrate your code to use the updated components and fix the black screen issue and other problems.

## Step 1: Update Your main.dart

Replace your current main.dart with the optimized version that uses InitialBinding:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:media_kit/media_kit.dart';

import 'app/core/theme/app_theme.dart';
import 'app/core/bindings/initial_binding.dart';
import 'app/routes/app_pages_fixed.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize GetStorage for persistent settings
  await GetStorage.init();
  
  // Initialize MediaKit for media playback
  MediaKit.ensureInitialized();
  
  runApp(const KioskApp());
}

class KioskApp extends StatelessWidget {
  const KioskApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter GetX Kiosk',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppPagesFixed.INITIAL,
      getPages: AppPagesFixed.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

## Step 2: Use the Consolidated MQTT Service

The `mqtt_service_consolidated.dart` file replaces both `mqtt_service.dart` and `mqtt_service_fixed.dart`. Update your imports to:

```dart
import '../services/mqtt_service_consolidated.dart';
```

## Step 3: Use the Consolidated Settings Controller

Use the new unified settings controller in your settings views:

```dart
import '../controllers/settings_controller.dart';

class YourSettingsView extends GetView<SettingsController> {
  // Your view code here
}
```

## Step 4: Fix Import References in Your Bindings

Make sure all your files reference the fixed home binding:

```dart
import '../modules/home/bindings/home_binding_fixed.dart';
```

## Step 5: Update Text Input Fields

Make sure all your text input fields use these best practices to fix the backwards text issue:

```dart
TextField(
  controller: controller.yourTextEditingController, // Use controller's TextEditingController
  textDirection: TextDirection.ltr, // Force left-to-right text
  decoration: InputDecoration(
    labelText: 'Your Label',
    hintText: 'Your Hint',
  ),
  onChanged: (value) {
    // Update your Rx variable here
    controller.yourRxVariable.value = value;
  },
)
```

## Step 6: Check for macOS Battery Detection Issue

If your app needs to run on macOS, make sure you have the special handling for battery detection:

```dart
if (Platform.isMacOS) {
  // Handle macOS battery detection differently
  try {
    // Use a fallback method or return a default value
    batteryLevel = 100; // Default value when unable to get actual battery level
  } catch (e) {
    batteryLevel = 0;
  }
} else {
  // Normal battery detection for other platforms
  batteryLevel = await battery.batteryLevel;
}
```

## Step 7: Replace Your App Routes

Use the consolidated app_pages_fixed.dart file for your routes:

```dart
// When navigating
Get.toNamed(Routes.SETTINGS);

// For app setup
initialRoute: AppPagesFixed.INITIAL,
getPages: AppPagesFixed.routes,
```

## Step 8: Test Your App

After making these changes:

1. **Run in Debug Mode**: Check for any dependency injection errors
2. **Test All Features**: Ensure all features work as expected
3. **Check for Black Screen**: Verify the app starts correctly without any black screen
4. **Test MQTT**: Verify MQTT connects correctly
5. **Test Settings**: Verify settings save and load correctly

## Additional Resources

- See the `FIXES_IMPLEMENTED_NEW.md` file for a complete list of changes
- Refer to `GETX_BEST_PRACTICES.md` for recommended patterns
- Check the updated controller files for examples of proper initialization
