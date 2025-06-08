import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lib/app/services/platform_kiosk_service.dart';
import 'lib/app/services/android_kiosk_service.dart';
import 'lib/app/widgets/kiosk_control_widget.dart';

/// Simple test app to demonstrate cross-platform kiosk functionality
/// This shows how the existing KioskControlWidget now works with PlatformKioskService
class TestCrossPlatformKioskApp extends StatelessWidget {
  const TestCrossPlatformKioskApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Cross-Platform Kiosk Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestKioskPage(),
      // Register the PlatformKioskService
      initialBinding: BindingsBuilder(() {
        Get.put<PlatformKioskService>(PlatformKioskService(), permanent: true);
      }),
    );
  }
}

class TestKioskPage extends StatelessWidget {
  const TestKioskPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cross-Platform Kiosk Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Platform Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      // Check if PlatformKioskService is available
                      if (Get.isRegistered<PlatformKioskService>()) {
                        final service = Get.find<PlatformKioskService>();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('✅ PlatformKioskService: Available'),
                            Text('🖥️ Platform: ${service.platformName}'),
                            Text('🎛️ Control Level: ${service.controlLevel}%'),
                            Text(
                                '📊 Status: ${service.controlLevelDescription}'),
                            Text(
                                '🔒 Kiosk Active: ${service.isKioskModeActive ? "Yes" : "No"}'),
                          ],
                        );
                      } else {
                        return const Text(
                            '❌ PlatformKioskService: Not Available');
                      }
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Integration test info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔧 Integration Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The KioskControlWidget below now automatically detects if PlatformKioskService is available and uses it for cross-platform support, otherwise falls back to AndroidKioskService.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This means your existing kiosk button now works on all platforms!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // The actual kiosk control widget (your existing widget, now cross-platform!)
            const KioskControlWidget(),

            const SizedBox(height: 16),

            // Test actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚡ Test Actions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _testPlatformDetection(),
                        child: const Text('Test Platform Detection'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _testServiceAvailability(),
                        child: const Text('Test Service Availability'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testPlatformDetection() {
    if (Get.isRegistered<PlatformKioskService>()) {
      final service = Get.find<PlatformKioskService>();
      Get.snackbar(
        '📱 Platform Detection',
        'Running on ${service.platformName} with ${service.controlLevel}% control level',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        '❌ Service Not Found',
        'PlatformKioskService is not registered',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _testServiceAvailability() {
    final hasAndroid = Get.isRegistered<AndroidKioskService>();
    final hasPlatform = Get.isRegistered<PlatformKioskService>();

    Get.dialog(
      AlertDialog(
        title: const Text('🔍 Service Availability'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'AndroidKioskService: ${hasAndroid ? "✅ Registered" : "❌ Not Registered"}'),
            Text(
                'PlatformKioskService: ${hasPlatform ? "✅ Registered" : "❌ Not Registered"}'),
            const SizedBox(height: 16),
            const Text(
              'Your KioskControlWidget automatically chooses the best available service!',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// To run this test:
// flutter run --target=test_cross_platform_kiosk.dart
void main() {
  runApp(const TestCrossPlatformKioskApp());
}
