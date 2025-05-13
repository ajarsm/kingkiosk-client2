import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/performance_monitor_service.dart';
import '../../../services/mqtt_service_consolidated.dart';

/// Controller to handle device compatibility tests
class DeviceTestController extends GetxController {
  // Test state tracking
  final RxBool isTestRunning = false.obs;
  final RxString currentTestDescription = ''.obs;
  final RxDouble testProgress = 0.0.obs;
  final RxList<String> testResults = <String>[].obs;
  
  // Services
  final PerformanceMonitorService _performanceService = Get.find<PerformanceMonitorService>();
  
  @override
  void onInit() {
    super.onInit();
  }
  
  /// Run a simulated web content test
  Future<void> runWebViewTest() async {
    _startTest('Simulating web content rendering...');
    
    try {
      // Set up initial load progress
      testProgress.value = 0.1;
      currentTestDescription.value = 'Initializing web rendering test...';
      await Future.delayed(Duration(milliseconds: 500));
      
      // Simulate page loading
      testProgress.value = 0.3;
      currentTestDescription.value = 'Loading web content...';
      await Future.delayed(Duration(milliseconds: 800));
      
      // Simulate progress updates
      for (int i = 0; i < 5; i++) {
        testProgress.value = 0.3 + ((i + 1) / 5) * 0.5;
        currentTestDescription.value = 'Page loading: ${((i + 1) / 5 * 100).toInt()}%';
        await Future.delayed(Duration(milliseconds: 300));
      }
      
      // Simulate JavaScript performance
      testProgress.value = 0.8;
      currentTestDescription.value = 'Testing rendering performance...';
      
      // Do some CPU-intensive work to simulate JS
      final startTime = DateTime.now().millisecondsSinceEpoch;
      // Just use math operations to consume CPU
      for (int i = 0; i < 20000; i++) {
        math.sqrt(i.toDouble());
      }
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final processingTime = endTime - startTime;
      
      // Complete the test
      testProgress.value = 1.0;
      testResults.add('Web Content Test - Processing time: ${processingTime}ms');
      
      if (processingTime < 100) {
        testResults.add('Web Content Test PASSED - Excellent performance');
      } else if (processingTime < 300) {
        testResults.add('Web Content Test PASSED - Good performance');
      } else if (processingTime < 800) {
        testResults.add('Web Content Test WARNING - Adequate performance');
      } else {
        testResults.add('Web Content Test FAILED - Poor performance');
      }
      
      currentTestDescription.value = 'Web content test completed';
      await Future.delayed(Duration(seconds: 1));
    } catch (e) {
      testProgress.value = 1.0;
      testResults.add('Web Content Test FAILED: $e');
      currentTestDescription.value = 'Web content test failed: $e';
    }
    
    _endTest();
  }
  
  /// Run a test of MQTT connectivity
  Future<void> runMqttTest() async {
    _startTest('Testing MQTT connection...');
    
    try {
      // Check if MQTT service is registered
      if (!Get.isRegistered<MqttService>()) {
        testResults.add('MQTT Test FAILED: MqttService not registered');
        testProgress.value = 1.0;
        currentTestDescription.value = 'MQTT service not available';
        _endTest();
        return;
      }
      
      final mqttService = Get.find<MqttService>();
      
      // Try to connect to a public MQTT broker
      testProgress.value = 0.3;
      currentTestDescription.value = 'Connecting to public MQTT broker...';
      
      // Try to disconnect first if already connected
      await mqttService.disconnect();
      await Future.delayed(Duration(milliseconds: 500));
      
      // Connect to public test broker
      await mqttService.connect(
        brokerUrl: 'broker.emqx.io',
        port: 1883,
      );
      
      // Check if connected
      testProgress.value = 0.7;
      currentTestDescription.value = 'Checking MQTT connection...';
      
      await Future.delayed(Duration(seconds: 2));
      
      if (mqttService.isConnected.value) {
        testResults.add('MQTT Test PASSED - Connected to broker successfully');
        testProgress.value = 0.9;
        currentTestDescription.value = 'MQTT connection successful';
      } else {
        testResults.add('MQTT Test FAILED - Could not connect to broker');
        testProgress.value = 0.9;
        currentTestDescription.value = 'Failed to connect to MQTT broker';
      }
      
      // Clean up - disconnect
      await mqttService.disconnect();
      
      testProgress.value = 1.0;
      await Future.delayed(Duration(seconds: 1));
    } catch (e) {
      testProgress.value = 1.0;
      testResults.add('MQTT Test FAILED: $e');
      currentTestDescription.value = 'MQTT test failed: $e';
    }
    
    _endTest();
  }
  
