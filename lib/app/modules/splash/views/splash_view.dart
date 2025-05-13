import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or app icon
            Icon(
              Icons.desktop_windows,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 30),
            // App title
            Text(
              'Kiosk App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            // Status message
            Obx(() => Text(
              controller.initStatus.value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            )),
          ],
        ),
      ),
    );
  }
}