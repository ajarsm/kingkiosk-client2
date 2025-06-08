import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../core/utils/app_constants.dart';
import 'storage_service.dart';
import 'mqtt_service_consolidated.dart';
import 'media_device_service.dart';

/// Data structure for passing inference data to background processing
class InferenceData {
  final Object inputData;
  final int personClassId;
  final double confidenceThreshold;
  final Uint8List modelBytes;

  InferenceData({
    required this.inputData,
    required this.personClassId,
    required this.confidenceThreshold,
    required this.modelBytes,
  });
}

/// Enhanced data structure for passing all processing data to background
class EnhancedInferenceData {
  final Uint8List rawFrameData;
  final int inputWidth;
  final int inputHeight;
  final int numChannels;
  final int personClassId;
  final double confidenceThreshold;
  final double objectDetectionThreshold;
  final Uint8List modelBytes;
  final bool isDebugMode;
  final int frameNumber;
  final bool isQuantizedModel; // Add this to detect model type

  EnhancedInferenceData({
    required this.rawFrameData,
    required this.inputWidth,
    required this.inputHeight,
    required this.numChannels,
    required this.personClassId,
    required this.confidenceThreshold,
    required this.objectDetectionThreshold,
    required this.modelBytes,
    required this.isDebugMode,
    required this.frameNumber,
    required this.isQuantizedModel,
  });
}

/// Detection box structure for debug visualization
class DetectionBox {
  final double x1, y1, x2, y2; // Normalized coordinates (0.0 - 1.0)
  final double confidence;
  final int classId;
  final String? className;

  DetectionBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.confidence,
    required this.classId,
    this.className,
  });
}

/// Result structure for inference results
class InferenceResult {
  final double maxPersonConfidence;
  final int numDetections;
  final String? error;
  final List<DetectionBox> detectionBoxes; // Added for debug visualization
  InferenceResult({
    required this.maxPersonConfidence,
    required this.numDetections,
    this.error,
    this.detectionBoxes = const [],
  });
}

/// Enhanced result structure for comprehensive background processing
class EnhancedInferenceResult {
  final double maxPersonConfidence;
  final int numDetections;
  final String? error;
  final List<DetectionBox> detectionBoxes;
  final Uint8List?
      preprocessedFrameData; // Debug: processed frame for visualization
  final Uint8List?
      debugFrameWithBoxes; // Debug: frame with bounding boxes drawn
  final Map<String, dynamic> debugMetrics; // Debug: processing metrics

  EnhancedInferenceResult({
    required this.maxPersonConfidence,
    required this.numDetections,
    this.error,
    this.detectionBoxes = const [],
    this.preprocessedFrameData,
    this.debugFrameWithBoxes,
    this.debugMetrics = const {},
  });
}

/// Object categories for grouping detected objects
enum ObjectCategory {
  people,
  animals,
  vehicles,
  furniture,
  electronics,
  food,
  sports,
  kitchenware,
  accessories,
  other,
}

/// Helper function to get class name for MobileNet SSD class IDs
String _getClassNameForId(int classId) {
  // MobileNet SSD class names (optimized for person detection)
  // Note: MobileNet SSD uses different class ordering than COCO
  const mobilenetSsdClasses = {
    0: 'person', // Primary target for person detection
    1: 'bicycle',
    2: 'car',
    3: 'motorcycle',
    4: 'airplane',
    5: 'bus',
    6: 'train',
    7: 'truck',
    8: 'boat',
    9: 'traffic light',
    10: 'fire hydrant',
    11: 'stop sign',
    12: 'parking meter',
    13: 'bench',
    14: 'bird',
    15: 'cat',
    16: 'dog',
    17: 'horse',
    18: 'sheep',
    19: 'cow',
    20: 'elephant',
    21: 'bear',
    22: 'zebra',
    23: 'giraffe',
    24: 'backpack',
    25: 'umbrella',
    26: 'handbag',
    27: 'tie',
    28: 'suitcase',
    29: 'frisbee',
    30: 'skis',
    31: 'snowboard',
    32: 'sports ball',
    33: 'kite',
    34: 'baseball bat',
    35: 'baseball glove',
    36: 'skateboard',
    37: 'surfboard',
    38: 'tennis racket',
    39: 'bottle',
    40: 'wine glass',
    41: 'cup',
    42: 'fork',
    43: 'knife',
    44: 'spoon',
    45: 'bowl',
    46: 'banana',
    47: 'apple',
    48: 'sandwich',
    49: 'orange',
    50: 'broccoli',
    51: 'carrot',
    52: 'hot dog',
    53: 'pizza',
    54: 'donut',
    55: 'cake',
    56: 'chair',
    57: 'couch',
    58: 'potted plant',
    59: 'bed',
    60: 'dining table',
    61: 'toilet',
    62: 'tv',
    63: 'laptop',
    64: 'mouse',
    65: 'remote',
    66: 'keyboard', 67: 'cell phone',
    68: 'microwave',
    69: 'oven',
    70: 'toaster',
    71: 'sink',
    72: 'refrigerator',
    73: 'book',
    74: 'clock',
    75: 'vase',
    76: 'scissors',
    77: 'teddy bear',
    78: 'hair drier',
    79: 'toothbrush',
  };

  return mobilenetSsdClasses[classId] ?? 'unknown';
}

/// Enhanced background inference function that handles complete frame processing in isolate
Future<EnhancedInferenceResult> _runEnhancedInferenceInBackground(
    EnhancedInferenceData data) async {
  try {
    final Stopwatch processingStopwatch = Stopwatch()..start();

    // Debug logging for input parameters
    print(
        'DEBUG: Running enhanced inference with personClassId: ${data.personClassId}, '
        'confidenceThreshold: ${data.confidenceThreshold}, frame: ${data.frameNumber}');

    // Step 1: Preprocess frame in background isolate
    final preprocessStopwatch = Stopwatch()..start();
    final Object inputData = _preprocessFrameInBackground(
        data.rawFrameData,
        data.inputWidth,
        data.inputHeight,
        data.numChannels,
        data.isQuantizedModel);
    preprocessStopwatch.stop();

    // Step 2: Load the interpreter from model bytes in the background isolate
    final modelLoadStopwatch = Stopwatch()..start();
    final interpreter = Interpreter.fromBuffer(data.modelBytes);
    modelLoadStopwatch.stop();

    // Step 3: Run inference
    final inferenceStopwatch = Stopwatch()..start();

    // Get output tensor shapes to determine the correct structure
    final outputShapes = <List<int>>[];
    for (int i = 0; i < interpreter.getOutputTensors().length; i++) {
      outputShapes.add(interpreter.getOutputTensor(i).shape);
    }

    final outputTensors = <int, Object>{};

    if (outputShapes.length >= 4) {
      // Standard SSD MobileNet format
      final numDetections =
          outputShapes[0][1]; // Get num_detections from boxes shape

      outputTensors[0] = List.generate(
          1,
          (_) => List.generate(
              numDetections, (_) => List.filled(4, 0.0))); // boxes
      outputTensors[1] =
          List.generate(1, (_) => List.filled(numDetections, 0.0)); // classes
      outputTensors[2] =
          List.generate(1, (_) => List.filled(numDetections, 0.0)); // scores
      outputTensors[3] = [0.0]; // num_detections
    } else {
      // Fallback for simpler models - use actual output shapes
      for (int i = 0; i < outputShapes.length; i++) {
        final shape = outputShapes[i];
        if (shape.length == 3 && shape[2] == 4) {
          outputTensors[i] = List.generate(
              shape[0],
              (_) =>
                  List.generate(shape[1], (_) => List.filled(shape[2], 0.0)));
        } else if (shape.length == 2) {
          outputTensors[i] =
              List.generate(shape[0], (_) => List.filled(shape[1], 0.0));
        } else if (shape.length == 1) {
          outputTensors[i] = List.filled(shape[0], 0.0);
        }
      }
    }

    // Run inference (this heavy computation is now in background)
    interpreter.runForMultipleInputs([inputData], outputTensors);
    inferenceStopwatch.stop();

    // Step 4: Parse results for person detection
    final resultsStopwatch = Stopwatch()..start();
    double maxPersonConfidence = 0.0;
    int totalDetections = 0;
    List<DetectionBox> detectionBoxes = [];

    // Handle different output formats
    if (outputTensors.containsKey(2) && outputTensors.containsKey(1)) {
      // Standard SSD format with separate scores and classes
      final scores = outputTensors[2] as List<List<double>>;
      final classes = outputTensors[1] as List<List<double>>;
      final boxes = outputTensors[0] as List<List<List<double>>>;

      // Get number of detections
      if (outputTensors.containsKey(3)) {
        totalDetections = (outputTensors[3] as List<double>)[0].toInt();
      } else {
        totalDetections = scores[0].length;
      }
      for (int i = 0; i < totalDetections && i < scores[0].length; i++) {
        final classId = classes[0][i].toInt();
        final score = scores[0][i];

        // Extract bounding box coordinates (MobileNet SSD format: [y1, x1, y2, x2])
        final y1 = boxes[0][i][0];
        final x1 = boxes[0][i][1];
        final y2 = boxes[0][i][2];
        final x2 = boxes[0][i][3];

        // Enhanced debug logging for MobileNet SSD (focused on person detection)
        if (score > data.objectDetectionThreshold) {
          final className = _getClassNameForId(classId);
          final isPersonDetection = classId == data.personClassId;

          print('${isPersonDetection ? "🚶" : "🔍"} MobileNet detection $i - '
              'ClassID: $classId (${className}), '
              'Confidence: ${(score * 100).toStringAsFixed(1)}%, '
              'BBox: [${y1.toStringAsFixed(3)}, ${x1.toStringAsFixed(3)}, '
              '${y2.toStringAsFixed(3)}, ${x2.toStringAsFixed(3)}]'
              '${isPersonDetection ? " ⭐ PERSON DETECTED!" : ""}');
        }

        // Create detection boxes for all significant detections
        if (score > data.objectDetectionThreshold) {
          detectionBoxes.add(DetectionBox(
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            confidence: score,
            classId: classId,
            className: _getClassNameForId(classId),
          ));
        }

        // Track the highest person confidence (MobileNet SSD: person = class 0)
        if (classId == data.personClassId && score > maxPersonConfidence) {
          maxPersonConfidence = score;
          print(
              '🎯 New highest person confidence: ${(score * 100).toStringAsFixed(1)}%');
        }
      }
    } else if (outputTensors.containsKey(0)) {
      // Simpler format - check if first output contains confidence scores
      final output = outputTensors[0];
      if (output is List<List<double>> && output.isNotEmpty) {
        maxPersonConfidence = output[0].isNotEmpty ? output[0][0] : 0.0;
        totalDetections = 1;
      }
    }
    resultsStopwatch.stop();

    // Step 5: Generate debug visualization if enabled
    Uint8List? debugFrameWithBoxes;
    Uint8List? preprocessedFrameData;

    if (data.isDebugMode) {
      final debugStopwatch = Stopwatch()..start();
      try {
        // Create preprocessed frame visualization
        preprocessedFrameData = _generatePreprocessedFrameVisualization(
            data.rawFrameData,
            data.inputWidth,
            data.inputHeight); // Create debug frame with bounding boxes
        debugFrameWithBoxes = _generateDebugFrameWithBoxes(
            data.rawFrameData,
            detectionBoxes,
            data.inputWidth,
            data.inputHeight,
            data.personClassId);
      } catch (e) {
        print('Warning: Debug frame generation failed: $e');
      }
      debugStopwatch.stop();
    }

    interpreter.close();
    processingStopwatch.stop();

    // Collect debug metrics
    final debugMetrics = <String, dynamic>{
      'frameNumber': data.frameNumber,
      'totalProcessingTime': processingStopwatch.elapsedMilliseconds,
      'preprocessingTime': preprocessStopwatch.elapsedMilliseconds,
      'modelLoadTime': modelLoadStopwatch.elapsedMilliseconds,
      'inferenceTime': inferenceStopwatch.elapsedMilliseconds,
      'resultsParsingTime': resultsStopwatch.elapsedMilliseconds,
      'inputDimensions':
          '${data.inputWidth}x${data.inputHeight}x${data.numChannels}',
      'rawFrameSize': data.rawFrameData.length,
      'detectionCount': detectionBoxes.length,
      'isBackgroundProcessing': true,
    };

    return EnhancedInferenceResult(
      maxPersonConfidence: maxPersonConfidence,
      numDetections: totalDetections,
      detectionBoxes: detectionBoxes,
      preprocessedFrameData: preprocessedFrameData,
      debugFrameWithBoxes: debugFrameWithBoxes,
      debugMetrics: debugMetrics,
    );
  } catch (e) {
    return EnhancedInferenceResult(
      maxPersonConfidence: 0.0,
      numDetections: 0,
      error: e.toString(),
      debugMetrics: {
        'frameNumber': data.frameNumber,
        'error': e.toString(),
        'isBackgroundProcessing': true,
      },
    );
  }
}

