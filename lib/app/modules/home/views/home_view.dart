import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('King Kiosk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            color: Colors.blueGrey.shade100,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Icon(Icons.device_hub),
                const SizedBox(width: 8),
                Obx(() => Text('Device: ${controller.deviceModel.value}')),
                const Spacer(),
                const Icon(Icons.battery_std),
                const SizedBox(width: 4),
                Obx(() => Text('${controller.batteryLevel.value}%')),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'King Kiosk',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to King Kiosk!',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Get.snackbar(
                        'Hello', 
                        'Welcome to King Kiosk!',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    child: const Text('Show Welcome Message'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}