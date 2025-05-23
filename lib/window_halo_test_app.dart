import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/controllers/halo_effect_controller.dart';
import 'app/controllers/window_halo_controller.dart';
import 'app/widgets/window_halo_wrapper.dart';

void main() {
  runApp(const WindowHaloTestApp());
}

class WindowHaloTestApp extends StatelessWidget {
  const WindowHaloTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Register controllers
    Get.put(HaloEffectControllerGetx(), permanent: true);
    Get.put(WindowHaloController(), permanent: true);

    return GetMaterialApp(
      title: 'Window Halo Test',
      theme: ThemeData.dark(),
      home: const WindowHaloTestScreen(),
    );
  }
}

class WindowHaloTestScreen extends StatelessWidget {
  const WindowHaloTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Window Halo Effect Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Test Window Halo Effects',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTestWindow("test_window_1", "Window 1"),
                  _buildTestWindow("test_window_2", "Window 2"),
                  _buildTestWindow("test_window_3", "Window 3"),
                  _buildTestWindow("test_window_4", "Window 4"),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _testHaloEffects(),
                    child: const Text("Run Halo Test"),
                  ),
                  ElevatedButton(
                    onPressed: () => _clearAllHalos(),
                    child: const Text("Clear All Halos"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestWindow(String windowId, String title) {
    return WindowHaloWrapper(
      windowId: windowId,
      child: Card(
        elevation: 4,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text('ID: $windowId'),
              const SizedBox(height: 16),
              GetBuilder<WindowHaloController>(builder: (controller) {
                return Obx(() {
                  final isActive = controller.hasActiveHalo(windowId);
                  return Text(
                    isActive ? 'Halo ACTIVE' : 'No Halo',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                });
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _testHaloEffects() async {
    final controller = Get.find<WindowHaloController>();

    // Red halo on window 1
    controller.enableHaloForWindow(
      windowId: "test_window_1",
      color: Colors.red,
    );

    await Future.delayed(const Duration(seconds: 2));

    // Blue halo on window 2
    controller.enableHaloForWindow(
      windowId: "test_window_2",
      color: Colors.blue,
    );

    await Future.delayed(const Duration(seconds: 2));

    // Green pulsing halo on window 3
    controller.enableHaloForWindow(
      windowId: "test_window_3",
      color: Colors.green,
      pulseMode: HaloPulseMode.gentle,
      pulseDuration: const Duration(milliseconds: 3000),
    );

    await Future.delayed(const Duration(seconds: 2));

    // Alert pulsing halo on window 4
    controller.enableHaloForWindow(
      windowId: "test_window_4",
      color: Colors.orange,
      pulseMode: HaloPulseMode.alert,
      pulseDuration: const Duration(milliseconds: 1000),
    );
  }

  void _clearAllHalos() {
    final controller = Get.find<WindowHaloController>();
    controller.disableHaloForWindow("test_window_1");
    controller.disableHaloForWindow("test_window_2");
    controller.disableHaloForWindow("test_window_3");
    controller.disableHaloForWindow("test_window_4");
  }
}
