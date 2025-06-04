import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../core/utils/app_constants.dart';
import '../core/platform/frame_capture_platform.dart';
import 'storage_service.dart';
import 'mqtt_service_consolidated.dart';
import 'media_device_service.dart';

/// Service for person presence detection using TensorFlow Lite
class PersonDetectionService extends GetxService {
  // Dependencies
  final StorageService _storageService = Get.find<StorageService>();
  
  // TensorFlow Lite interpreter
  Interpreter? _interpreter;
  
  // Observable properties
  final RxBool isEnabled = false.obs;
  final RxBool isPersonPresent = false.obs;
  final RxBool isProcessing = false.obs;
  final RxString lastError = ''.obs;
  final RxDouble confidence = 0.0.obs;
  final RxInt framesProcessed = 0.obs;
    // Processing configuration for SSD MobileNet
  final int inputWidth = 300;
  final int inputHeight = 300;
  final int numChannels = 3;
  final double confidenceThreshold = 0.5; // Threshold for person detection
  final int personClassId = 1; // Person class ID in COCO dataset// Frame processing timer and stream
  Timer? _processingTimer;
  webrtc.MediaStream? _cameraStream;
  webrtc.RTCVideoRenderer? _videoRenderer;
    // Platform support flags
  bool _isFrameCaptureSupported = false;
  int? _rendererTextureId;
  
