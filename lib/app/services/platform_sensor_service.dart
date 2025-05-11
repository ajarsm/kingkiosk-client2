import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class PlatformSensorService extends GetxService {
  // Battery info
  final RxInt batteryLevel = 0.obs;
  final RxString batteryState = "unknown".obs;
  
  // Sensor data
  final RxDouble accelerometerX = 0.0.obs;
  final RxDouble accelerometerY = 0.0.obs;
  final RxDouble accelerometerZ = 0.0.obs;
  
  // Device info
  final RxMap<String, dynamic> deviceData = <String, dynamic>{}.obs;
  
  // System resources
  final RxDouble cpuUsage = 0.0.obs;
  final RxDouble memoryUsage = 0.0.obs;
  
  Timer? _resourceMonitorTimer;

  PlatformSensorService init() {
    // Simulate getting device info
    _getDeviceInfo();
    
    // Start monitoring system resources
    _initResourceMonitoring();
    
    return this;
  }

  void _getDeviceInfo() {
    // This is a simplified implementation that returns basic info
    // In a real implementation, you would use device_info_plus package
    deviceData.assignAll({
      'platform': kIsWeb ? 'web' : 'native',
      'isDesktop': GetPlatform.isDesktop,
      'isMobile': GetPlatform.isMobile,
      'isWeb': kIsWeb,
    });
  }
  
  void _initResourceMonitoring() {
    // Simulate resource monitoring with a timer
    _resourceMonitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Generate mock data
      batteryLevel.value = (DateTime.now().second % 100);
      batteryState.value = batteryLevel.value > 20 ? "charging" : "discharging";
      
      // Simulate accelerometer data
      accelerometerX.value = (DateTime.now().millisecond % 100) / 100;
      accelerometerY.value = (DateTime.now().millisecond % 70) / 100;
      accelerometerZ.value = (DateTime.now().millisecond % 50) / 100;
      
      // Simulate system resource usage
      cpuUsage.value = (DateTime.now().millisecond % 100) / 100;
      memoryUsage.value = (DateTime.now().second % 100) / 100;
    });
  }
  
  Map<String, dynamic> getAllSensorData() {
    return {
      'battery': {
        'level': batteryLevel.value,
        'state': batteryState.value,
      },
      'accelerometer': {
        'x': accelerometerX.value,
        'y': accelerometerY.value,
        'z': accelerometerZ.value,
      },
      'deviceInfo': Map<String, dynamic>.from(deviceData),
      'systemResources': {
        'cpuUsage': cpuUsage.value,
        'memoryUsage': memoryUsage.value,
      }
    };
  }
  
  @override
  void onClose() {
    _resourceMonitorTimer?.cancel();
    super.onClose();
  }
}