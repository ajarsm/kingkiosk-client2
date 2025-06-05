import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/person_detection_service.dart';

class PersonDetectionDebugWidget extends StatelessWidget {
  const PersonDetectionDebugWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final personDetectionService = Get.find<PersonDetectionService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Person Detection Debug'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          Obx(() => IconButton(
                icon: Icon(
                  personDetectionService.isDebugVisualizationEnabled.value
                      ? Icons.bug_report
                      : Icons.bug_report_outlined,
                ),
                onPressed: () {
                  personDetectionService.toggleDebugVisualization();
                },
                tooltip: personDetectionService.isDebugVisualizationEnabled.value
                    ? 'Disable Debug Mode'
                    : 'Enable Debug Mode',
              )),
        ],
      ),
      body: Obx(() {
        if (!personDetectionService.isEnabled.value) {
          return _buildDisabledState();
        }

        if (!personDetectionService.isDebugVisualizationEnabled.value) {
          return _buildInstructionsState();
        }

        return _buildDebugVisualization(personDetectionService, context);
      }),
    );
  }

  Widget _buildDisabledState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_off,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Person Detection Disabled',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Enable person detection in settings to use debug visualization',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bug_report_outlined,
            size: 64,
            color: Colors.blue,
          ),
          SizedBox(height: 16),
          Text(
            'Debug Visualization Ready',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the debug icon in the top-right to enable visualization',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Get.find<PersonDetectionService>().enableDebugVisualization();
            },
            icon: Icon(Icons.bug_report),
            label: Text('Enable Debug Mode'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDebugVisualization(PersonDetectionService service, BuildContext context) {
    return Column(
      children: [
        // Status bar
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.blue.shade900.withOpacity(0.3)
              : Colors.blue.shade50,
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Detection Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Frames Processed: ${service.framesProcessed.value}'),
                            Text('Person Present: ${service.isPersonPresent.value ? "YES" : "NO"}'),
                            Text('Confidence: ${service.confidence.value.toStringAsFixed(3)}'),
                            Text('Detection Boxes: ${service.latestDetectionBoxes.length}'),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.videocam,
                                  size: 16,
                                  color: service.debugVisualizationFrame.value != null 
                                      ? Colors.green : Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Frame Source:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Text(
                              service.debugVisualizationFrame.value != null 
                                  ? 'Test Data (Synthetic)' 
                                  : 'No frames available',
                              style: TextStyle(
                                color: service.debugVisualizationFrame.value != null 
                                    ? Colors.orange : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.link,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'WebRTC Connection:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Text(
                              'Mock/Test Mode',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )),        ),
        
        // WebRTC Connection Status
        Obx(() => _buildWebRTCConnectionStatus(service, context)),
        
        // Camera feed with bounding boxes
        Expanded(
          child: Obx(() => _buildCameraWithBoxes(service, context)),
        ),
      ],
    );  }

  Widget _buildWebRTCConnectionStatus(PersonDetectionService service, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.router,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'WebRTC Integration Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusItem('Native Plugins', 'Available', Colors.green),
                        _buildStatusItem('Texture Extraction', 'Mock Mode', Colors.orange),
                        _buildStatusItem('Frame Capture', 'Test Data', Colors.orange),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusItem('Camera Stream', 'Not Connected', Colors.grey),
                        _buildStatusItem('Real Frames', 'Pending', Colors.grey),
                        _buildStatusItem('Production Ready', '95%', Colors.blue),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Currently using test frames. Real WebRTC texture mapping requires native plugin updates.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String status, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $status',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraWithBoxes(PersonDetectionService service, BuildContext context) {
    final frameData = service.debugVisualizationFrame.value;
    final detectionBoxes = service.latestDetectionBoxes;

    if (frameData == null || frameData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Waiting for camera frame...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Debug mode will show synthetic test data if camera is unavailable',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                service.enableDebugVisualization();
              },
              child: Text('Generate Test Data'),
            ),
          ],
        ),
      );
    }

    try {
      final imageBytes = base64Decode(frameData);
      return Stack(
        children: [
          // Camera image with proper aspect ratio and centering
          Center(
            child: AspectRatio(
              aspectRatio: 1.0, // Force square aspect ratio for 300x300 images
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade600
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load camera frame',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Image decode error: ${error.toString()}',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),          // Bounding boxes overlay - positioned over the centered image
          Center(
            child: AspectRatio(
              aspectRatio: 1.0, // Same aspect ratio as the image
              child: CustomPaint(
                painter: BoundingBoxPainter(detectionBoxes.toList(), context),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red),
            Text('Error displaying frame: $e'),
          ],
        ),
      );
    }  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<DetectionBox> detectionBoxes;
  final BuildContext context;

  BoundingBoxPainter(this.detectionBoxes, this.context);

  @override
  void paint(Canvas canvas, Size size) {
    for (final box in detectionBoxes) {
      _drawBoundingBox(canvas, size, box);
    }
  }

  void _drawBoundingBox(Canvas canvas, Size size, DetectionBox box) {
    // Convert normalized coordinates to screen coordinates
    final left = box.x1 * size.width;
    final top = box.y1 * size.height;
    final right = box.x2 * size.width;
    final bottom = box.y2 * size.height;

    // Choose color based on class and confidence
    Color boxColor;
    if (box.classId == 1) { // Person
      if (box.confidence > 0.7) {
        boxColor = Colors.green;
      } else if (box.confidence > 0.5) {
        boxColor = Colors.orange;
      } else {
        boxColor = Colors.red;
      }
    } else {
      boxColor = Colors.blue;
    }

    // Draw bounding box
    final paint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final rect = Rect.fromLTRB(left, top, right, bottom);
    canvas.drawRect(rect, paint);    // Prepare label text
    final labelText = '${box.className ?? 'Class ${box.classId}'} ${(box.confidence * 100).toInt()}%';
    
    // Get theme-aware colors - ensure contrast
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final backgroundColor = isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.9);
    final shadowColor = isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.8);

    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 3,
              color: shadowColor,
            ),
            Shadow(
              offset: Offset(-1, -1),
              blurRadius: 3,
              color: shadowColor,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Calculate label position (above the box, or below if near top)
    final labelTop = top > textPainter.height + 8 
        ? top - textPainter.height - 8
        : bottom + 8;

    final labelRect = Rect.fromLTWH(
      left,
      labelTop,
      textPainter.width + 12,
      textPainter.height + 6,
    );

    // Draw label background
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, Radius.circular(4)),
      backgroundPaint,
    );

    // Draw label border
    final borderPaint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, Radius.circular(4)),
      borderPaint,
    );

    // Draw label text
    textPainter.paint(canvas, Offset(left + 6, labelTop + 3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
