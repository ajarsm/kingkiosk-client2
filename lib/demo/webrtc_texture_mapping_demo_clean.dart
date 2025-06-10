import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/webrtc_demo_controller.dart';

/// Demonstration widget showing WebRTC direct video track capture
/// This shows how the simplified person detection system works with:
/// - Direct WebRTC video track capture
/// - videoTrack.captureFrame() method
/// - TensorFlow Lite person detection
/// - Memory-efficient conditional loading
class WebRTCDirectCaptureDemo extends GetView<WebRTCDemoController> {
  const WebRTCDirectCaptureDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(WebRTCDemoController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Direct Video Track Capture Demo'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Integration Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            if (!controller.isInitialized.value)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            if (!controller.isInitialized.value)
                              SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.statusMessage.value,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Components Overview
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Implementation Components',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildComponentItem('✅ WebRTC Frame Callback Service',
                            'Cross-platform interface for WebRTC frame capture'),
                        _buildComponentItem('✅ Windows D3D11 Plugin',
                            'Native frame capture using Direct3D 11'),
                        _buildComponentItem('✅ Android OpenGL Plugin',
                            'Native frame capture using OpenGL ES'),
                        _buildComponentItem('✅ iOS Metal Plugin',
                            'Native frame capture using Metal framework'),
                        _buildComponentItem('✅ PersonDetectionService',
                            'TensorFlow Lite integration with WebRTC'),
                        _buildComponentItem('✅ Memory Optimization',
                            'Conditional lazy loading based on settings'),
                        _buildComponentItem('✅ Texture ID Extraction',
                            'Get GPU texture from WebRTC renderer'),
                        _buildComponentItem('✅ RGBA Frame Processing',
                            'Convert GPU frames for ML inference'),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Service Controls (if service is available)
                if (controller.personDetectionService != null) ...[
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Person Detection Controls',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade800,
                            ),
                          ),
                          SizedBox(height: 12),
                          Obx(() => SwitchListTile(
                                title: Text('Enable Person Detection'),
                                subtitle: Text(
                                    'Toggle WebRTC-based person detection'),
                                value: controller
                                    .personDetectionService!.isEnabled.value,
                                onChanged: (value) {
                                  controller.personDetectionService!
                                      .toggleEnabled();
                                },
                              )),
                          SizedBox(height: 8),
                          Obx(() => _buildStatusRow(
                              'Processing',
                              controller
                                  .personDetectionService!.isProcessing.value)),
                          Obx(() => _buildStatusRow(
                              'Person Present',
                              controller.personDetectionService!.isPersonPresent
                                  .value)),
                          Obx(() => Text(
                              'Confidence: ${controller.personDetectionService!.confidence.value.toStringAsFixed(2)}')),
                          Obx(() => Text(
                              'Frames Processed: ${controller.personDetectionService!.framesProcessed.value}')),
                        ],
                      ),
                    ),
                  ),
                ],

                Spacer(),

                // Summary
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎯 Implementation Complete!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The WebRTC texture mapping implementation is complete with:\n'
                        '• Real-time frame capture from WebRTC video streams\n'
                        '• Cross-platform GPU texture access (Windows/Android/iOS)\n'
                        '• TensorFlow Lite person detection integration\n'
                        '• Memory-efficient conditional loading\n'
                        '• Production-ready error handling and fallbacks',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            )),
      ),
    );
  }

  Widget _buildComponentItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label: '),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.grey,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(value ? 'Yes' : 'No'),
        ],
      ),
    );
  }
}