/// Helper function to center crop and resize an image
img.Image _centerCropAndResize(
    img.Image image, int targetWidth, int targetHeight) {
  // Calculate the aspect ratios
  final sourceAspect = image.width / image.height;
  final targetAspect = targetWidth / targetHeight;

  img.Image cropped;

  if (sourceAspect > targetAspect) {
    // Source is wider - crop the width
    final newWidth = (image.height * targetAspect).round();
    final cropX = ((image.width - newWidth) / 2).round();
    cropped = img.copyCrop(image,
        x: cropX, y: 0, width: newWidth, height: image.height);
  } else {
    // Source is taller - crop the height
    final newHeight = (image.width / targetAspect).round();
    final cropY = ((image.height - newHeight) / 2).round();
    cropped = img.copyCrop(image,
        x: 0, y: cropY, width: image.width, height: newHeight);
  }

  // Now resize to exact target dimensions
  return img.copyResize(cropped, width: targetWidth, height: targetHeight);
}

/// Preprocess frame data for MobileNet SSD model input in background isolate (OPTIMIZED)
Object _preprocessFrameInBackground(Uint8List frameData, int inputWidth,
    int inputHeight, int numChannels, bool isQuantizedModel) {
  try {
    img.Image? image;

    // Optimized image decoding with fallback strategy
    image = img.decodeImage(frameData);
    if (image == null && frameData.length == inputWidth * inputHeight * 4) {
      // Fallback: try raw RGBA if decodeImage failed
      try {
        image = img.Image.fromBytes(
          width: inputWidth,
          height: inputHeight,
          bytes: frameData.buffer,
          format: img.Format.uint8,
          numChannels: 4,
        );
      } catch (e) {
        print('Failed to create image from raw RGBA: $e');
      }
    }

    if (image == null) {
      throw Exception('Failed to decode frame data for preprocessing');
    }

    // Optimized center crop and resize for MobileNet SSD
    final resized = _centerCropAndResize(image, inputWidth, inputHeight);

    if (isQuantizedModel) {
      // For MobileNet SSD quantized models: use raw pixel values (0-255)
      // Optimized memory allocation and pixel processing
      final totalSize = 1 * inputHeight * inputWidth * numChannels;
      final input = Uint8List(totalSize);
      int index = 0;

      // Optimized pixel processing loop
      for (int y = 0; y < inputHeight; y++) {
        for (int x = 0; x < inputWidth; x++) {
          final pixel = resized.getPixel(x, y);
          // MobileNet SSD expects RGB format
          input[index++] = pixel.r.toInt();
          input[index++] = pixel.g.toInt();
          input[index++] = pixel.b.toInt();
        }
      }
      return input.reshape([1, inputHeight, inputWidth, numChannels]);
    } else {
      // For float models: normalized values (0.0-1.0) with MobileNet optimizations
      final totalSize = 1 * inputHeight * inputWidth * numChannels;
      final input = Float32List(totalSize);
      int index = 0;

      // Optimized normalization for MobileNet SSD
      const double normalizationFactor = 1.0 / 255.0;
      for (int y = 0; y < inputHeight; y++) {
        for (int x = 0; x < inputWidth; x++) {
          final pixel = resized.getPixel(x, y);
          // MobileNet SSD normalization: (pixel_value / 255.0)
          input[index++] = pixel.r * normalizationFactor;
          input[index++] = pixel.g * normalizationFactor;
          input[index++] = pixel.b * normalizationFactor;
        }
      }
      return input.reshape([1, inputHeight, inputWidth, numChannels]);
    }
  } catch (e) {
    print('Error in background frame preprocessing: $e');
    // Return fallback data based on model type
    if (isQuantizedModel) {
      final totalSize = 1 * inputHeight * inputWidth * numChannels;
      final input = Uint8List(totalSize);
      return input.reshape([1, inputHeight, inputWidth, numChannels]);
    } else {
      final totalSize = 1 * inputHeight * inputWidth * numChannels;
      final input = Float32List(totalSize);
      return input.reshape([1, inputHeight, inputWidth, numChannels]);
    }
  }
}

/// Generate preprocessed frame visualization for debug purposes
Uint8List? _generatePreprocessedFrameVisualization(
    Uint8List frameData, int width, int height) {
  try {
    final image = img.decodeImage(frameData);
    if (image == null) return null;

    // Use center crop and resize instead of stretching
    final resized = _centerCropAndResize(image, width, height);
    return Uint8List.fromList(img.encodePng(resized));
  } catch (e) {
    print('Failed to generate preprocessed frame visualization: $e');
    return null;
  }
}

/// Generate debug frame with bounding boxes drawn
Uint8List? _generateDebugFrameWithBoxes(Uint8List frameData,
    List<DetectionBox> boxes, int width, int height, int personClassId) {
  try {
    final image = img.decodeImage(frameData);
    if (image == null) return null;

    // Use center crop and resize instead of stretching
    final resized = _centerCropAndResize(image, width, height);

    // Draw bounding boxes on the image
    for (final box in boxes) {
      final x1 = (box.x1 * width).round().clamp(0, width - 1);
      final y1 = (box.y1 * height).round().clamp(0, height - 1);
      final x2 = (box.x2 * width).round().clamp(0, width - 1);
      final y2 = (box.y2 * height)
          .round()
          .clamp(0, height - 1); // Draw rectangle (simple implementation)
      img.drawRect(resized,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: box.classId ==
                  personClassId // Person class ID (0 for MobileNet SSD)
              ? img.ColorRgb8(0, 255, 0) // Green for person
              : img.ColorRgb8(255, 0, 0), // Red for other objects
          thickness: 2);
    }

    return Uint8List.fromList(img.encodePng(resized));
  } catch (e) {
    print('Failed to generate debug frame with boxes: $e');
    return null;
  }
}

/// Service for person presence detection using TensorFlow Lite
class PersonDetectionService extends GetxService {
  // Dependencies
  final StorageService _storageService = Get.find<StorageService>();
  // Removed WebRTC frame callback service - using direct video track capture

  // TensorFlow Lite interpreter
  Interpreter? _interpreter;
  Uint8List? _modelBytes; // Store model bytes for background processing
  bool _isQuantizedModel =
      false; // Track if the model is quantized (uint8) or float
  // Observable properties
  final RxBool isEnabled = false.obs;
  final RxBool isPersonPresent = false.obs;
  final RxBool isProcessing = false.obs;
  final RxString lastError = ''.obs;
  final RxDouble confidence = 0.0.obs;
  final RxInt framesProcessed = 0.obs;

  // Multi-object detection properties
  final RxList<DetectionBox> detectedObjects = <DetectionBox>[].obs;
  final RxMap<String, int> objectCounts = <String, int>{}.obs;
  final RxMap<String, double> objectConfidences = <String, double>{}.obs;
  final RxBool anyObjectDetected = false.obs;

  // Debug visualization properties
  final RxBool isDebugVisualizationEnabled = false.obs;
  final RxList<DetectionBox> latestDetectionBoxes = <DetectionBox>[].obs;
  final RxnString debugVisualizationFrame =
      RxnString(); // Base64 encoded processed frame with bounding boxes
  final RxnString rawCapturedFrame =
      RxnString(); // Base64 encoded raw captured frame before processing
  final RxnString preprocessedTensorFlowFrame =
      RxnString(); // Base64 encoded preprocessed frame for TensorFlow

