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
                tooltip:
                    personDetectionService.isDebugVisualizationEnabled.value
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

  Widget _buildDebugVisualization(
      PersonDetectionService service, BuildContext context) {
    return Column(
      children: [
        // Camera Resolution Controls
        _buildCameraResolutionControls(service, context),

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
                            Text(
                                'Frames Processed: ${service.framesProcessed.value}'),
                            Text(
                                'Person Present: ${service.isPersonPresent.value ? "YES" : "NO"}'),
                            Text(
                                'Confidence: ${service.confidence.value.toStringAsFixed(3)}'),
                            Text(
                                'Detection Boxes: ${service.latestDetectionBoxes.length}'),
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
                                  color: service.isFrameSourceReal.value
                                      ? Colors.green
                                      : service.framesProcessed.value > 0
                                          ? Colors.orange
                                          : Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Frame Source:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Text(
                              service.frameSourceStatus.value.isNotEmpty
                                  ? service.frameSourceStatus.value
                                  : (service.framesProcessed.value > 0
                                      ? 'Processing...'
                                      : 'No frames captured'),
                              style: TextStyle(
                                color: service.isFrameSourceReal.value
                                    ? Colors.green
                                    : service.framesProcessed.value > 0
                                        ? Colors.orange
                                        : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.link,
                                  size: 16,
                                  color: service.framesProcessed.value > 0
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Connection Status:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Text(
                              service.framesProcessed.value > 0
                                  ? 'Active (Real Stream)'
                                  : 'Connecting...',
                              style: TextStyle(
                                color: service.framesProcessed.value > 0
                                    ? Colors.green
                                    : Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )),
        ),

        // ML Analysis Status
        _buildMLAnalysisStatus(service, context),

        // Camera feed with bounding boxes
        Expanded(
          child: Obx(() => _buildCameraWithBoxes(
              service.debugVisualizationFrame.value,
              List<DetectionBox>.from(service.latestDetectionBoxes),
              service,
              context)),
        ),
      ],
    );
  }

  Widget _buildCameraResolutionControls(
      PersonDetectionService service, BuildContext context) {
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
                    Icons.camera_alt,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Camera Resolution Control',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Obx(() => Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.aspect_ratio,
                            size: 16,
                            color: service.isUpgradedTo720p.value
                                ? Colors.blue
                                : Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Current Resolution: ${service.isUpgradedTo720p.value ? "720p (SIP Call)" : "300x300 (Person Detection)"}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: service.isUpgradedTo720p.value
                                  ? Colors.blue
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: service.isUpgradedTo720p.value
                                  ? null
                                  : () async {
                                      final result =
                                          await service.upgradeTo720p();
                                      final message = result
                                          ? 'Camera upgraded to 720p'
                                          : 'Failed to upgrade to 720p';
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(message),
                                          backgroundColor: result
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                    },
                              icon: Icon(
                                Icons.upgrade,
                                size: 16,
                              ),
                              label: Text('720p (SIP)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: !service.isUpgradedTo720p.value
                                  ? null
                                  : () async {
                                      final result =
                                          await service.downgradeTo300x300();
                                      final message = result
                                          ? 'Camera downgraded to 300x300'
                                          : 'Failed to downgrade to 300x300';
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(message),
                                          backgroundColor: result
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                    },
                              icon: Icon(
                                Icons.compress,
                                size: 16,
                              ),
                              label: Text('300x300 (ML)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.blue.shade700),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Use 300x300 for efficient person detection. Switch to 720p during SIP video calls.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
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

  Widget _buildMLAnalysisStatus(
      PersonDetectionService service, BuildContext context) {
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
                    Icons.psychology,
                    color: Colors.purple,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ML Analysis Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
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
                        _buildStatusItem(
                            'Person Detection', 'Active', Colors.green),
                        _buildStatusItem(
                            'Frame Analysis',
                            service.framesProcessed.value > 0
                                ? 'Processing'
                                : 'Waiting',
                            service.framesProcessed.value > 0
                                ? Colors.green
                                : Colors.orange),
                        _buildStatusItem(
                            'ML Output',
                            service.debugVisualizationFrame.value != null &&
                                    service.debugVisualizationFrame.value!
                                        .isNotEmpty
                                ? 'Available'
                                : 'No Data',
                            service.debugVisualizationFrame.value != null &&
                                    service.debugVisualizationFrame.value!
                                        .isNotEmpty
                                ? Colors.green
                                : Colors.grey),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusItem(
                            'Bounding Boxes',
                            service.latestDetectionBoxes.isNotEmpty
                                ? '${service.latestDetectionBoxes.length} found'
                                : 'None',
                            service.latestDetectionBoxes.isNotEmpty
                                ? Colors.green
                                : Colors.grey),
                        _buildStatusItem(
                            'Confidence',
                            '${(service.confidence.value * 100).toInt()}%',
                            service.confidence.value > 0.5
                                ? Colors.green
                                : Colors.orange),
                        _buildStatusItem('Model Ready', 'Yes', Colors.green),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: service.debugVisualizationFrame.value != null &&
                          service.debugVisualizationFrame.value!.isNotEmpty
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: service.debugVisualizationFrame.value != null &&
                              service.debugVisualizationFrame.value!.isNotEmpty
                          ? Colors.green.shade200
                          : Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16,
                        color: service.debugVisualizationFrame.value != null &&
                                service
                                    .debugVisualizationFrame.value!.isNotEmpty
                            ? Colors.green.shade700
                            : Colors.orange.shade700),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        service.debugVisualizationFrame.value != null &&
                                service
                                    .debugVisualizationFrame.value!.isNotEmpty
                            ? 'ML analysis is active and generating processed frames with detection results.'
                            : 'Waiting for ML analysis output. The display will show processed frames with bounding boxes.',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              service.debugVisualizationFrame.value != null &&
                                      service.debugVisualizationFrame.value!
                                          .isNotEmpty
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
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

  Widget _buildCameraWithBoxes(
      String? frameData,
      List<DetectionBox> detectionBoxes,
      PersonDetectionService service,
      BuildContext context) {
    return Row(
      children: [
        // Left side: Raw captured frames (before TensorFlow processing)
        Expanded(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Raw Captured Frame',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  final rawFrame = service.rawCapturedFrame.value;

                  if (rawFrame != null && rawFrame.isNotEmpty) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(rawFrame),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No frame captured',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Waiting for WebRTC frame...',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }),
              ),
            ],
          ),
        ),

        SizedBox(width: 16),

        // Right side: ML Analysis Results
        Expanded(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                child: Text(
                  'ML Analysis Output',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
              Expanded(
                child: _buildMLAnalysisDisplay(
                    frameData, detectionBoxes, service, context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMLAnalysisDisplay(
      String? frameData,
      List<DetectionBox> detectionBoxes,
      PersonDetectionService service,
      BuildContext context) {
    // Show the processed ML output frame with detection results
    // This displays the analyzed frame from person detection, not the raw camera feed

    if (frameData == null || frameData.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Waiting for ML analysis output...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                service.isEnabled.value
                    ? 'Person detection is processing camera frames'
                    : 'Enable person detection to start analysis',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (!service.isEnabled.value) {
                    // Enable person detection first
                    service.toggleEnabled();
                  } else {
                    // Generate test data if detection is not working
                    service.enableDebugVisualization();
                  }
                },
                child: Text(service.isEnabled.value
                    ? 'Generate Test Data'
                    : 'Enable Detection'),
              ),
            ],
          ),
        ),
      );
    }

    // Show processed ML frame data with detection results
    try {
      final imageBytes = base64Decode(frameData);
      return Stack(
        children: [
          // Processed ML frame with analysis results
          Container(
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
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load ML analysis frame',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Analysis error: ${error.toString()}',
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
          // Bounding boxes overlay showing detection results
          Positioned.fill(
            child: CustomPaint(
              painter: BoundingBoxPainter(
                detectionBoxes,
                context,
                imageSize:
                    Size(300.0, 300.0), // ML analysis frame is always 300x300
              ),
            ),
          ),
          // ML Analysis indicator
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'ML ANALYSIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Error displaying ML analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Error: ${e.toString()}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<DetectionBox> detectionBoxes;
  final BuildContext context;
  final Size? imageSize; // Add image size for proper scaling

  BoundingBoxPainter(this.detectionBoxes, this.context, {this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final box in detectionBoxes) {
      _drawBoundingBox(canvas, size, box);
    }
  }

  void _drawBoundingBox(Canvas canvas, Size size, DetectionBox box) {
    // Calculate the actual image display area within the widget
    // The image is displayed with BoxFit.contain, so we need to account for aspect ratio
    final imageWidth = imageSize?.width ?? 300.0;
    final imageHeight = imageSize?.height ?? 300.0;
    final imageAspectRatio = imageWidth / imageHeight;
    final widgetAspectRatio = size.width / size.height;

    double displayWidth, displayHeight;
    double offsetX = 0, offsetY = 0;

    if (imageAspectRatio > widgetAspectRatio) {
      // Image is wider - fit to width
      displayWidth = size.width;
      displayHeight = size.width / imageAspectRatio;
      offsetY = (size.height - displayHeight) / 2;
    } else {
      // Image is taller - fit to height
      displayHeight = size.height;
      displayWidth = size.height * imageAspectRatio;
      offsetX = (size.width - displayWidth) / 2;
    }

    // Convert normalized coordinates to display coordinates
    final left = offsetX + (box.x1 * displayWidth);
    final top = offsetY + (box.y1 * displayHeight);
    final right = offsetX + (box.x2 * displayWidth);
    final bottom = offsetY + (box.y2 * displayHeight);

    // Clamp coordinates to visible area
    final clampedLeft = left.clamp(offsetX, offsetX + displayWidth);
    final clampedTop = top.clamp(offsetY, offsetY + displayHeight);
    final clampedRight = right.clamp(offsetX, offsetX + displayWidth);
    final clampedBottom = bottom.clamp(offsetY, offsetY + displayHeight);

    // Choose color based on class and confidence
    Color boxColor;
    if (box.classId == 1) {
      // Person
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

    final rect =
        Rect.fromLTRB(clampedLeft, clampedTop, clampedRight, clampedBottom);
    canvas.drawRect(rect, paint);

    // Prepare label text
    final labelText =
        '${box.className ?? 'Class ${box.classId}'} ${(box.confidence * 100).toInt()}%';

    // Get theme-aware colors - ensure contrast
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final backgroundColor =
        isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.9);
    final shadowColor =
        isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.8);

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
    final labelTop = clampedTop > textPainter.height + 8
        ? clampedTop - textPainter.height - 8
        : clampedBottom + 8;

    // Ensure label stays within bounds
    final labelLeft =
        clampedLeft.clamp(0, size.width - textPainter.width - 12).toDouble();
    final adjustedLabelTop =
        labelTop.clamp(0, size.height - textPainter.height - 6).toDouble();

    final labelRect = Rect.fromLTWH(
      labelLeft,
      adjustedLabelTop,
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
    textPainter.paint(canvas, Offset(labelLeft + 6, adjustedLabelTop + 3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