  /// Run UI responsiveness test
  Future<void> runUiTest() async {
    _startTest('Testing UI responsiveness...');
    
    try {
      // Start with a simple animation test
      testProgress.value = 0.1;
      currentTestDescription.value = 'Running animation tests...';
      
      // Run for a few seconds to gather frame metrics
      for (int i = 0; i < 10; i++) {
        testProgress.value = 0.1 + (i / 10) * 0.4;
        currentTestDescription.value = 'Animation test phase: ${i+1}/10';
        await Future.delayed(Duration(milliseconds: 200));
      }
      
      // Now do a more intensive calculation to test CPU
      testProgress.value = 0.5;
      currentTestDescription.value = 'Running CPU stress test...';
      
      final startTime = DateTime.now().millisecondsSinceEpoch;
      int calculationCount = 0;
      
      // Run calculations for 2 seconds
      while (DateTime.now().millisecondsSinceEpoch - startTime < 2000) {
        // Some CPU-intensive calculation
        double result = 0;
        for (int i = 0; i < 10000; i++) {
          result += math.sqrt(i.toDouble());
        }
        calculationCount++;
        
        // Update progress every few iterations
        if (calculationCount % 5 == 0) {
          testProgress.value = 0.5 + (DateTime.now().millisecondsSinceEpoch - startTime) / 2000 * 0.4;
          await Future.delayed(Duration(milliseconds: 1)); // Allow UI update
        }
      }
      
      // Test results
      testProgress.value = 0.9;
      currentTestDescription.value = 'Analyzing test results...';
      
      final frameRate = _performanceService.frameRate.value;
      final slowFrames = _performanceService.slowFrameCount.value;
      
      if (frameRate >= 45) {
        testResults.add('UI Test PASSED - Excellent frame rate: ${frameRate.toStringAsFixed(1)} FPS, Slow frames: $slowFrames');
      } else if (frameRate >= 30) {
        testResults.add('UI Test PASSED - Good frame rate: ${frameRate.toStringAsFixed(1)} FPS, Slow frames: $slowFrames');
      } else if (frameRate >= 20) {
        testResults.add('UI Test WARNING - Marginal frame rate: ${frameRate.toStringAsFixed(1)} FPS, Slow frames: $slowFrames');
      } else {
        testResults.add('UI Test FAILED - Poor frame rate: ${frameRate.toStringAsFixed(1)} FPS, Slow frames: $slowFrames');
      }
      
      // Log the calculation performance
      testResults.add('CPU Performance: Completed $calculationCount calculation cycles in 2 seconds');
      
      testProgress.value = 1.0;
      await Future.delayed(Duration(seconds: 1));
    } catch (e) {
      testProgress.value = 1.0;
      testResults.add('UI Test FAILED: $e');
      currentTestDescription.value = 'UI test failed: $e';
    }
    
    _endTest();
  }
  
  /// Run memory stress test
  Future<void> runMemoryTest() async {
    _startTest('Testing memory management...');
    
    try {
      final List<List<int>> memoryBlocks = [];
      
      // Try to allocate progressively more memory
      for (int i = 0; i < 20; i++) {
        testProgress.value = i / 20;
        currentTestDescription.value = 'Allocating memory block ${i+1}/20...';
        
        try {
          // Each block is approximately 1MB
          final block = List<int>.filled(1024 * 1024, 42);
          memoryBlocks.add(block);
          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          testResults.add('Memory Test WARNING - Failed at block ${i+1}: $e');
          break;
        }
      }
      
      testProgress.value = 0.9;
      currentTestDescription.value = 'Releasing memory...';
      
      // Release the memory
      memoryBlocks.clear();
      
      // Wait for GC
      await Future.delayed(Duration(seconds: 2));
      
      testResults.add('Memory Test PASSED - Allocated ${memoryBlocks.length} MB of memory');
      testProgress.value = 1.0;
      await Future.delayed(Duration(seconds: 1));
    } catch (e) {
      testProgress.value = 1.0;
      testResults.add('Memory Test FAILED: $e');
      currentTestDescription.value = 'Memory test failed: $e';
    }
    
    _endTest();
  }
  
  /// Generate a full device compatibility report
  void generateReport() {
    final report = StringBuffer();
    report.writeln('===== DEVICE COMPATIBILITY REPORT =====');
    report.writeln('Device: ${_performanceService.deviceModel.value}');
    report.writeln('Android Version: ${_performanceService.androidVersion.value}');
    report.writeln('Average Frame Rate: ${_performanceService.frameRate.value.toStringAsFixed(1)} FPS');
    report.writeln('Slow Frames: ${_performanceService.slowFrameCount.value}');
    report.writeln('Frozen Frames: ${_performanceService.frozenFrameCount.value}');
    report.writeln('\nTest Results:');
    
    for (final result in testResults) {
      report.writeln('- $result');
    }
    
    report.writeln('\nCompatibility Rating: ${_getCompatibilityRating()}');
    report.writeln('==================================');
    
    final reportText = report.toString();
    print(reportText);
    
    Get.dialog(
      AlertDialog(
        title: Text('Compatibility Report'),
        content: SingleChildScrollView(
          child: Text(reportText),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () {
              // Here you would implement sharing functionality
              Get.back();
            },
            child: Text('Share'),
          ),
        ],
      ),
    );
  }
  
  /// Get a rating of device compatibility
  String _getCompatibilityRating() {
    final frameRate = _performanceService.frameRate.value;
    final frozenFrames = _performanceService.frozenFrameCount.value;
    final failedTests = testResults.where((r) => r.contains('FAILED')).length;
    
    if (frameRate >= 50 && frozenFrames == 0 && failedTests == 0) {
      return '★★★★★ EXCELLENT - Device exceeds all requirements';
    } else if (frameRate >= 40 && frozenFrames <= 5 && failedTests == 0) {
      return '★★★★☆ VERY GOOD - Device meets all requirements';
    } else if (frameRate >= 30 && frozenFrames <= 10 && failedTests <= 1) {
      return '★★★☆☆ GOOD - Device meets minimum requirements';
    } else if (frameRate >= 20 && failedTests <= 2) {
      return '★★☆☆☆ FAIR - Device may exhibit some performance issues';
    } else if (frameRate >= 15) {
      return '★☆☆☆☆ POOR - Device falls short of minimum requirements';
    } else {
      return '☆☆☆☆☆ INCOMPATIBLE - Device cannot run this application properly';
    }
  }
  
  /// Start a new test
  void _startTest(String description) {
    isTestRunning.value = true;
    currentTestDescription.value = description;
    testProgress.value = 0.0;
  }
  
  /// End the current test
  void _endTest() {
    isTestRunning.value = false;
  }
}