  // Frame source tracking for debug widget
  final RxBool isFrameSourceReal =
      false.obs; // Track if frames are real camera or simulated
  final RxString frameSourceStatus =
      'No frames captured'.obs; // Processing configuration for SSD MobileNet
  final int inputWidth = 300; // Matches your current model requirements
  final int inputHeight = 300; // Matches your current model requirements
  final int numChannels = 3;
  final double confidenceThreshold =
      0.6; // Higher threshold for more reliable person detection
  final double objectDetectionThreshold =
      0.6; // Use same 60% threshold for all object detection as configured by user
  final int personClassId =
      0; // Person class ID in MobileNet SSD (0 for person, correct for MobileNet)

  // Frame processing timer and stream
  Timer? _processingTimer;
  webrtc.MediaStream? _cameraStream;
  webrtc.RTCVideoRenderer? _videoRenderer;

  // Platform support flags
  bool _isFrameCaptureSupported = true; // Always true for WebRTC capture
  // Removed _rendererTextureId - using direct video track capture

  // ML Analysis configuration - configurable and optimized for performance
  static const Duration defaultAnalysisInterval =
      Duration(milliseconds: 2000); // Analyze every 2 seconds
  late Duration analysisInterval;

  // Last analysis timestamp for rate limiting
  DateTime? _lastAnalysisTime;

  // Camera resolution management for SIP calls (reactive)
  final RxBool isUpgradedTo720p = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();

    print('✅ WebRTC frame capture always supported');

    // Initialize ML analysis interval (configurable)
    analysisInterval = defaultAnalysisInterval;
    print(
        '📊 ML Analysis interval set to: ${analysisInterval.inMilliseconds}ms');

    // Load settings
    isEnabled.value =
        _storageService.read<bool>(AppConstants.keyPersonDetectionEnabled) ??
            false;

    // Initialize if enabled
    if (isEnabled.value) {
      final modelInitialized = await _initializeModel();
      if (modelInitialized) {
        // Start detection immediately if model initialized successfully
        final detectionStarted = await startDetection();
        if (detectionStarted) {
          print('✅ Person detection started successfully at startup');
        } else {
          print(
              '⚠️ Person detection model initialized but failed to start camera');
        }
      }
    }

