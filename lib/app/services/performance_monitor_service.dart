import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A service to monitor app performance metrics
/// Useful for determining minimum system requirements
class PerformanceMonitorService extends GetxService {
  // Observable performance metrics
  final RxDouble frameRate = 0.0.obs;
  final RxInt memoryUsage = 0.obs;
  final RxInt frameCount = 0.obs;
  final RxInt slowFrameCount = 0.obs;
  final RxInt frozenFrameCount = 0.obs;
  final RxList<String> performanceWarnings = <String>[].obs;
  
  // Internal counters
  int _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
  int _frameTimesIndex = 0;
  final List<int> _frameTimes = List.filled(60, 16); // Target 60fps = 16ms/frame
  
  // Background monitoring timers
  Timer? _frameRateTimer;
  Timer? _memoryReportTimer;
  
  // Device information
  final RxString deviceModel = 'Unknown'.obs;
  final RxString androidVersion = 'Unknown'.obs;
  final RxInt totalMemoryMB = 0.obs;
  final RxInt processorCores = 0.obs;
  
  /// Initialize the service
  PerformanceMonitorService init() {
    return this;
  }
  
  /// Start monitoring performance
  void startMonitoring() {
    // Collect device information
    _collectDeviceInfo();
    
    // Reset counters
    frameCount.value = 0;
    slowFrameCount.value = 0;
    frozenFrameCount.value = 0;
    performanceWarnings.clear();
    
    // Setup frame callback
    WidgetsBinding.instance.addPostFrameCallback(_onFrameRendered);
    
    // Start memory monitoring
    _startMemoryMonitoring();
    
    // Start frame rate calculation timer
    _frameRateTimer = Timer.periodic(Duration(seconds: 1), (_) {
      _calculateFrameRate();
    });
    
    print('Performance monitoring started');
  }
  
  /// Stop monitoring
  void stopMonitoring() {
    _frameRateTimer?.cancel();
    _memoryReportTimer?.cancel();
    print('Performance monitoring stopped');
    _generateReport();
  }
  
  /// Frame callback
  void _onFrameRendered(Duration timeStamp) {
    // Calculate frame time
    final now = DateTime.now().millisecondsSinceEpoch;
    final frameTime = now - _lastFrameTime;
    _lastFrameTime = now;
    
    // Store frame time in circular buffer
    _frameTimes[_frameTimesIndex] = frameTime;
    _frameTimesIndex = (_frameTimesIndex + 1) % _frameTimes.length;
    
    // Count slow and frozen frames
    frameCount.value++;
    if (frameTime > 16) {
      slowFrameCount.value++;
    }
    if (frameTime > 700) {
      frozenFrameCount.value++;
      performanceWarnings.add('Frozen frame detected: ${frameTime}ms');
    }
    
    // Re-register for next frame
    WidgetsBinding.instance.addPostFrameCallback(_onFrameRendered);
  }
  
  /// Calculate frame rate from accumulated frame times
  void _calculateFrameRate() {
    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final calculatedFps = 1000 / avgFrameTime;
    frameRate.value = calculatedFps;
    
    // Check for performance issues
    if (calculatedFps < 30 && frameCount.value > 120) {
      performanceWarnings.add('Low frame rate detected: ${calculatedFps.toStringAsFixed(1)} FPS');
    }
  }
  
  /// Start memory usage monitoring
  void _startMemoryMonitoring() {
    _memoryReportTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      if (kReleaseMode) {
        // In release mode, we can only estimate based on non-precise methods
        memoryUsage.value = 0; // No reliable way in release mode
      } else {
        // In debug mode, we can use more detailed metrics
        // This would typically use a platform channel in a real app
        memoryUsage.value = 100; // Placeholder
      }
    });
  }
  
  /// Collect device information
  void _collectDeviceInfo() {
    if (Platform.isAndroid) {
      // In a complete implementation, you would use a package like
      // device_info_plus to get real device information
      deviceModel.value = 'Android Device'; // Placeholder
      androidVersion.value = 'Android'; // Placeholder
      processorCores.value = 4; // Placeholder
      totalMemoryMB.value = 2048; // Placeholder
    } else {
      deviceModel.value = Platform.operatingSystem;
    }
  }
  
  /// Generate a performance report
  String _generateReport() {
    final report = StringBuffer();
    report.writeln('--- PERFORMANCE REPORT ---');
    report.writeln('Device: ${deviceModel.value}');
    report.writeln('OS Version: ${androidVersion.value}');
    report.writeln('Total Runtime: ${frameCount.value / 60} seconds');
    report.writeln('Average Frame Rate: ${frameRate.value.toStringAsFixed(1)} FPS');
    report.writeln('Total Frames: ${frameCount.value}');
    report.writeln('Slow Frames: ${slowFrameCount.value} (${(slowFrameCount.value / frameCount.value * 100).toStringAsFixed(1)}%)');
    report.writeln('Frozen Frames: ${frozenFrameCount.value}');
    report.writeln('Performance Verdict: ${_getPerformanceVerdict()}');
    
    final reportString = report.toString();
    print(reportString);
    return reportString;
  }
  
  /// Get a qualitative assessment of performance
  String _getPerformanceVerdict() {
    if (frameRate.value >= 55) {
      return 'EXCELLENT - This device exceeds requirements';
    } else if (frameRate.value >= 40) {
      return 'GOOD - This device meets recommended requirements';
    } else if (frameRate.value >= 25) {
      return 'ACCEPTABLE - This device meets minimum requirements';
    } else if (frameRate.value >= 15) {
      return 'POOR - This device is below minimum requirements but may still function';
    } else {
      return 'UNUSABLE - This device cannot run the application properly';
    }
  }
}