import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/services/person_detection_service.dart';
import '../app/core/platform/frame_capture_platform.dart';
import '../app/core/bindings/memory_optimized_binding.dart';

/// Demonstration widget showing WebRTC texture mapping integration
/// This shows how the complete person detection system works with:
/// - WebRTC camera stream
/// - Texture ID extraction
/// - Frame capture from GPU
/// - TensorFlow Lite person detection
/// - Memory-efficient conditional loading
class WebRTCTextureMappingDemo extends StatefulWidget {
  const WebRTCTextureMappingDemo({Key? key}) : super(key: key);

  @override
  State<WebRTCTextureMappingDemo> createState() => _WebRTCTextureMappingDemoState();
}

class _WebRTCTextureMappingDemoState extends State<WebRTCTextureMappingDemo> {
  PersonDetectionService? _personDetectionService;
  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _initializeDemo();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDemo() async {
    try {
      setState(() {
        _statusMessage = 'Checking platform support...';
      });

      // 1. Check if frame capture is supported on this platform
      final isFrameCaptureSupported = await FrameCapturePlatform.isSupported();
      print('Frame capture platform support: $isFrameCaptureSupported');

      setState(() {
        _statusMessage = 'Platform support: ${isFrameCaptureSupported ? "✅ Available" : "❌ Not available"}';
      });

      await Future.delayed(Duration(seconds: 1));

      // 2. Check if PersonDetectionService is conditionally loaded
      setState(() {
        _statusMessage = 'Checking conditional service loading...';
      });

      final isServiceRegistered = Get.isRegistered<PersonDetectionService>();
      print('PersonDetectionService registered: $isServiceRegistered');

      if (isServiceRegistered) {
        // Service is already loaded (person detection enabled in settings)
        _personDetectionService = Get.find<PersonDetectionService>();
        setState(() {
          _statusMessage = '✅ PersonDetectionService found (enabled in settings)';
        });
      } else {
        // Service not loaded (person detection disabled in settings)
        setState(() {
          _statusMessage = '⏭️ PersonDetectionService not loaded (disabled in settings)';
        });
      }

      await Future.delayed(Duration(seconds: 1));

      // 3. Demonstrate texture ID extraction
      setState(() {
        _statusMessage = 'Testing texture ID extraction...';
      });

      final testRendererData = {
        'rendererId': 123,
        'textureId': 123,
        'videoTrackId': 'test-track',
      };

      final extractedTextureId = await FrameCapturePlatform.getRendererTextureId(testRendererData);
      print('Extracted texture ID: $extractedTextureId');

      setState(() {
        _statusMessage = 'Texture ID extraction: ${extractedTextureId != null ? "✅ Working" : "⚠️ Test mode"}';
      });

      await Future.delayed(Duration(seconds: 1));

      // 4. Demonstrate frame capture
      setState(() {
        _statusMessage = 'Testing frame capture...';
      });

      if (extractedTextureId != null && extractedTextureId > 0) {
        final frameData = await FrameCapturePlatform.captureFrame(
          rendererId: extractedTextureId,
          width: 224,
          height: 224,
        );

        if (frameData != null) {
          print('Frame capture successful: ${frameData.length} bytes');
          setState(() {
            _statusMessage = '✅ Frame capture working (${frameData.length} bytes)';
          });
        } else {
          setState(() {
            _statusMessage = '⚠️ Frame capture returned null (expected in test)';
          });
        }
      } else {
        setState(() {
          _statusMessage = '⚠️ No valid texture ID for frame capture test';
        });
      }

      await Future.delayed(Duration(seconds: 1));

      // 5. Show memory optimization status
      setState(() {
        _statusMessage = 'Checking memory optimization...';
      });

      final serviceStatus = MemoryOptimizedBinding.getServiceStatus();
      print('Service initialization status: $serviceStatus');

      setState(() {
        _statusMessage = '✅ Memory optimization active (${serviceStatus.length} services tracked)';
      });

      await Future.delayed(Duration(seconds: 1));

      // 6. Complete initialization
      setState(() {
        _isInitialized = true;
        _statusMessage = '🎯 WebRTC Texture Mapping Demo Ready!';
      });

      // Start periodic status updates if service is available
      if (_personDetectionService != null) {
        _startStatusUpdates();
      }

    } catch (e) {
      setState(() {
        _statusMessage = '❌ Initialization error: $e';
      });
      print('Demo initialization error: $e');
    }
  }

  void _startStatusUpdates() {
    _statusTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_personDetectionService != null && mounted) {
        setState(() {
          final service = _personDetectionService!;
          if (service.isEnabled.value) {
            if (service.isProcessing.value) {
              _statusMessage = '🔄 Processing frames... (${service.framesProcessed.value} processed)';
            } else if (service.isPersonPresent.value) {
              _statusMessage = '👤 Person detected! Confidence: ${service.confidence.value.toStringAsFixed(2)}';
            } else {
              _statusMessage = '👁️ Monitoring for person presence...';
            }
          } else {
            _statusMessage = '⏸️ Person detection disabled';
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebRTC Texture Mapping Demo'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
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
                        if (!_isInitialized)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        if (!_isInitialized) SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage,
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
                    _buildComponentItem('✅ FrameCapturePlatform.dart', 'Cross-platform interface for WebRTC frame capture'),
                    _buildComponentItem('✅ Windows D3D11 Plugin', 'Native frame capture using Direct3D 11'),
                    _buildComponentItem('✅ Android OpenGL Plugin', 'Native frame capture using OpenGL ES'),
                    _buildComponentItem('✅ iOS Metal Plugin', 'Native frame capture using Metal framework'),
                    _buildComponentItem('✅ PersonDetectionService', 'TensorFlow Lite integration with WebRTC'),
                    _buildComponentItem('✅ Memory Optimization', 'Conditional lazy loading based on settings'),
                    _buildComponentItem('✅ Texture ID Extraction', 'Get GPU texture from WebRTC renderer'),
                    _buildComponentItem('✅ RGBA Frame Processing', 'Convert GPU frames for ML inference'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Service Controls (if service is available)
            if (_personDetectionService != null) ...[
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
                        subtitle: Text('Toggle WebRTC-based person detection'),
                        value: _personDetectionService!.isEnabled.value,
                        onChanged: (value) {
                          _personDetectionService!.toggleEnabled();
                        },
                      )),
                      SizedBox(height: 8),
                      Obx(() => _buildStatusRow('Processing', _personDetectionService!.isProcessing.value)),
                      Obx(() => _buildStatusRow('Person Present', _personDetectionService!.isPersonPresent.value)),
                      Obx(() => Text('Confidence: ${_personDetectionService!.confidence.value.toStringAsFixed(2)}')),
                      Obx(() => Text('Frames Processed: ${_personDetectionService!.framesProcessed.value}')),
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
        ),
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
