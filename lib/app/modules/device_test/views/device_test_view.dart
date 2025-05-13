import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/device_test_controller.dart';
import '../../../services/performance_monitor_service.dart';

/// A screen to test device performance and compatibility
class DeviceTestView extends GetView<DeviceTestController> {
  const DeviceTestView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Make sure performance monitor is registered
    final performanceService = Get.put(PerformanceMonitorService().init());
    performanceService.startMonitoring();
    
    return WillPopScope(
      onWillPop: () async {
        performanceService.stopMonitoring();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Device Compatibility Test'),
          actions: [
            IconButton(
              icon: Icon(Icons.assessment),
              onPressed: controller.generateReport,
              tooltip: 'Generate Report',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(performanceService),
              SizedBox(height: 16),
              _buildTestCategory(
                title: 'Web View Test',
                description: 'Tests the device\'s ability to display web content',
                buttonText: 'Run Web View Test',
                onPressed: controller.runWebViewTest,
              ),
              _buildTestCategory(
                title: 'MQTT Connection Test',
                description: 'Tests the device\'s ability to maintain MQTT connections',
                buttonText: 'Run MQTT Test',
                onPressed: controller.runMqttTest,
              ),
              _buildTestCategory(
                title: 'UI Responsiveness Test',
                description: 'Tests the device\'s ability to handle complex UI',
                buttonText: 'Run UI Test',
                onPressed: controller.runUiTest,
              ),
              _buildTestCategory(
                title: 'Memory Stress Test',
                description: 'Tests the device\'s ability to handle memory pressure',
                buttonText: 'Run Memory Test',
                onPressed: controller.runMemoryTest,
              ),
              SizedBox(height: 16),
              Obx(() => controller.isTestRunning.value
                ? _buildCurrentTestPanel()
                : SizedBox.shrink()),
              SizedBox(height: 16),
              _buildDeviceInfoPanel(performanceService),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusCard(PerformanceMonitorService performanceService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Obx(() => _buildMetricRow(
              'Frame Rate',
              '${performanceService.frameRate.value.toStringAsFixed(1)} FPS',
              performanceService.frameRate.value >= 30 
                ? Colors.green 
                : performanceService.frameRate.value >= 20 
                  ? Colors.orange 
                  : Colors.red,
            )),
            SizedBox(height: 8),
            Obx(() => _buildMetricRow(
              'Slow Frames',
              '${performanceService.slowFrameCount.value}',
              performanceService.slowFrameCount.value < 100 
                ? Colors.green 
                : performanceService.slowFrameCount.value < 500 
                  ? Colors.orange 
                  : Colors.red,
            )),
            SizedBox(height: 8),
            Obx(() => _buildMetricRow(
              'Frozen Frames',
              '${performanceService.frozenFrameCount.value}',
              performanceService.frozenFrameCount.value < 5 
                ? Colors.green 
                : performanceService.frozenFrameCount.value < 15 
                  ? Colors.orange 
                  : Colors.red,
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        Text(
          value, 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)
        ),
      ],
    );
  }
  
  Widget _buildTestCategory({
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(description),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrentTestPanel() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24, 
                  height: 24, 
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text(
                  'Test in Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Obx(() => Text(controller.currentTestDescription.value)),
            SizedBox(height: 16),
            Obx(() => LinearProgressIndicator(value: controller.testProgress.value)),
            SizedBox(height: 16),
            Obx(() => Text(
              '${(controller.testProgress.value * 100).toInt()}% Complete',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeviceInfoPanel(PerformanceMonitorService performanceService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Obx(() => _buildInfoRow('Model', performanceService.deviceModel.value)),
            SizedBox(height: 8),
            Obx(() => _buildInfoRow('Android Version', performanceService.androidVersion.value)),
            SizedBox(height: 8),
            Obx(() => _buildInfoRow('Processor Cores', '${performanceService.processorCores.value}')),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}