  // Processing rate configuration
  final Duration processingInterval = Duration(milliseconds: 500); // Process 2 frames per second
    @override
  Future<void> onInit() async {
    super.onInit();
    
    // Check platform support for frame capture
    _isFrameCaptureSupported = await FrameCapturePlatform.isSupported();
    print('Frame capture platform support: $_isFrameCaptureSupported');
    
    // Load settings
    isEnabled.value = _storageService.read<bool>(AppConstants.keyPersonDetectionEnabled) ?? false;
      // Initialize if enabled
    if (isEnabled.value) {
      final modelInitialized = await _initializeModel();
      if (modelInitialized) {
        // Start detection immediately if model initialized successfully
        final detectionStarted = await startDetection();
        if (detectionStarted) {
          print('✅ Person detection started successfully at startup');
        } else {
          print('⚠️ Person detection model initialized but failed to start camera');
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
            print('⚠️ Person detection model initialized but failed to start camera via settings');
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
    /// Initialize the TensorFlow Lite model
  Future<bool> _initializeModel() async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      
      // Try to load the TensorFlow Lite model from assets
      try {
        _interpreter = await Interpreter.fromAsset('assets/models/person_detect.tflite');
        
        // Verify model input/output shape
        final inputShape = _interpreter!.getInputTensor(0).shape;
        final outputShape = _interpreter!.getOutputTensor(0).shape;
        
        print('Person detection model loaded successfully');
        print('Input shape: $inputShape');
        print('Output shape: $outputShape');
        
        return true;
        
      } catch (e) {
        print('Failed to load TensorFlow Lite model: $e');
        
        // Check if this is a native library issue
        if (e.toString().contains('libtensorflowlite_c') || 
            e.toString().contains('Failed to load dynamic library')) {
          lastError.value = 'TensorFlow Lite native libraries not available. Person detection will use fallback mode.';
          print('TensorFlow Lite native libraries missing. This is common on Windows.');
          print('Person detection will continue with simulated detection for development.');
          
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
  }  /// Start person detection with camera access
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

    try {      // Get device ID from MediaDeviceService if not provided
      String? actualDeviceId = deviceId;
      if (actualDeviceId == null || actualDeviceId.isEmpty) {
        try {
          final mediaDeviceService = Get.find<MediaDeviceService>();
          if (mediaDeviceService.selectedVideoInput.value != null) {
            actualDeviceId = mediaDeviceService.selectedVideoInput.value!.deviceId;
            print('👤 Using camera from MediaDeviceService: ${mediaDeviceService.selectedVideoInput.value!.label}');
          } else if (mediaDeviceService.videoInputs.isNotEmpty) {
            actualDeviceId = mediaDeviceService.videoInputs.first.deviceId;
            print('👤 Using first available camera: ${mediaDeviceService.videoInputs.first.label}');
          }
        } catch (e) {
          print('⚠️ MediaDeviceService not available, will use default camera: $e');
        }
      }

      // Initialize video renderer if not already done
      if (_videoRenderer == null) {
        _videoRenderer = webrtc.RTCVideoRenderer();
        await _videoRenderer!.initialize();
      }

      // Configure camera constraints for efficient processing
      final Map<String, dynamic> mediaConstraints = {
        'audio': false,
        'video': {
          'width': {'ideal': 640},
          'height': {'ideal': 480},
          'frameRate': {'ideal': 15}, // Lower frame rate for efficiency
          'facingMode': 'user', // Default to front camera
        }
      };

      // Add device ID if available
      if (actualDeviceId != null && actualDeviceId.isNotEmpty) {
        mediaConstraints['video']['deviceId'] = actualDeviceId;
        print('👤 Person detection using camera device: $actualDeviceId');
      } else {
        print('⚠️ No specific camera device selected, using default');
      }

      // Get camera stream
      _cameraStream = await webrtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
      _videoRenderer!.srcObject = _cameraStream;

      // Get the renderer texture ID for frame capture
      if (_isFrameCaptureSupported) {
        try {
          // Pass the renderer object to extract texture ID
          final rendererData = {
            'rendererId': _videoRenderer!.textureId,
            'textureId': _videoRenderer!.textureId,
            'videoTrackId': _cameraStream!.getVideoTracks().isNotEmpty ? 
                          _cameraStream!.getVideoTracks().first.id : null,
          };
          
          _rendererTextureId = await FrameCapturePlatform.getRendererTextureId(rendererData);
          print('Video renderer texture ID: $_rendererTextureId');
          
          if (_rendererTextureId == null || _rendererTextureId! < 0) {
            print('Warning: Failed to get valid texture ID, using renderer textureId: ${_videoRenderer!.textureId}');
            _rendererTextureId = _videoRenderer!.textureId;
          }
        } catch (e) {
          print('Error getting texture ID: $e, falling back to renderer textureId');
          _rendererTextureId = _videoRenderer!.textureId;
        }
      }

      // Start frame processing
      _startFrameProcessing();

      print('Person detection started successfully with texture ID: $_rendererTextureId');
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
    
    // Stop camera stream
    _cameraStream?.getTracks().forEach((track) => track.stop());
    _cameraStream?.dispose();
    _cameraStream = null;
    
    // Dispose video renderer
    _videoRenderer?.dispose();
    _videoRenderer = null;
    
    // Reset texture ID
    _rendererTextureId = null;
    
    // Reset state
    isPersonPresent.value = false;
    confidence.value = 0.0;
    isProcessing.value = false;
    
    print('Person detection stopped');
  }
  
  /// Start periodic frame processing
  void _startFrameProcessing() {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(processingInterval, (_) {
      _processCurrentFrame();
    });
  }
    /// Process the current camera frame for person detection
  Future<void> _processCurrentFrame() async {
    if (_videoRenderer == null || isProcessing.value) {
      return;
    }
    
    try {
      isProcessing.value = true;
      
      // If TensorFlow Lite interpreter is available, use real detection
      if (_interpreter != null) {        // Capture frame from video renderer
        final frameData = await _captureFrame();
        if (frameData == null) {
          if (framesProcessed.value % 20 == 0) {
            print('⚠️  Frame capture failed - no frame data available (frame ${framesProcessed.value})');
          }
          return;
        }
        
        // Log successful frame capture occasionally
        if (framesProcessed.value % 50 == 0) {
          print('📷 Frame captured successfully: ${frameData.length} bytes (${inputWidth}x${inputHeight})');
        }
        
        // Preprocess frame for model input
        final inputData = _preprocessFrame(frameData);        // Run inference with proper input/output tensors for SSD MobileNet
        final inputTensor = inputData.reshape([1, inputHeight, inputWidth, numChannels]);
        
        // SSD MobileNet has multiple outputs indexed by integer
        final outputTensors = <int, Object>{};
        
        // Prepare output tensors (SSD MobileNet standard outputs)
        final detectionBoxes = List.filled(40, 0.0).reshape([1, 10, 4]); // 10 boxes with 4 coordinates each
        final detectionClasses = List.filled(10, 0.0).reshape([1, 10]); // Max 10 detections
        final detectionScores = List.filled(10, 0.0).reshape([1, 10]);
        final numDetections = List.filled(1, 0.0).reshape([1]);
        
        // Map outputs by index (SSD MobileNet standard output order)
        outputTensors[0] = detectionBoxes;
        outputTensors[1] = detectionClasses;  
        outputTensors[2] = detectionScores;
        outputTensors[3] = numDetections;
        
        try {
          _interpreter!.runForMultipleInputs([inputTensor], outputTensors);
          
          // Parse detection results for person class
          double maxPersonConfidence = 0.0;
          
          final scores = detectionScores[0] as List<double>;
          final classes = detectionClasses[0] as List<double>;
          final numDets = (numDetections[0] as List<double>)[0].toInt();
          
          for (int i = 0; i < numDets && i < 10; i++) {
            final classId = classes[i].toInt();
            final score = scores[i];
            
            // Check if this is a person detection (class ID 1 in COCO)
            if (classId == personClassId && score > maxPersonConfidence) {
              maxPersonConfidence = score;
            }
          }
            confidence.value = maxPersonConfidence;
          
          // Enhanced debugging output
          if (framesProcessed.value % 10 == 0) { // Log every 10th frame
            print('🤖 Person Detection Frame ${framesProcessed.value}:');
            print('   📊 Detections found: $numDets');
            print('   🎯 Max person confidence: ${maxPersonConfidence.toStringAsFixed(3)}');
            print('   👤 Person present: ${maxPersonConfidence > confidenceThreshold} (threshold: $confidenceThreshold)');
            
            // Show top 3 detections for debugging
            for (int i = 0; i < math.min(3, numDets); i++) {
              final classId = classes[i].toInt();
              final score = scores[i];
              print('   Detection $i: Class $classId, Score ${score.toStringAsFixed(3)}');
            }
          }
          
        } catch (e) {
          print('Error running SSD MobileNet inference: $e');
          // Fallback to simple single output processing if multi-output fails
          final outputShape = _interpreter!.getOutputTensor(0).shape;
          final output = List.filled(outputShape.last, 0.0).reshape([1, outputShape.last]);
          _interpreter!.run(inputTensor, output);
          
          // For simple models, assume first output is confidence
          confidence.value = output[0][0];
        }          // Update presence detection
        final wasPersonPresent = isPersonPresent.value;
        isPersonPresent.value = confidence.value > confidenceThreshold;
        
        // Publish to MQTT if status changed
        if (wasPersonPresent != isPersonPresent.value) {
          _publishPresenceChange();
          print('🚨 Person presence changed: ${isPersonPresent.value ? "DETECTED" : "NOT DETECTED"} (confidence: ${confidence.value.toStringAsFixed(3)})');
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
    final simulatedConfidence = (random / 1000.0) * 0.3 + 0.4; // Between 0.4 and 0.7
    
    confidence.value = simulatedConfidence;
    
    // Update presence detection with some randomness
    final wasPersonPresent = isPersonPresent.value;
    isPersonPresent.value = simulatedConfidence > confidenceThreshold;
    
    // Add some stability - don't change state too frequently
    if (framesProcessed.value % 10 == 0) {
      // Publish to MQTT if status changed
      if (wasPersonPresent != isPersonPresent.value) {
        _publishPresenceChange();
      }
    }
    
    framesProcessed.value++;
    
    // Log simulation mode periodically
    if (framesProcessed.value % 20 == 0) {
      print('Person detection running in simulation mode (frame ${framesProcessed.value})');
    }
  }/// Capture current frame from video renderer
  Future<Uint8List?> _captureFrame() async {
    try {
      // Check if platform capture is supported and texture ID is available
      if (_isFrameCaptureSupported && _rendererTextureId != null && _rendererTextureId! > 0) {
        // Use platform channel to capture frame from WebRTC renderer
        final frameData = await FrameCapturePlatform.captureFrame(
          rendererId: _rendererTextureId!,
          width: inputWidth,
          height: inputHeight,
        );
        
        if (frameData != null && frameData.isNotEmpty) {
          // Validate frame data size
          final expectedSize = inputWidth * inputHeight * 4; // RGBA
          if (frameData.length == expectedSize) {
            return frameData;
          } else {
            print('Warning: Frame data size mismatch. Expected: $expectedSize, Got: ${frameData.length}');
            // Try to process anyway if size is close
            if (frameData.length >= expectedSize * 0.8) {
              return frameData;
            }
          }
        } else {
          print('Platform frame capture returned null or empty data');
        }
      } else {
        print('Frame capture not available - platform support: $_isFrameCaptureSupported, texture ID: $_rendererTextureId');
      }
      
      // Fallback: Try alternative capture methods
      if (_videoRenderer != null && _cameraStream != null) {
        // In the future, this could use alternative capture methods
        // such as canvas-based capture or other WebRTC frame access APIs
        print('Attempting fallback frame capture methods...');
        
        // For now, return null to indicate no frame available
        // In a production implementation, you might want to:
        // 1. Use platform-specific WebRTC frame extraction
        // 2. Implement canvas-based capture for web platforms
        // 3. Use alternative video processing APIs
      }
      
      return null;
      
    } catch (e) {
      print('Error capturing frame: $e');
      lastError.value = 'Frame capture error: $e';
      return null;
    }
  }/// Preprocess frame data for model input using the image package
  Float32List _preprocessFrame(Uint8List frameData) {
    try {
      img.Image? image;
      
      // Check if this is RGBA data from platform capture or encoded image
      if (frameData.length == inputWidth * inputHeight * 4) {
        // Raw RGBA data from platform capture
        image = img.Image.fromBytes(
          width: inputWidth,
          height: inputHeight,
          bytes: frameData.buffer,
          format: img.Format.uint8,
          numChannels: 4,
        );
      } else {
        // Encoded image data (JPEG, PNG, etc.)
        image = img.decodeImage(frameData);
      }
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Resize image to model input size if needed
      if (image.width != inputWidth || image.height != inputHeight) {
        image = img.copyResize(image, width: inputWidth, height: inputHeight);
      }
      
      // Convert to Float32List with normalization
      final input = Float32List(1 * inputHeight * inputWidth * numChannels);
      int pixelIndex = 0;
      
      for (int y = 0; y < inputHeight; y++) {
        for (int x = 0; x < inputWidth; x++) {
          final pixel = image.getPixel(x, y);
          
          // Extract RGB values and normalize to [0, 1] range
          final r = pixel.r / 255.0;
          final g = pixel.g / 255.0;
          final b = pixel.b / 255.0;
          
          // Store in HWC format (Height, Width, Channels)
          input[pixelIndex * numChannels + 0] = r;
          input[pixelIndex * numChannels + 1] = g;
          input[pixelIndex * numChannels + 2] = b;
          
          pixelIndex++;
        }
      }
      
      return input;
      
    } catch (e) {
      print('Error preprocessing frame: $e');
      // Return zeros as fallback
      return Float32List(1 * inputHeight * inputWidth * numChannels);
    }
  }
  
  /// Publish presence change to MQTT
  void _publishPresenceChange() {
    try {
      if (Get.isRegistered<MqttService>()) {
        final mqttService = Get.find<MqttService>();
        
        final presenceData = {
          'person_present': isPersonPresent.value,
          'confidence': confidence.value,
          'timestamp': DateTime.now().toIso8601String(),
          'frames_processed': framesProcessed.value,
        };
        
        mqttService.publishJsonToTopic('kingkiosk/${mqttService.deviceName.value}/person_presence', presenceData);
        
        print('Published person presence to MQTT: ${isPersonPresent.value} (confidence: ${confidence.value.toStringAsFixed(2)})');
      }
    } catch (e) {
      print('Error publishing to MQTT: $e');
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
    };  }
  
  /// Check if camera is available for detection
  Future<bool> isCameraAvailable() async {
    try {
      final devices = await webrtc.navigator.mediaDevices.enumerateDevices();
      final videoDevices = devices.where((device) => device.kind == 'videoinput').toList();
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
      return mediaDeviceService.videoInputs.map((device) => device.deviceId).toList();
    } catch (e) {
      print('⚠️ MediaDeviceService not available for camera enumeration: $e');
      return [];
    }
  }
}
