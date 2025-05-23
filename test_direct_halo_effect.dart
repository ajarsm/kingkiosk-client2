// Test script to exercise the HaloEffectControllerGetx directly without MQTT
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'lib/app/controllers/halo_effect_controller.dart';
import 'lib/app/widgets/halo_effect/halo_effect_overlay.dart';

void main() async {
  // Initialize Flutter bindings
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up controller
  final HaloEffectControllerGetx controller = HaloEffectControllerGetx();
  Get.put(controller, permanent: true);

  // Test with red color
  print('\n🧪 Testing with red color - gentle pulse');
  controller.enableHaloEffect(
    color: Color(0xFFFF0000), // Red
    pulseMode: HaloPulseMode.gentle,
    pulseDuration: Duration(milliseconds: 2000),
  );

  // Wait a bit to simulate animation
  await Future.delayed(Duration(seconds: 2));

  // Test with green color
  print('\n🧪 Testing with green color - moderate pulse');
  controller.enableHaloEffect(
    color: Color(0xFF00FF00), // Green
    pulseMode: HaloPulseMode.moderate,
    pulseDuration: Duration(milliseconds: 2000),
  );

  // Wait a bit to simulate animation
  await Future.delayed(Duration(seconds: 2));

  // Test with blue color
  print('\n🧪 Testing with blue color - alert pulse');
  controller.enableHaloEffect(
    color: Color(0xFF0000FF), // Blue
    pulseMode: HaloPulseMode.alert,
    pulseDuration: Duration(milliseconds: 1000),
  );

  // Wait a bit to simulate animation
  await Future.delayed(Duration(seconds: 2));

  // Test with orange color and custom intensity
  print('\n🧪 Testing with orange color - high intensity');
  controller.enableHaloEffect(
    color: Color(0xFFFFAA00), // Orange
    intensity: 0.9,
    pulseMode: HaloPulseMode.moderate,
    pulseDuration: Duration(milliseconds: 2000),
  );

  // Wait a bit to simulate animation
  await Future.delayed(Duration(seconds: 2));

  // Test with MaterialColor to ensure proper handling
  print('\n🧪 Testing with MaterialColor (Colors.red)');
  controller.enableHaloEffect(
    color: Colors.red, // MaterialColor
    pulseMode: HaloPulseMode.gentle,
    pulseDuration: Duration(milliseconds: 2000),
  );

  // Wait a bit to simulate animation
  await Future.delayed(Duration(seconds: 2));

  // Disable halo effect
  print('\n🧪 Disabling halo effect');
  controller.disableHaloEffect();

  print('\n✅ All halo effect tests completed successfully');
}