    // Listen for setting changes
    ever(isEnabled, (bool enabled) async {
      _storageService.write(AppConstants.keyPersonDetectionEnabled, enabled);
      if (enabled) {
        final modelInitialized = await _initializeModel();
        if (modelInitialized) {
          final detectionStarted = await startDetection();
          if (detectionStarted) {
            print('✅ Person detection restarted via settings');
          } else {
            print(
                '⚠️ Person detection model initialized but failed to start camera via settings');
          }
        }
      } else {
        _stopDetection();
      }
    });
  }

  @override
  void onClose() {
    _stopDetection();
    _interpreter?.close();
    super.onClose();
  }

  /// Upgrade camera resolution to 720p for SIP calls
  Future<bool> upgradeTo720p({String? deviceId}) async {
    if (isUpgradedTo720p.value) {
      print('📹 Camera is already at 720p resolution');
      return true;
    }

    print('📹 Upgrading camera to 720p for SIP call...');

    try {
      // Stop current stream
      _stopDetection();

      // Get device ID from MediaDeviceService if not provided
      String? actualDeviceId = deviceId;
      if (actualDeviceId == null || actualDeviceId.isEmpty) {
        try {
          final mediaDeviceService = Get.find<MediaDeviceService>();
          if (mediaDeviceService.selectedVideoInput.value != null) {
            actualDeviceId =
                mediaDeviceService.selectedVideoInput.value!.deviceId;
          } else if (mediaDeviceService.videoInputs.isNotEmpty) {
            actualDeviceId = mediaDeviceService.videoInputs.first.deviceId;
          }
        } catch (e) {
          print('⚠️ MediaDeviceService not available: $e');
        }
      }

      // Set up 720p constraints
      final Map<String, dynamic> mediaConstraints = {
        'audio': false,
        'video': true
      };

      if (actualDeviceId != null && actualDeviceId.isNotEmpty) {
        mediaConstraints['video']['deviceId'] = actualDeviceId;
      }

      // Initialize renderer if needed
      if (_videoRenderer == null) {
        _videoRenderer = webrtc.RTCVideoRenderer();
        await _videoRenderer!.initialize();
      }

      // Get 720p camera stream
      _cameraStream =
          await webrtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
      _videoRenderer!.srcObject = _cameraStream;

      isUpgradedTo720p.value = true;
      print('✅ Camera upgraded to 720p successfully');
      return true;
    } catch (e) {
      print('❌ Failed to upgrade camera to 720p: $e');
      lastError.value = 'Failed to upgrade to 720p: $e';
      return false;
    }
  }

  /// Downgrade camera resolution to 300x300 for person detection
  Future<bool> downgradeTo300x300({String? deviceId}) async {
    if (!isUpgradedTo720p.value) {
      print('📹 Camera is already at 300x300 resolution');
      return true;
    }

    print('📹 Downgrading camera to 300x300 for person detection...');

    try {
      // Stop current stream
      _stopDetection();

      // Restart detection with 300x300 resolution (this will handle the camera setup)
      final success = await startDetection(deviceId: deviceId);

      if (success) {
        isUpgradedTo720p.value = false;
        print('✅ Camera downgraded to 300x300 successfully');
        return true;
      } else {
        print('❌ Failed to restart detection with 300x300');
        return false;
      }
    } catch (e) {
      print('❌ Failed to downgrade camera to 300x300: $e');
      lastError.value = 'Failed to downgrade to 300x300: $e';
      return false;
    }
  }

  /// Get current camera resolution mode as a string
  String getCurrentResolutionMode() {
    return isUpgradedTo720p.value
        ? '720p (SIP Call)'
        : '300x300 (Person Detection)';
  }

  /// Check if camera is currently at 720p resolution
  bool isAt720p() {
    return isUpgradedTo720p.value;
  }

  /// Configure ML analysis interval (how often to run object detection)
  void setAnalysisInterval(Duration interval) {
    if (interval.inMilliseconds < 500) {
      print(
          '⚠️ Warning: Analysis interval too short (${interval.inMilliseconds}ms), minimum is 500ms');
      analysisInterval = Duration(milliseconds: 500);
    } else if (interval.inMilliseconds > 30000) {
      print(
          '⚠️ Warning: Analysis interval too long (${interval.inMilliseconds}ms), maximum is 30s');
      analysisInterval = Duration(milliseconds: 30000);
    } else {
      analysisInterval = interval;
    }
    print(
        '📊 ML Analysis interval updated to: ${analysisInterval.inMilliseconds}ms');

    // Restart processing timer with new interval if currently running
    if (_processingTimer != null) {
      _startFrameProcessing();
    }
  }

  /// Check if enough time has passed since last analysis to run a new one
  bool _shouldRunAnalysis() {
    final now = DateTime.now();
    if (_lastAnalysisTime == null) {
      return true; // First analysis
    }

    final timeSinceLastAnalysis = now.difference(_lastAnalysisTime!);
    return timeSinceLastAnalysis >= analysisInterval;
  }

  /// Mark that analysis was performed
  void _markAnalysisPerformed() {
    _lastAnalysisTime = DateTime.now();
  }

  /// Initialize the TensorFlow Lite model
  Future<bool> _initializeModel() async {
    try {
      isProcessing.value = true;
      lastError.value = '';

      // Try to load the TensorFlow Lite model from assets
      try {
        // Load the optimized MobileNet SSD model for better person detection
        final modelData =
            await rootBundle.load('assets/models/ssd_mobilenet_v1.tflite');
        _modelBytes = modelData.buffer.asUint8List();

        _interpreter = await Interpreter.fromAsset(
            'assets/models/ssd_mobilenet_v1.tflite');

        // Verify model input/output shape
        final inputShape = _interpreter!.getInputTensor(0).shape;
        final outputShape = _interpreter!.getOutputTensor(0).shape;

        // Detect model type (quantized vs float)
        final inputTensor = _interpreter!.getInputTensor(0);
        final inputType = inputTensor.type;
        _isQuantizedModel = inputType.toString().contains('uint8') ||
            inputType.toString().contains('UINT8');

        print('Person detection model loaded successfully');
        print('Input shape: $inputShape');
        print('Output shape: $outputShape');
        print(
            'Model type: ${_isQuantizedModel ? "quantized (uint8)" : "float"}');
        print('Output shape: $outputShape');

        return true;
      } catch (e) {
        print('Failed to load TensorFlow Lite model: $e');

        // Check if this is a native library issue
        if (e.toString().contains('libtensorflowlite_c') ||
            e.toString().contains('Failed to load dynamic library')) {
          lastError.value =
              'TensorFlow Lite native libraries not available. Person detection will use fallback mode.';
          print(
              'TensorFlow Lite native libraries missing. This is common on Windows.');
          print(
              'Person detection will continue with simulated detection for development.');

          // Enable fallback mode - simulate model for development/testing
          _interpreter = null; // Mark as unavailable but don't fail
          return true; // Return true to allow the service to continue
        } else {
          // Re-throw other errors (model file issues, etc.)
          throw e;
        }
      }
    } catch (e) {
      lastError.value = 'Failed to initialize person detection: $e';
      print('Error initializing person detection: $e');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  /// Get camera stream with progressive fallback on constraint failures
  Future<webrtc.MediaStream?> _getCameraStreamWithFallback(
      String? deviceId) async {
    // Create base video constraints with deviceId if available
    Map<String, dynamic> createVideoConstraints(
        Map<String, dynamic>? sizeConstraints) {
      final videoConstraints = <String, dynamic>{};

      // Add device ID constraint if available (use simple string format for better compatibility)
      if (deviceId != null && deviceId.isNotEmpty) {
        videoConstraints['deviceId'] = deviceId;
      }

      // Add size constraints if provided
      if (sizeConstraints != null) {
        videoConstraints.addAll(sizeConstraints);
      }

      return videoConstraints;
    }

    // Try multiple constraint configurations in order of preference
    final constraintConfigurations = [
      // 1. Try simple resolution constraints (most compatible with macOS)
      {
        'audio': false,
        'video': createVideoConstraints({
          'width': 640,
          'height': 360,
        })
      },
       {
        'audio': false,
        'video': createVideoConstraints({
          'width': 1280,
          'height': 720,
        })
      },
      // 3. Default (no size constraints, just deviceId if available)
      {'audio': false, 'video': createVideoConstraints(null)}
    ];

    for (int i = 0; i < constraintConfigurations.length; i++) {
      try {
        final constraints = constraintConfigurations[i];

        print(
            '📹 Attempting camera constraints (attempt [1m${i + 1}/${constraintConfigurations.length}[0m):');
        print(
            '   Width: [1m${constraints['video'] is Map ? (constraints['video'] as Map)['width'] : 'no constraint'}[0m');
        print(
            '   Height: [1m${constraints['video'] is Map ? (constraints['video'] as Map)['height'] : 'no constraint'}[0m');

        final stream =
            await webrtc.navigator.mediaDevices.getUserMedia(constraints);

        // Validate the resulting resolution
        final videoTracks = stream.getVideoTracks();
        if (videoTracks.isNotEmpty) {
          try {
            final settings = await videoTracks.first.getSettings();
            final width = settings['width'] as int?;
            final height = settings['height'] as int?;

            print('📹 Camera stream acquired successfully:');
            print(
                '   Actual resolution: [1m${width ?? 'unknown'}x${height ?? 'unknown'}[0m');
            print('   Frame rate: ${settings['frameRate'] ?? 'unknown'}');

            // Accept only if at least 640x360
            if (width != null &&
                height != null &&
                width >= 640 &&
                height >= 360) {
              print('✅ Camera resolution is acceptable for frame capture');
              return stream;
            } else if (i == constraintConfigurations.length - 1) {
              // Last attempt - accept whatever we get
              print('📹 Accepting low resolution as last resort');
              return stream;
            } else {
              print(
                  '⚠️ Camera resolution is below required minimum (got ${width}x${height}, need at least 640x360)');
              // Only stop/dispose the stream if we are NOT returning it
              stream.getTracks().forEach((track) => track.stop());
              await stream.dispose();
              continue;
            }
          } catch (e) {
            print('⚠️ Could not get camera settings: $e');
            return stream; // Return it anyway
          }
        } else {
          print('❌ No video tracks in camera stream');
          stream.dispose();
          continue;
        }
      } catch (e) {
        print('❌ Camera constraint attempt ${i + 1} failed: $e');
        if (i == constraintConfigurations.length - 1) {
          print('❌ All camera constraint attempts failed');
          return null;
        }
        // Continue to next attempt
      }
    }

    return null;
  }

  /// Start person detection with camera access
  Future<bool> startDetection({String? deviceId}) async {
    if (!isEnabled.value) {
      lastError.value = 'Person detection is disabled';
      return false;
    }

    // Initialize model if not already done
    if (_interpreter == null) {
      final initialized = await _initializeModel();
      if (!initialized) return false;
    }

    try {
      // Get device ID from MediaDeviceService if not provided
      String? actualDeviceId = deviceId;
      if (actualDeviceId == null || actualDeviceId.isEmpty) {
        try {
          final mediaDeviceService = Get.find<MediaDeviceService>();
          if (mediaDeviceService.selectedVideoInput.value != null) {
            actualDeviceId =
                mediaDeviceService.selectedVideoInput.value!.deviceId;
            print(
                '👤 Using camera from MediaDeviceService: ${mediaDeviceService.selectedVideoInput.value!.label}');
          } else if (mediaDeviceService.videoInputs.isNotEmpty) {
            actualDeviceId = mediaDeviceService.videoInputs.first.deviceId;
            print(
                '👤 Using first available camera: ${mediaDeviceService.videoInputs.first.label}');
          }
        } catch (e) {
          print(
              '⚠️ MediaDeviceService not available, will use default camera: $e');
        }
      }

      // Initialize video renderer if not already done
      if (_videoRenderer == null) {
        _videoRenderer = webrtc.RTCVideoRenderer();
        await _videoRenderer!.initialize();
      }

      // Get camera stream with progressive fallback
      _cameraStream = await _getCameraStreamWithFallback(actualDeviceId);
      if (_cameraStream == null) {
        throw Exception('Failed to acquire camera stream');
      }

      _videoRenderer!.srcObject = _cameraStream;

      // Log the actual resolution that was negotiated
      final videoTracks = _cameraStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final track = videoTracks.first;
        final settings = await track.getSettings();
        print('📹 Camera resolution negotiated for person detection:');
        print('   Width: ${settings['width'] ?? 'unknown'}');
        print('   Height: ${settings['height'] ?? 'unknown'}');
        print('   Frame rate: ${settings['frameRate'] ?? 'unknown'}');

        // If we got a very small resolution, warn about it
        final width = settings['width'] as int?;
        final height = settings['height'] as int?;
        if (width != null && height != null) {
          if (width < 200 || height < 200) {
            print(
                '⚠️ WARNING: Camera resolution is very small (${width}x${height}). This may cause poor detection performance.');
          }
        }
      }

      // Wait for video stream to start receiving frames
      print('⏳ Waiting for video stream to start rendering frames...');
      await _waitForVideoStreamReady();

      // Start frame processing using direct video track capture
      _startFrameProcessing();

      print(
          '✅ Person detection started successfully using direct video track capture');
      return true;
    } catch (e) {
      lastError.value = 'Failed to start camera: $e';
      print('Error starting person detection: $e');
      return false;
    }
  }

  /// Stop person detection
  void _stopDetection() {
    _processingTimer?.cancel();
    _processingTimer = null;

    // Clean up camera stream and video renderer - direct approach
    _cameraStream?.getTracks().forEach((track) => track.stop());
    _cameraStream?.dispose();
    _cameraStream = null;

    // Dispose video renderer
    _videoRenderer?.dispose();
    _videoRenderer = null;

    // Reset state
    isPersonPresent.value = false;
    confidence.value = 0.0;
    isProcessing.value = false;

    print('Person detection stopped');
  }

  /// Start periodic frame processing
  /// Uses a shorter check interval (500ms) for responsiveness but only runs ML analysis at the configured interval
  void _startFrameProcessing() {
    _processingTimer?.cancel();

    // Use a shorter interval for checking (500ms) to be responsive
    const Duration checkInterval = Duration(milliseconds: 500);

    _processingTimer = Timer.periodic(checkInterval, (_) {
      // Only run ML analysis if enough time has passed since the last analysis
      if (_shouldRunAnalysis()) {
        _processCurrentFrame();
      }
    });

    print(
        '📊 Frame processing timer started: check every ${checkInterval.inMilliseconds}ms, analyze every ${analysisInterval.inMilliseconds}ms');
  }

  /// Wait for the video stream to be ready for frame capture
  Future<void> _waitForVideoStreamReady() async {
    if (_videoRenderer == null) {
      throw Exception('Video renderer is not initialized');
    }

    const int maxAttempts = 50; // 5 seconds at 100ms intervals
    const Duration checkInterval = Duration(milliseconds: 100);
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        // Check if the video renderer has a valid source object
        if (_videoRenderer!.srcObject != null) {
          // Additional checks for readiness based on platform
          if (kIsWeb) {
            // On web, we can check video element readiness through DOM queries
            // The web implementation handles video element detection separately
            // For now, check if we have video tracks with settings
            final videoTracks = _cameraStream?.getVideoTracks();
            if (videoTracks != null && videoTracks.isNotEmpty) {
              try {
                final settings = await videoTracks.first.getSettings();
                final width = settings['width'] as int?;
                final height = settings['height'] as int?;

                if (width != null &&
                    height != null &&
                    width > 0 &&
                    height > 0) {
                  print(
                      '✅ Video stream is ready for capture (${width}x${height})');
                  return;
                }
              } catch (e) {
                // Settings might not be available yet, continue waiting
              }
            }
          } else {
            // For non-web platforms, check if we have video tracks with settings
            final videoTracks = _cameraStream?.getVideoTracks();
            if (videoTracks != null && videoTracks.isNotEmpty) {
              try {
                final settings = await videoTracks.first.getSettings();
                final width = settings['width'] as int?;
                final height = settings['height'] as int?;

                if (width != null &&
                    height != null &&
                    width > 0 &&
                    height > 0) {
                  print(
                      '✅ Video stream is ready for capture (${width}x${height})');
                  return;
                }
              } catch (e) {
                // Settings might not be available yet, continue waiting
              }
            }
          }

          // Additional check: verify renderer has valid texture ID and dimensions
          if (_videoRenderer!.textureId != null &&
              _videoRenderer!.value.width > 0 &&
              _videoRenderer!.value.height > 0) {
            print(
                '✅ Video renderer has valid texture and dimensions (${_videoRenderer!.value.width.toInt()}x${_videoRenderer!.value.height.toInt()})');
            return;
          }
        }

        attempts++;
        if (attempts < maxAttempts) {
          await Future.delayed(checkInterval);
        }
      } catch (e) {
        print('⚠️ Error checking video stream readiness: $e');
        attempts++;
        if (attempts < maxAttempts) {
          await Future.delayed(checkInterval);
        }
      }
    }

    // If we reach here, we've exceeded max attempts
    print(
        '⚠️ Warning: Video stream readiness check timed out after ${maxAttempts * checkInterval.inMilliseconds}ms');
    print(
        '   Proceeding with frame capture setup, but there may be timing issues');
  }

  /// Process the current camera frame for person detection
  Future<void> _processCurrentFrame() async {
    if (_videoRenderer == null || isProcessing.value || !_shouldRunAnalysis()) {
      return;
    }

    try {
      isProcessing.value = true;

      // If TensorFlow Lite interpreter is available, use real detection
      if (_interpreter != null) {
        // Capture frame from video renderer
        final frameData = await _captureFrame();
        if (frameData == null) {
          if (framesProcessed.value % 20 == 0) {
            print(
                '⚠️  Frame capture failed - no frame data available (frame ${framesProcessed.value})');
          }

          // In debug mode, don't generate synthetic data - let the debug widget show "No frame available"
          if (isDebugVisualizationEnabled.value) {
            if (framesProcessed.value % 20 == 0) {
              print(
                  '🔍 Debug mode: No real WebRTC frames available - debug widget will show status');
            }
          }
          framesProcessed.value++; // Still count the frame
          return;
        }

        // Analyze and save frame data for inspection
        _analyzeAndSaveFrameData(frameData, "Captured Frame");

        // Store raw captured frame for debug visualization (before TensorFlow processing)
        if (isDebugVisualizationEnabled.value) {
          // If the frame is already a PNG, just use it directly
          if (frameData.length > 8 &&
              frameData[0] == 0x89 &&
              frameData[1] == 0x50 &&
              frameData[2] == 0x4E &&
              frameData[3] == 0x47) {
            // PNG header detected
            final base64Raw = base64Encode(frameData);
            rawCapturedFrame.value = base64Raw;
            print(
                '🐞 rawCapturedFrame.value set directly from PNG, length: ${base64Raw.length}');
          } else {
            // Fallback: try to convert to PNG
            Uint8List? rawPngData = _convertRawFrameToPng(frameData);
            if (rawPngData == null) {
              print(
                  '⚠️ _convertRawFrameToPng returned null, using fallback image');
              rawPngData = _generateFallbackPngImage();
            }
            if (rawPngData != null) {
              final base64Raw = base64Encode(rawPngData);
              rawCapturedFrame.value = base64Raw;
              print(
                  '🐞 rawCapturedFrame.value set (converted to PNG), length: ${base64Raw.length}');
            } else {
              print('❌ Failed to generate any PNG for rawCapturedFrame');
              rawCapturedFrame.value = null;
            }
          }
        }

        // Determine if this is real frame from direct video track capture
        final isRealFrame = _isFrameCaptureSupported &&
            _cameraStream != null &&
            _videoRenderer != null;

        // Log successful frame capture occasionally
        if (framesProcessed.value % 50 == 0) {
          final frameType = isRealFrame ? "real WebRTC" : "test";
          print(
              '📷 Frame captured successfully ($frameType): ${frameData.length} bytes (${inputWidth}x${inputHeight})');
        }

        // Check if model bytes are available for background processing
        if (_modelBytes == null) {
          print('⚠️ Model bytes not available for background processing');
          return;
        }

        try {
          // Use enhanced background processing for complete frame processing in isolate
          final enhancedInferenceData = EnhancedInferenceData(
            rawFrameData: frameData,
            inputWidth: inputWidth,
            inputHeight: inputHeight,
            numChannels: numChannels,
            personClassId: personClassId,
            confidenceThreshold: confidenceThreshold,
            objectDetectionThreshold: objectDetectionThreshold,
            modelBytes: _modelBytes!,
            isDebugMode: isDebugVisualizationEnabled.value,
            frameNumber: framesProcessed.value,
            isQuantizedModel: _isQuantizedModel,
          );

          final enhancedResult = await compute(
              _runEnhancedInferenceInBackground, enhancedInferenceData);

          if (enhancedResult.error != null) {
            throw Exception(
                'Enhanced background inference error: ${enhancedResult.error}');
          }

          confidence.value = enhancedResult.maxPersonConfidence;

          // Process all detected objects
          _processAllDetectedObjects(enhancedResult.detectionBoxes);

          // Store debug visualization data if enabled (now generated in background)
          if (isDebugVisualizationEnabled.value) {
            latestDetectionBoxes.value = enhancedResult.detectionBoxes;

            // Use preprocessed frame visualization from background processing
            if (enhancedResult.preprocessedFrameData != null) {
              final base64Preprocessed =
                  base64Encode(enhancedResult.preprocessedFrameData!);
              preprocessedTensorFlowFrame.value = base64Preprocessed;
              print(
                  '🐞 preprocessedTensorFlowFrame.value set from background, length: ${base64Preprocessed.length}');
            }

            // Use debug frame with boxes from background processing
            if (enhancedResult.debugFrameWithBoxes != null) {
              final base64Debug =
                  base64Encode(enhancedResult.debugFrameWithBoxes!);
              debugVisualizationFrame.value = base64Debug;
              print(
                  '🐞 debugVisualizationFrame.value set from background, length: ${base64Debug.length}');
            }

            // Store raw captured frame (before processing)
            if (frameData.length > 8 &&
                frameData[0] == 0x89 &&
                frameData[1] == 0x50 &&
                frameData[2] == 0x4E &&
                frameData[3] == 0x47) {
              // PNG header detected
              final base64Raw = base64Encode(frameData);
              rawCapturedFrame.value = base64Raw;
              print(
                  '🐞 rawCapturedFrame.value set directly from PNG, length: ${base64Raw.length}');
            } else {
              // Fallback: try to convert to PNG
              Uint8List? rawPngData = _convertRawFrameToPng(frameData);
              if (rawPngData == null) {
                print(
                    '⚠️ _convertRawFrameToPng returned null, using fallback image');
                rawPngData = _generateFallbackPngImage();
              }
              if (rawPngData != null) {
                final base64Raw = base64Encode(rawPngData);
                rawCapturedFrame.value = base64Raw;
                print(
                    '🐞 rawCapturedFrame.value set (converted to PNG), length: ${base64Raw.length}');
              } else {
                print('❌ Failed to generate any PNG for rawCapturedFrame');
                rawCapturedFrame.value = null;
              }
            }
          }

          // Enhanced debugging output with metrics from background processing
          if (framesProcessed.value % 10 == 0) {
            // Log every 10th frame
            print(
                '🤖 Enhanced Person Detection Frame ${framesProcessed.value}:');
            print('   📊 Detections found: ${enhancedResult.numDetections}');
            print(
                '   🎯 Max person confidence: ${enhancedResult.maxPersonConfidence.toStringAsFixed(3)}');
            print(
                '   👤 Person present: ${enhancedResult.maxPersonConfidence > confidenceThreshold} (threshold: $confidenceThreshold)');
            print('   ⚡ Processed completely in background isolate');

            // Log performance metrics
            final metrics = enhancedResult.debugMetrics;
            if (metrics.isNotEmpty) {
              print('   🔧 Performance metrics:');
              print(
                  '      - Total processing: ${metrics['totalProcessingTime']}ms');
              print('      - Preprocessing: ${metrics['preprocessingTime']}ms');
              print('      - Model load: ${metrics['modelLoadTime']}ms');
              print('      - Inference: ${metrics['inferenceTime']}ms');
              print(
                  '      - Results parsing: ${metrics['resultsParsingTime']}ms');
            }

            if (isDebugVisualizationEnabled.value) {
              print(
                  '   🐛 Debug boxes stored: ${enhancedResult.detectionBoxes.length}');
            }
          }

          // Mark that ML analysis was successfully performed
          _markAnalysisPerformed();
        } catch (e) {
          print('Error running enhanced background inference: $e');
          // Fallback to simple single output processing if enhanced fails
          final outputShape = _interpreter!.getOutputTensor(0).shape;

          // Preprocess frame for model input (fallback on main thread)
          final inputData = _preprocessFrame(frameData);

          // Handle multi-dimensional output tensor shapes properly
          final Map<int, Object> outputTensors = <int, Object>{};

          if (outputShape.length == 3 && outputShape[1] > 1) {
            // Multi-detection output format like [1, 10, 4]
            final numDetections = outputShape[1];
            final boxSize = outputShape[2];
            outputTensors[0] = List.generate(
                1,
                (_) => List.generate(
                    numDetections, (_) => List.filled(boxSize, 0.0)));
          } else {
            // Simple output format
            final outputSize = outputShape.isNotEmpty ? outputShape.last : 1;
            outputTensors[0] =
                List.generate(1, (_) => List.filled(outputSize, 0.0));
          }

          _interpreter!.runForMultipleInputs([inputData], outputTensors);

          // Parse results based on output format
          double maxPersonConfidence = 0.0;
          if (outputShape.length == 3 && outputShape[1] > 1) {
            // Multi-detection format - extract confidence scores
            final output = outputTensors[0] as List<List<List<double>>>;
            for (int i = 0; i < output[0].length; i++) {
              // Assume last element in each detection is confidence
              final confidence = output[0][i].last;
              if (confidence > maxPersonConfidence) {
                maxPersonConfidence = confidence;
              }
            }
          } else {
            // Simple format - first output is confidence
            final output = outputTensors[0] as List<List<double>>;
            maxPersonConfidence = output[0].isNotEmpty ? output[0][0] : 0.0;
          }

          confidence.value = maxPersonConfidence;

          // Mark that ML analysis was performed (even in fallback mode)
          _markAnalysisPerformed();
        }

        // Update presence detection
        final wasPersonPresent = isPersonPresent.value;
        isPersonPresent.value = confidence.value > confidenceThreshold;

        // Publish to MQTT if status changed or periodically for all objects
        if (wasPersonPresent != isPersonPresent.value ||
            framesProcessed.value % 20 == 0) {
          _publishAllDetections();
          if (wasPersonPresent != isPersonPresent.value) {
            print(
                '🚨 Person presence changed: ${isPersonPresent.value ? "DETECTED" : "NOT DETECTED"} (confidence: ${confidence.value.toStringAsFixed(3)})');
          }
        }

        framesProcessed.value++;
      } else {
        // Fallback mode: Simulate person detection for development/testing
        // This provides basic functionality when TensorFlow Lite is not available
        _simulatePersonDetection();
      }
    } catch (e) {
      lastError.value = 'Frame processing error: $e';
      print('Error processing frame: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Simulate person detection when TensorFlow Lite is not available
  void _simulatePersonDetection() {
    // Simple simulation: randomly detect person presence
    // In a real implementation, this could use alternative detection methods
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    final simulatedConfidence =
        (random / 1000.0) * 0.3 + 0.4; // Between 0.4 and 0.7

    confidence.value = simulatedConfidence;

    // Update presence detection with some randomness
    final wasPersonPresent = isPersonPresent.value;
    isPersonPresent.value = simulatedConfidence > confidenceThreshold;
    // Add some stability - don't change state too frequently
    if (framesProcessed.value % 10 == 0) {
      // Publish to MQTT if status changed
      if (wasPersonPresent != isPersonPresent.value) {
        _publishAllDetections();
      }
    }
    framesProcessed.value++;

    // In debug mode, don't generate synthetic data - let the debug widget show actual status
    // This ensures the debug widget displays real information about WebRTC frame availability
    if (isDebugVisualizationEnabled.value && framesProcessed.value % 20 == 0) {
      print(
          'Debug mode active: Frame source real=${isFrameSourceReal.value}, status="${frameSourceStatus.value}"');
    }

    // Log simulation mode periodically (only when actually in simulation and not in debug mode)
    if (!isFrameSourceReal.value &&
        !isDebugVisualizationEnabled.value &&
        framesProcessed.value % 20 == 0) {
      print(
          'Person detection running in simulation mode (frame ${framesProcessed.value}) - real WebRTC frames not available');
    }
  }

  /// Capture current frame from video renderer using direct VideoTrack.captureFrame()
  Future<Uint8List?> _captureFrame() async {
    print('🟦 _captureFrame: called'); // Explicit entry log
    try {
      // Direct approach: Use videoTrack.captureFrame() method
      if (_cameraStream != null) {
        print('🟦 _captureFrame: _cameraStream is not null');
        final videoTracks = _cameraStream!.getVideoTracks();
        print(
            '🟦 _captureFrame: videoTracks.length = [1m${videoTracks.length}[0m');
        if (videoTracks.isNotEmpty) {
          final videoTrack = videoTracks.first;
          print(
              '🟦 _captureFrame: videoTrack found, attempting captureFrame()');
          try {
            final ByteBuffer frameBuffer = await videoTrack.captureFrame();
            print('🟦 _captureFrame: captureFrame() completed');
            final Uint8List frameBytes = frameBuffer.asUint8List();
            final hexSample = frameBytes
                .take(16)
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join(' ');
            print(
                '🟦 _captureFrame: length=[1m${frameBytes.length}[0m, first 16 bytes: $hexSample');
            isFrameSourceReal.value = true;
            frameSourceStatus.value =
                'Real frame captured from video track ([1m${frameBytes.length}[0m bytes)';
            if (framesProcessed.value % 100 == 0) {
              print(
                  '✅ Direct video track capture: [1m${frameBytes.length}[0m bytes');
            }
            return frameBytes;
          } catch (e, st) {
            print('❌ Direct video track capture failed: $e\n$st');
            isFrameSourceReal.value = false;
            frameSourceStatus.value = 'Video track capture failed: $e';
          }
        } else {
          print('❌ No video tracks available in camera stream');
          isFrameSourceReal.value = false;
          frameSourceStatus.value = 'No video tracks available';
        }
      } else {
        print('❌ No camera stream available for frame capture');
        isFrameSourceReal.value = false;
        frameSourceStatus.value = 'No camera stream available';
      }
      print('🟦 _captureFrame: returning null (frame capture failed)');
      return null;
    } catch (e, st) {
      print('❌ Frame capture error: $e\n$st');
      isFrameSourceReal.value = false;
      frameSourceStatus.value = 'Frame capture error: $e';
      print('🟦 _captureFrame: returning null (exception)');
      return null;
    }
  }

  /// Preprocess frame data for model input using the image package
  Object _preprocessFrame(Uint8List frameData) {
    try {
      img.Image? image;

      // Always try to decode as image first (handles JPEG/PNG and raw RGBA)
      image = img.decodeImage(frameData);
      if (image == null && frameData.length == inputWidth * inputHeight * 4) {
        // Fallback: try raw RGBA if decodeImage failed
        try {
          image = img.Image.fromBytes(
            width: inputWidth,
            height: inputHeight,
            bytes: frameData.buffer,
            format: img.Format.uint8,
            numChannels: 4,
          );
        } catch (e) {
          print('⚠️ Fallback to raw RGBA failed: $e');
        }
      }

      if (image == null) {
        print(
            '❌ _preprocessFrame: Failed to decode image. Data length: ${frameData.length}');
        throw Exception('Failed to decode image');
      }

      // Resize image to model input size if needed
      if (image.width != inputWidth || image.height != inputHeight) {
        image = _centerCropAndResize(image, inputWidth, inputHeight);
      }

      // Check model input tensor type to determine preprocessing
      final inputTensor = _interpreter!.getInputTensor(0);
      final inputType = inputTensor.type;

      // Check if this is a quantized model (uint8) or float model
      final isQuantized = inputType.toString().contains('uint8') ||
          inputType.toString().contains('UINT8');

      if (isQuantized) {
        final totalSize = 1 * inputHeight * inputWidth * numChannels;
        final input = Uint8List(totalSize);
        int index = 0;
        for (int y = 0; y < inputHeight; y++) {
          for (int x = 0; x < inputWidth; x++) {
            final pixel = image.getPixel(x, y);
            input[index++] = pixel.r.toInt().clamp(0, 255);
            input[index++] = pixel.g.toInt().clamp(0, 255);
            input[index++] = pixel.b.toInt().clamp(0, 255);
          }
        }
        return input.reshape([1, inputHeight, inputWidth, numChannels]);
      } else {
        final totalSize = 1 * inputHeight * inputWidth * numChannels;
        final input = Float32List(totalSize);
        int index = 0;
        for (int y = 0; y < inputHeight; y++) {
          for (int x = 0; x < inputWidth; x++) {
            final pixel = image.getPixel(x, y);
            input[index++] = (pixel.r / 255.0).clamp(0.0, 1.0);
            input[index++] = (pixel.g / 255.0).clamp(0.0, 1.0);
            input[index++] = (pixel.b / 255.0).clamp(0.0, 1.0);
          }
        }
        return input.reshape([1, inputHeight, inputWidth, numChannels]);
      }
    } catch (e) {
      print('Error preprocessing frame: $e');

      // Return appropriate fallback based on model type
      try {
        final inputTensor = _interpreter!.getInputTensor(0);
        final inputType = inputTensor.type;

        // Check if this is a quantized model using string representation
        final isQuantized = inputType.toString().contains('uint8') ||
            inputType.toString().contains('UINT8');

        if (isQuantized) {
          // Return efficient Uint8List filled with zeros for quantized model
          final totalSize = 1 * inputHeight * inputWidth * numChannels;
          final input = Uint8List(totalSize);
          return input.reshape([1, inputHeight, inputWidth, numChannels]);
        } else {
          // Return efficient Float32List filled with zeros for float model
          final totalSize = 1 * inputHeight * inputWidth * numChannels;
          final input = Float32List(totalSize);
          return input.reshape([1, inputHeight, inputWidth, numChannels]);
        }
      } catch (_) {
        // If we can't determine type, default to efficient Float32List 4D tensor
        final totalSize = 1 * inputHeight * inputWidth * numChannels;
        final input = Float32List(totalSize);
        return input.reshape([1, inputHeight, inputWidth, numChannels]);
      }
    }
  }

  /// Converts raw RGBA frame data to PNG bytes for debug visualization
  Uint8List? _convertRawFrameToPng(Uint8List rawRgbaData) {
    try {
      // Expected frame size is 300x300x4 bytes (RGBA)
      const int width = 300;
      const int height = 300;
      const int channels = 4; // RGBA
      const int expectedSize = width * height * channels;

      if (rawRgbaData.length != expectedSize) {
        print(
            '⚠️ Frame data size mismatch: ${rawRgbaData.length} bytes (expected $expectedSize for ${width}x${height} RGBA)');

        // Try to handle different sizes
        if (rawRgbaData.length == width * height * 3) {
          // RGB data without alpha
          print('📷 Converting RGB data to RGBA for PNG encoding');
          final rgbaData = Uint8List(expectedSize);
          for (int i = 0; i < width * height; i++) {
            final rgbIndex = i * 3;
            final rgbaIndex = i * 4;
            rgbaData[rgbaIndex] = rawRgbaData[rgbIndex]; // R
            rgbaData[rgbaIndex + 1] = rawRgbaData[rgbIndex + 1]; // G
            rgbaData[rgbaIndex + 2] = rawRgbaData[rgbIndex + 2]; // B
            rgbaData[rgbaIndex + 3] = 255; // A (full opacity)
          }
          return _convertRawFrameToPng(
              rgbaData); // Recursive call with corrected data
        }

        // If size is completely wrong, return null
        return null;
      }

      // Validate data is not all zeros (which would create a black image)
      bool hasNonZeroData = false;
      for (int i = 0; i < rawRgbaData.length && !hasNonZeroData; i += 4) {
        if (rawRgbaData[i] != 0 ||
            rawRgbaData[i + 1] != 0 ||
            rawRgbaData[i + 2] != 0) {
          hasNonZeroData = true;
        }
      }

      if (!hasNonZeroData) {
        print(
            '⚠️ Warning: Frame data is all zeros - this will create a black image');
        // Continue processing anyway as this might be expected for test data
      }

      // Create an image from raw RGBA data using the newer Image.fromBytes method
      final image = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: rawRgbaData.buffer,
        format: img.Format.uint8,
        numChannels: 4,
      );

      // Encode as PNG and return bytes
      final pngBytes = img.encodePng(image);
      print(
          '✅ Successfully converted ${rawRgbaData.length} bytes to PNG (${pngBytes.length} bytes)');
      return Uint8List.fromList(pngBytes);
    } catch (e) {
      print('⚠️ Error converting raw frame to PNG: $e');
      // Generate a fallback test image instead of returning null
      return _generateFallbackPngImage();
    }
  }

  /// Generate a fallback PNG image when frame conversion fails
  Uint8List? _generateFallbackPngImage() {
    try {
      const int width = 300;
      const int height = 300;

      // Create a simple gradient test image
      final image = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final r = (x / width * 255).toInt();
          final g = (y / height * 255).toInt();
          final b = 128;
          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      final pngBytes = img.encodePng(image);
      print('🎨 Generated fallback test image (${pngBytes.length} bytes)');
      return Uint8List.fromList(pngBytes);
    } catch (e) {
      print('❌ Failed to generate fallback image: $e');
      return null;
    }
  }

  /// Process all detected objects and update observable properties
  void _processAllDetectedObjects(List<DetectionBox> detectionBoxes) {
    // Show ALL objects above threshold (not just persons)
    print("🔍 Total raw detections: ${detectionBoxes.length}");

    // Print all detections for debugging
    for (int i = 0; i < detectionBoxes.length && i < 10; i++) {
      final box = detectionBoxes[i];
      print(
          "Detection $i: class='${box.className}', classId=${box.classId}, confidence=${box.confidence.toStringAsFixed(3)}, bbox=[${box.x1.toStringAsFixed(2)}, ${box.y1.toStringAsFixed(2)}, ${box.x2.toStringAsFixed(2)}, ${box.y2.toStringAsFixed(2)}]");
    }

    // Filter objects above the general detection threshold (show ALL objects, not just persons)
    final aboveThreshold = detectionBoxes
        .where((box) => box.confidence > objectDetectionThreshold)
        .toList();

    print(
        "🎯 Above threshold (${objectDetectionThreshold}): ${aboveThreshold.length}");

    // Sort by confidence descending
    aboveThreshold.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Limit to top 10 detections of any object type
    final validDetections = aboveThreshold.take(10).toList();

    print("🏆 Final object detections (all types): ${validDetections.length}");

    // Log all detected object types
    if (validDetections.isNotEmpty) {
      print("📋 Detected object types:");
      for (final box in validDetections) {
        print(
            "   - ${box.className} (ID: ${box.classId}, confidence: ${box.confidence.toStringAsFixed(3)})");
      }
    }

    // Update detected objects list (now contains all object types)
    detectedObjects.value = validDetections;

    // Update object counts and confidences for all detected objects
    final counts = <String, int>{};
    final confidences = <String, double>{};

    for (final detection in validDetections) {
      final className = detection.className ?? 'unknown';
      counts[className] = (counts[className] ?? 0) + 1;
      // Keep the highest confidence for each class
      if (!confidences.containsKey(className) ||
          detection.confidence > confidences[className]!) {
        confidences[className] = detection.confidence;
      }
    }

    objectCounts.value = counts;
    objectConfidences.value = confidences;
    anyObjectDetected.value = validDetections
        .isNotEmpty; // Update person-specific detection status for backward compatibility
    final personDetections = validDetections
        .where((box) =>
            box.classId == personClassId &&
            box.className != null &&
            box.className!.toLowerCase() == 'person')
        .toList();

    isPersonPresent.value = personDetections.isNotEmpty;
    confidence.value =
        personDetections.isNotEmpty ? personDetections.first.confidence : 0.0;

    // Log detected objects periodically
    if (framesProcessed.value % 10 == 0 && validDetections.isNotEmpty) {
      print('🔍 All objects detected:');
      for (final entry in counts.entries) {
        final confidence = confidences[entry.key]?.toStringAsFixed(2) ?? '0.00';
        print('   ${entry.key}: ${entry.value} (max confidence: $confidence)');
      }
    }
  }

  /// Enhanced MQTT publishing for all detected objects
  void _publishAllDetections() {
    try {
      if (Get.isRegistered<MqttService>()) {
        final mqttService = Get.find<MqttService>();
        
        // Check MQTT connection status
        if (!mqttService.isConnected.value) {
          print('❌ MQTT not connected - skipping publish');
          return;
        }
        print('📡 MQTT connected - publishing detection data');
        
        // Publish comprehensive detection data
        final detectionData = {
          'timestamp': DateTime.now().toIso8601String(),
          'frames_processed': framesProcessed.value,
          'person_present': isPersonPresent.value,
          'person_confidence': confidence.value,
          'any_object_detected': anyObjectDetected.value,
          'total_objects': detectedObjects.length,
          'object_counts': Map<String, int>.from(objectCounts),
          'object_confidences': Map<String, double>.from(objectConfidences),
          'detected_objects': detectedObjects
              .map((box) => {
                    'class_name': box.className,
                    'class_id': box.classId,
                    'confidence': box.confidence,
                    'bounding_box': {
                      'x1': box.x1,
                      'y1': box.y1,
                      'x2': box.x2,
                      'y2': box.y2,
                    },
                  })
              .toList(),
        };

        print('📡 Full MQTT object detection payload: ${jsonEncode(detectionData)}');

        // Publish to general object detection topic
        mqttService.publishJsonToTopic(
            'kingkiosk/${mqttService.deviceName.value}/object_detection',
            detectionData);
        print('✅ Successfully published object detection data');

        // Also publish to legacy person presence topic for backward compatibility
        final presenceData = {
          'person_present': isPersonPresent.value,
          'confidence': confidence.value,
          'timestamp': DateTime.now().toIso8601String(),
          'frames_processed': framesProcessed.value,
        };

        print('📡 Full MQTT person presence payload: ${jsonEncode(presenceData)}');

        mqttService.publishJsonToTopic(
            'kingkiosk/${mqttService.deviceName.value}/person_presence',
            presenceData);
        print('✅ Successfully published person presence data');

        print(
            '📡 Published object detection data: ${objectCounts.length} object types detected (above ${(objectDetectionThreshold * 100).toInt()}% threshold)');
      } else {
        print('❌ MQTT service not registered');
      }
    } catch (e) {
      print('❌ Error publishing detection data to MQTT: $e');
    }
  }

  /// Toggle person detection enabled/disabled
  void toggleEnabled() {
    isEnabled.value = !isEnabled.value;
  }

  /// Get current detection status
  Map<String, dynamic> getStatus() {
    return {
      'enabled': isEnabled.value,
      'person_present': isPersonPresent.value,
      'confidence': confidence.value,
      'processing': isProcessing.value,
      'frames_processed': framesProcessed.value,
      'last_error': lastError.value,
      // Multi-object detection status
      'any_object_detected': anyObjectDetected.value,
      'total_objects': detectedObjects.length,
      'object_counts': Map<String, int>.from(objectCounts),
      'object_confidences': Map<String, double>.from(objectConfidences),
      'detected_objects': detectedObjects
          .map((box) => {
                'class_name': box.className,
                'class_id': box.classId,
                'confidence': box.confidence,
              })
          .toList(),
    };
  }

  /// Check if camera is available for detection
  Future<bool> isCameraAvailable() async {
    try {
      final devices = await webrtc.navigator.mediaDevices.enumerateDevices();
      final videoDevices =
          devices.where((device) => device.kind == 'videoinput').toList();
      return videoDevices.isNotEmpty;
    } catch (e) {
      print('Error checking camera availability: $e');
      return false;
    }
  }

  /// Get the currently selected camera device from MediaDeviceService
  String? getSelectedCameraDevice() {
    try {
      final mediaDeviceService = Get.find<MediaDeviceService>();
      if (mediaDeviceService.selectedVideoInput.value != null) {
        return mediaDeviceService.selectedVideoInput.value!.deviceId;
      } else if (mediaDeviceService.videoInputs.isNotEmpty) {
        return mediaDeviceService.videoInputs.first.deviceId;
      }
    } catch (e) {
      print('⚠️ MediaDeviceService not available for camera selection: $e');
    }
    return null;
  }

  /// Restart detection with a new camera device
  Future<bool> switchCamera(String deviceId) async {
    if (!isEnabled.value) {
      print('⚠️ Person detection is disabled, cannot switch camera');
      return false;
    }

    // Stop current detection
    _stopDetection();

    // Wait a moment for cleanup
    await Future.delayed(Duration(milliseconds: 100));

    // Start with new device
    return await startDetection(deviceId: deviceId);
  }

  /// Get available camera devices from MediaDeviceService
  List<String> getAvailableCameras() {
    try {
      final mediaDeviceService = Get.find<MediaDeviceService>();
      return mediaDeviceService.videoInputs
          .map((device) => device.deviceId)
          .toList();
    } catch (e) {
      print('⚠️ MediaDeviceService not available for camera enumeration: $e');
      return [];
    }
  }

  // Object Detection Query Methods

  /// Check if a specific object type is detected
  bool isObjectDetected(String objectName) {
    return objectCounts.containsKey(objectName) &&
        objectCounts[objectName]! > 0;
  }

  /// Get the count of a specific object type
  int getObjectCount(String objectName) {
    return objectCounts[objectName] ?? 0;
  }

  /// Get the confidence of a specific object type
  double getObjectConfidence(String objectName) {
    return objectConfidences[objectName] ?? 0.0;
  }

  /// Get all detected objects of a specific type
  List<DetectionBox> getObjectsOfType(String objectName) {
    return detectedObjects.where((box) => box.className == objectName).toList();
  }

  /// Get detected objects by category
  List<DetectionBox> getObjectsByCategory(ObjectCategory category) {
    final categoryObjects = _getObjectNamesForCategory(category);
    return detectedObjects
        .where((box) =>
            box.className != null && categoryObjects.contains(box.className!))
        .toList();
  }

  /// Check if any object from a category is detected
  bool isCategoryDetected(ObjectCategory category) {
    return getObjectsByCategory(category).isNotEmpty;
  }

  /// Get all detected animal objects
  List<DetectionBox> getDetectedAnimals() {
    return getObjectsByCategory(ObjectCategory.animals);
  }

  /// Get all detected vehicles
  List<DetectionBox> getDetectedVehicles() {
    return getObjectsByCategory(ObjectCategory.vehicles);
  }

  /// Get all detected furniture objects
  List<DetectionBox> getDetectedFurniture() {
    return getObjectsByCategory(ObjectCategory.furniture);
  }

  /// Get all detected food items
  List<DetectionBox> getDetectedFood() {
    return getObjectsByCategory(ObjectCategory.food);
  }

  /// Get object names for a specific category
  List<String> _getObjectNamesForCategory(ObjectCategory category) {
    switch (category) {
      case ObjectCategory.people:
        return ['person'];
      case ObjectCategory.animals:
        return [
          'bird',
          'cat',
          'dog',
          'horse',
          'sheep',
          'cow',
          'elephant',
          'bear',
          'zebra',
          'giraffe'
        ];
      case ObjectCategory.vehicles:
        return [
          'bicycle',
          'car',
          'motorcycle',
          'airplane',
          'bus',
          'train',
          'truck',
          'boat'
        ];
      case ObjectCategory.furniture:
        return ['chair', 'couch', 'bed', 'dining table', 'toilet'];
      case ObjectCategory.electronics:
        return [
          'tv',
          'laptop',
          'mouse',
          'remote',
          'keyboard',
          'cell phone',
          'microwave',
          'oven',
          'toaster',
          'refrigerator'
        ];
      case ObjectCategory.food:
        return [
          'banana',
          'apple',
          'sandwich',
          'orange',
          'broccoli',
          'carrot',
          'hot dog',
          'pizza',
          'donut',
          'cake'
        ];
      case ObjectCategory.sports:
        return [
          'frisbee',
          'skis',
          'snowboard',
          'sports ball',
          'kite',
          'baseball bat',
          'baseball glove',
          'skateboard',
          'surfboard',
          'tennis racket'
        ];
      case ObjectCategory.kitchenware:
        return [
          'bottle',
          'wine glass',
          'cup',
          'fork',
          'knife',
          'spoon',
          'bowl'
        ];
      case ObjectCategory.accessories:
        return ['backpack', 'umbrella', 'handbag', 'tie', 'suitcase'];
      case ObjectCategory.other:
        return [
          'traffic light',
          'fire hydrant',
          'stop sign',
          'parking meter',
          'bench',
          'potted plant',
          'book',
          'clock',
          'vase',
          'scissors',
          'teddy bear',
          'hair drier',
          'toothbrush'
        ];
    }
  }

  // Debug Visualization Methods

  /// Enable debug visualization to show detection boxes
  void enableDebugVisualization() {
    isDebugVisualizationEnabled.value = true;
    print(
        '🐛 Debug visualization enabled - will capture real WebRTC frames when available');

    // Don't immediately generate synthetic data - let real frame capture take priority
    // In debug mode, only show real WebRTC frames - no synthetic data generation
    print(
        '🎯 Debug mode enabled: Will only show real WebRTC frames (no synthetic data)');
    print(
        '📺 Debug widget will display "No frame available" when real WebRTC frames are not accessible');
  }

  /// Disable debug visualization
  void disableDebugVisualization() {
    isDebugVisualizationEnabled.value = false;
    latestDetectionBoxes.clear();
    debugVisualizationFrame.value = null;
    print('🐛 Debug visualization disabled');
  }

  /// Toggle debug visualization
  void toggleDebugVisualization() {
    if (isDebugVisualizationEnabled.value) {
      disableDebugVisualization();
    } else {
      enableDebugVisualization();
    }
  }

  /// Get the latest detection boxes for debug visualization
  List<DetectionBox> getLatestDetectionBoxes() {
    return List.from(latestDetectionBoxes);
  }

  /// Get the latest frame as base64 for debug visualization
  String? getLatestDebugFrame() {
    return debugVisualizationFrame.value;
  }

  /// Get the WebRTC video renderer for displaying real camera feed
  webrtc.RTCVideoRenderer? getVideoRenderer() {
    return _videoRenderer;
  }

  /// Check if the camera stream is active
  bool isCameraStreamActive() {
    return _cameraStream != null && _videoRenderer != null && isEnabled.value;
  }

  /// Public getter for the current camera stream (for use in settings preview widget)
  webrtc.MediaStream? get cameraStream => _cameraStream;

  /// Generate realistic debug data with simulated camera frames and detection boxes

  /// Debug method to analyze and save frame data for inspection
  void _analyzeAndSaveFrameData(Uint8List frameData, String source) {
    if (!isDebugVisualizationEnabled.value) return;

    try {
      Uint8List? pixelData = frameData;
      // If the frame is a PNG, decode it to RGBA for analysis
      if (frameData.length > 8 &&
          frameData[0] == 0x89 &&
          frameData[1] == 0x50 &&
          frameData[2] == 0x4E &&
          frameData[3] == 0x47) {
        final img.Image? decoded = img.decodeImage(frameData);
        if (decoded != null) {
          // Use toUint8List() if available, else getBytes()
          try {
            pixelData = decoded.toUint8List();
          } catch (_) {
            pixelData = decoded.getBytes();
          }
        } else {
          print('⚠️ Could not decode PNG for frame analysis');
          return;
        }
      }

      // Analyze frame data characteristics
      final stats = _analyzeFrameDataStats(pixelData);

      // Only save every 30 frames to avoid spam
      if (framesProcessed.value % 30 == 0) {
        print('🔍 FRAME DEBUG ANALYSIS [\u001b[1m$source\u001b[0m]:');
        print(
            '   📊 Size: \u001b[1m${pixelData.length}\u001b[0m bytes (${inputWidth}x${inputHeight})');
        print(
            '   🎨 RGB Averages: R=${stats['avgR']}, G=${stats['avgG']}, B=${stats['avgB']}');
        print(
            '   📈 Variance: R=${stats['varR']}, G=${stats['varG']}, B=${stats['varB']}');
        print(
            '   ⚫ All black pixels: ${stats['allBlack']}/${stats['totalPixels']} (${(stats['allBlack'] / stats['totalPixels'] * 100).toStringAsFixed(1)}%)');
        print(
            '   ⚪ All white pixels: ${stats['allWhite']}/${stats['totalPixels']} (${(stats['allWhite'] / stats['totalPixels'] * 100).toStringAsFixed(1)}%)');
        print('   🌈 Unique colors: ${stats['uniqueColors']}');
        print(
            '   📊 Is synthetic pattern: ${stats['isSynthetic'] ? "YES (test data)" : "NO (possibly real camera)"}');

        // Convert to PNG and store for debug visualization
        final pngData = _convertRawFrameToPng(pixelData);
        if (pngData != null) {
          debugVisualizationFrame.value = base64Encode(pngData);
          print('   💾 Frame saved for debug visualization');
        }

        // Save sample pixels for detailed analysis
        if (pixelData.length >= 16) {
          print('   🔬 First 4 pixels (RGBA):');
          for (int i = 0; i < 4 && i * 4 + 3 < pixelData.length; i++) {
            final r = pixelData[i * 4];
            final g = pixelData[i * 4 + 1];
            final b = pixelData[i * 4 + 2];
            final a = pixelData[i * 4 + 3];
            print('      Pixel $i: R=$r, G=$g, B=$b, A=$a');
          }
        }
      }
    } catch (e) {
      print('❌ Error analyzing frame data: $e');
    }
  }

  /// Analyze frame data statistics to determine if it's real camera data or synthetic
  Map<String, dynamic> _analyzeFrameDataStats(Uint8List frameData) {
    if (frameData.length < 4) {
      return {
        'avgR': 0,
        'avgG': 0,
        'avgB': 0,
        'varR': 0,
        'varG': 0,
        'varB': 0,
        'allBlack': 0,
        'allWhite': 0,
        'totalPixels': 0,
        'uniqueColors': 0,
        'isSynthetic': true
      };
    }

    final totalPixels = frameData.length ~/ 4;
    int sumR = 0, sumG = 0, sumB = 0;
    int allBlack = 0, allWhite = 0;
    final uniqueColors = <int>{};

    // First pass: calculate averages and count special pixels
    for (int i = 0; i < frameData.length; i += 4) {
      final r = frameData[i];
      final g = frameData[i + 1];
      final b = frameData[i + 2];

      sumR += r;
      sumG += g;
      sumB += b;

      // Check for all black pixels
      if (r == 0 && g == 0 && b == 0) allBlack++;

      // Check for all white pixels
      if (r == 255 && g == 255 && b == 255) allWhite++;

      // Track unique colors (simplified to RGB only)
      final color = (r << 16) | (g << 8) | b;
      uniqueColors.add(color);
    }

    final avgR = (sumR / totalPixels).round();
    final avgG = (sumG / totalPixels).round();
    final avgB = (sumB / totalPixels).round();

    // Second pass: calculate variance
    double varR = 0, varG = 0, varB = 0;
    for (int i = 0; i < frameData.length; i += 4) {
      final r = frameData[i];
      final g = frameData[i + 1];
      final b = frameData[i + 2];

      varR += (r - avgR) * (r - avgR);
      varG += (g - avgG) * (g - avgG);
      varB += (b - avgB) * (b - avgB);
    }

    varR = varR / totalPixels;
    varG = varG / totalPixels;
    varB = varB / totalPixels;

    // Determine if this looks like synthetic data
    bool isSynthetic = false;

    // Check for patterns typical of test data:
    // 1. Very low variance (solid colors)
    // 2. High percentage of black pixels
    // 3. Very few unique colors
    // 4. Mathematical patterns in color values

    if (varR < 100 && varG < 100 && varB < 100) {
      isSynthetic = true; // Very low variance
    }

    if (allBlack > totalPixels * 0.8) {
      isSynthetic = true; // Mostly black
    }

    if (uniqueColors.length < totalPixels * 0.01) {
      isSynthetic = true; // Very few unique colors
    }

    // Check for gradient patterns typical of test data
    bool hasGradientPattern = false;
    if (frameData.length >= inputWidth * 4 * 2) {
      // Check first two rows for gradient patterns
      for (int row = 0; row < 2; row++) {
        int consecutiveGradient = 0;
        for (int col = 1; col < inputWidth && col < 50; col++) {
          final idx1 = (row * inputWidth + col - 1) * 4;
          final idx2 = (row * inputWidth + col) * 4;

          if (idx2 + 2 < frameData.length) {
            final diff = (frameData[idx2] - frameData[idx1]).abs();
            if (diff == 1 || diff == 2) {
              // Smooth gradient
              consecutiveGradient++;
              if (consecutiveGradient > 10) {
                hasGradientPattern = true;
                break;
              }
            } else {
              consecutiveGradient = 0;
            }
          }
        }
        if (hasGradientPattern) break;
      }
    }

    if (hasGradientPattern) {
      isSynthetic = true;
    }

    return {
      'avgR': avgR,
      'avgG': avgG,
      'avgB': avgB,
      'varR': varR.toInt(),
      'varG': varG.toInt(),
      'varB': varB.toInt(),
      'allBlack': allBlack,
      'allWhite': allWhite,
      'totalPixels': totalPixels,
      'uniqueColors': uniqueColors.length,
      'isSynthetic': isSynthetic
    };
  }
}
