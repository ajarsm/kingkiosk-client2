import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';

import './background_media_service.dart';
import './media_recovery_service.dart';

/// A simple command-line tool to test the media health check functionality
/// This can be run from the main application to validate that the health checks
/// are working properly.
class MediaHealthCheckTester {
  /// Start health checks and monitor the system
  static Future<void> runTest() async {
    print('=== MEDIA HEALTH CHECK TEST STARTING ===');
    print('Time: ${DateTime.now().toIso8601String()}');
    
    try {
      // Get the BackgroundMediaService
      final mediaService = Get.find<BackgroundMediaService>();
      print('Current health status: ${mediaService.isHealthy.value ? "HEALTHY ✅" : "UNHEALTHY ❌"}');
      
      // Get the MediaRecoveryService
      final recoveryService = Get.find<MediaRecoveryService>();
      final healthData = recoveryService.getMediaHealthStatus();
      print('Media system health data: $healthData');
      
      // Listen for health status changes
      final healthSubscription = mediaService.isHealthy.listen((isHealthy) {
        print('Health status changed to: ${isHealthy ? "HEALTHY ✅" : "UNHEALTHY ❌"}');
      });
      
      // Listen for recovery events
      final recoverySubscription = recoveryService.isPerformingRecovery.listen((isRecovering) {
        if (isRecovering) {
          print('⚠️ Recovery in progress...');
        } else {
          print('Recovery complete or idle');
        }
      });
        // Force a health check by setting a short interval and waiting
      print('Forcing immediate health check...');
      mediaService.setHealthCheckInterval(1); // Set to 1 second to force quick check
      await Future.delayed(Duration(seconds: 2)); // Wait for check to happen
      
      print('Recovery count: ${recoveryService.recoveryCount.value}');
      print('Last recovery time: ${recoveryService.lastRecoveryTime.value?.toIso8601String() ?? "never"}');
      
      // Print test complete message after a delay
      await Future.delayed(Duration(seconds: 3));
      print('=== MEDIA HEALTH CHECK TEST COMPLETE ===');
      
      // Clean up subscriptions
      healthSubscription.cancel();
      recoverySubscription.cancel();
      
    } catch (e) {
      print('❌ Error during health check test: $e');
    }
  }
  
  /// Run a simple command-line interface in debug mode only
  static void showDebugCommands() {
    if (kReleaseMode) return; // Only in debug mode
    
    print('''
=== MEDIA DEBUG COMMANDS ===
1. Press 'h' to run health check test
2. Press 'r' to force media reset (normal)
3. Press 'R' to force media reset (forced)
4. Press 'q' to quit debug mode
''');
  }
}
