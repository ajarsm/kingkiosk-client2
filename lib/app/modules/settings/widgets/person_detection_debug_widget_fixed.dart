import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/person_detection_service.dart';

class PersonDetectionDebugWidget extends StatelessWidget {
  const PersonDetectionDebugWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use try-catch to handle service access issues
    try {
      final personDetectionService = Get.find<PersonDetectionService>();

      return Obx(() {
        return Scaffold(
          appBar: AppBar(
            title: Text('Person Detection Debug'),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
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
              ),
            ],
          ),
          body: _buildBody(personDetectionService, context),
        );
      });
    } catch (e) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Person Detection Debug'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Service not available: $e'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBody(
      PersonDetectionService personDetectionService, BuildContext context) {
    if (!personDetectionService.isEnabled.value) {
      return _buildDisabledState();
    }

    if (!personDetectionService.isDebugVisualizationEnabled.value) {
      return _buildInstructionsState();
    }

    return _buildDebugVisualization(personDetectionService, context);
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
    return SingleChildScrollView(
      child: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.blue.shade900.withOpacity(0.3)
                : Colors.blue.shade50,
            child: _buildStatusSection(service),
          ),

          // ML Analysis Status
          _buildMLAnalysisStatus(service, context),

          // Camera feed with bounding boxes
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildCameraWithBoxes(service, context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(PersonDetectionService service) {
    return Column(
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;

            if (isSmallScreen) {
              // Stack vertically on small screens
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusColumn1(service),
                  SizedBox(height: 12),
                  _buildStatusColumn2(service),
                ],
              );
            } else {
              // Use horizontal layout on larger screens
              return Row(
                children: [
                  Expanded(child: _buildStatusColumn1(service)),
                  SizedBox(width: 16),
                  Expanded(child: _buildStatusColumn2(service)),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatusColumn1(PersonDetectionService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frames Processed: ${service.framesProcessed.value}'),
        Text('Person Present: ${service.isPersonPresent.value ? "YES" : "NO"}'),
        Text('Confidence: ${service.confidence.value.toStringAsFixed(3)}'),
        Text('Detection Boxes: ${service.latestDetectionBoxes.length}'),
      ],
    );
  }

  Widget _buildStatusColumn2(PersonDetectionService service) {
    return Column(
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
            Expanded(
              child: Text(
                'Frame Source:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
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
            Expanded(
              child: Text(
                'Connection Status:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
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
                  Icon(Icons.psychology, color: Colors.purple, size: 20),
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 600;

                  if (isSmallScreen) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMLStatusColumn1(service),
                        SizedBox(height: 12),
                        _buildMLStatusColumn2(service),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(child: _buildMLStatusColumn1(service)),
                        SizedBox(width: 16),
                        Expanded(child: _buildMLStatusColumn2(service)),
                      ],
                    );
                  }
                },
              ),
              SizedBox(height: 8),
              _buildMLStatusInfo(service),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMLStatusColumn1(PersonDetectionService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusItem('Person Detection', 'Active', Colors.green),
        _buildStatusItem(
          'Frame Analysis',
          service.framesProcessed.value > 0 ? 'Processing' : 'Waiting',
          service.framesProcessed.value > 0 ? Colors.green : Colors.orange,
        ),
        _buildStatusItem(
          'ML Output',
          service.debugVisualizationFrame.value != null &&
                  service.debugVisualizationFrame.value!.isNotEmpty
              ? 'Available'
              : 'No Data',
          service.debugVisualizationFrame.value != null &&
                  service.debugVisualizationFrame.value!.isNotEmpty
              ? Colors.green
              : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildMLStatusColumn2(PersonDetectionService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusItem(
          'Bounding Boxes',
          service.latestDetectionBoxes.isNotEmpty
              ? '${service.latestDetectionBoxes.length} found'
              : 'None',
          service.latestDetectionBoxes.isNotEmpty ? Colors.green : Colors.grey,
        ),
        _buildStatusItem(
          'Confidence',
          '${(service.confidence.value * 100).toInt()}%',
          service.confidence.value > 0.5 ? Colors.green : Colors.orange,
        ),
        _buildStatusItem('Model Ready', 'Yes', Colors.green),
      ],
    );
  }

  Widget _buildMLStatusInfo(PersonDetectionService service) {
    final hasOutput = service.debugVisualizationFrame.value != null &&
        service.debugVisualizationFrame.value!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasOutput ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hasOutput ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: hasOutput ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              hasOutput
                  ? 'ML analysis is active and generating processed frames with detection results.'
                  : 'Waiting for ML analysis output. The display will show processed frames with bounding boxes.',
              style: TextStyle(
                fontSize: 12,
                color:
                    hasOutput ? Colors.green.shade700 : Colors.orange.shade700,
              ),
            ),
          ),
        ],
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
      PersonDetectionService service, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 800;

        if (isSmallScreen) {
          // Stack vertically on small screens
          return Column(
            children: [
              Expanded(child: _buildRawFrameSection(service)),
              SizedBox(height: 8),
              Expanded(child: _buildTensorFlowInputSection(service)),
              SizedBox(height: 8),
              Expanded(child: _buildMLAnalysisSection(service, context)),
            ],
          );
        } else {
          // Use horizontal layout on larger screens
          return Row(
            children: [
              Expanded(child: _buildRawFrameSection(service)),
              SizedBox(width: 12),
              Expanded(child: _buildTensorFlowInputSection(service)),
              SizedBox(width: 12),
              Expanded(child: _buildMLAnalysisSection(service, context)),
            ],
          );
        }
      },
    );
  }

  Widget _buildRawFrameSection(PersonDetectionService service) {
    return Column(
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
          child: _buildFrameDisplay(
            service.rawCapturedFrame.value,
            'No frame captured',
            'Waiting for WebRTC frame...',
            Icons.camera_alt,
            Colors.blue.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildTensorFlowInputSection(PersonDetectionService service) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          child: Text(
            'TensorFlow Input (Center Cropped 300x300)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: _buildFrameDisplay(
            service.preprocessedTensorFlowFrame.value,
            'No preprocessed frame',
            'Enable debug mode to see TensorFlow input',
            Icons.psychology,
            Colors.orange.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildMLAnalysisSection(
      PersonDetectionService service, BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          child: Text(
            'ML Analysis (1:1 with Detections)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: _buildMLAnalysisDisplay(service, context),
        ),
      ],
    );
  }

  Widget _buildFrameDisplay(
    String? frameData,
    String noDataText,
    String waitingText,
    IconData icon,
    Color borderColor,
  ) {
    if (frameData != null && frameData.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(frameData),
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
              Icon(icon, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                noDataText,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                waitingText,
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMLAnalysisDisplay(
      PersonDetectionService service, BuildContext context) {
    final frameData = service.debugVisualizationFrame.value;
    final detectionBoxes = List<DetectionBox>.from(service.latestDetectionBoxes)
        .where((box) => box.confidence >= service.objectDetectionThreshold)
        .toList();

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
                    service.toggleEnabled();
                  } else {
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
            child: _DynamicBoundingBoxOverlay(
              detectionBoxes: detectionBoxes,
              imageBytes: imageBytes,
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

class _DynamicBoundingBoxOverlay extends StatefulWidget {
  final List<DetectionBox> detectionBoxes;
  final Uint8List imageBytes;

  const _DynamicBoundingBoxOverlay({
    Key? key,
    required this.detectionBoxes,
    required this.imageBytes,
  }) : super(key: key);

  @override
  State<_DynamicBoundingBoxOverlay> createState() =>
      _DynamicBoundingBoxOverlayState();
}

class _DynamicBoundingBoxOverlayState
    extends State<_DynamicBoundingBoxOverlay> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _decodeImageSize();
  }

  void _decodeImageSize() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _imageSize = Size(
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          );
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void didUpdateWidget(covariant _DynamicBoundingBoxOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      _decodeImageSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BoundingBoxPainter(
        widget.detectionBoxes,
        context,
        imageSize: _imageSize,
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<DetectionBox> detectionBoxes;
  final BuildContext context;
  final Size? imageSize;

  BoundingBoxPainter(this.detectionBoxes, this.context, {this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final box in detectionBoxes) {
      _drawBoundingBox(canvas, size, box);
    }
  }

  void _drawBoundingBox(Canvas canvas, Size size, DetectionBox box) {
    // Calculate the actual image display area within the widget
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

    // Get theme-aware colors
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

    // Calculate label position
    final labelTop = clampedTop > textPainter.height + 8
        ? clampedTop - textPainter.height - 8
        : clampedBottom + 8;

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
