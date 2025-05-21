import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            colors: [Colors.blueAccent, Colors.cyanAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
          child: Text(
            'King Kiosk',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () => Get.toNamed('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
              Colors.blue.shade200
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Status bar
            Container(
              margin: const EdgeInsets.only(top: 80),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.device_hub, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Obx(() => Text('Device: ${controller.deviceModel.value}',
                      style: TextStyle(fontWeight: FontWeight.w600))),
                  Spacer(),
                  Icon(Icons.battery_std, color: Colors.green),
                  SizedBox(width: 4),
                  Obx(() => Text('${controller.batteryLevel.value}%',
                      style: TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Center(
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (rect) => LinearGradient(
                            colors: [Colors.blueAccent, Colors.cyanAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(rect),
                          child: Icon(Icons.desktop_windows_rounded,
                              size: 64, color: Colors.white),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Welcome to King Kiosk!',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade800),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Your secure, modern kiosk experience.',
                          style: TextStyle(
                              fontSize: 16, color: Colors.blueGrey.shade500),
                        ),
                        SizedBox(height: 32),
                        ElevatedButton.icon(
                          icon: Icon(Icons.celebration_rounded),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                          onPressed: () {
                            Get.snackbar(
                              'Hello',
                              'Welcome to King Kiosk!',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.blueAccent,
                              colorText: Colors.white,
                              borderRadius: 16,
                              margin: EdgeInsets.all(16),
                            );
                          },
                          label: Text('Show Welcome Message',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
