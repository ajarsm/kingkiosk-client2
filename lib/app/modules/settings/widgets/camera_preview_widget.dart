import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import '../../../core/utils/permissions_manager.dart';
import '../../../services/person_detection_service.dart';

/// Camera resolution modes for different use cases
enum CameraResolutionMode {
  preview, // HD preview for settings (1280x720)
  personDetection, // Square format for ML processing (300x300)
  sipCall, // High quality for video calls (720p)
}

/// A widget that displays a live preview of the selected video device
class CameraPreviewWidget extends StatefulWidget {
  final String deviceId;
  final double width;
  final double height;
  final BoxFit fit;
  final CameraResolutionMode resolutionMode;

  const CameraPreviewWidget({
    Key? key,
    required this.deviceId,
    this.width = 320,
    this.height = 240,
    this.fit = BoxFit.contain,
    this.resolutionMode = CameraResolutionMode.preview,
  }) : super(key: key);

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  webrtc.MediaStream? _localStream;
  final _localRenderer = webrtc.RTCVideoRenderer();
  bool _isInitialized = false;
  Timer? _retryTimer;
  int _retryCount = 0;
  final _maxRetryCount = 3;
  bool _permissionDenied = false; // Track permission denial
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  @override
  void didUpdateWidget(CameraPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId) {
      // Device changed, reinitialize with new deviceId
      _disposeStream();
      _initRenderers();
    }
  }

  Future<void> _initRenderers() async {
    // First check current permission status
    final currentCameraStatus =
        await PermissionsManager.checkCameraPermission();
    print(
        '[CameraPreview] Current camera permission: ${currentCameraStatus.status}');

    // Debug permission statuses
    final debugStatuses = await PermissionsManager.debugPermissionStatuses();
    print('[CameraPreview] Debug permissions: $debugStatuses');

    // If already granted, proceed directly
    if (currentCameraStatus.granted) {
      print('[CameraPreview] Camera permission already granted, proceeding...');
      _permissionDenied = false;
      _errorMessage = '';
      await _localRenderer.initialize();
      await _startCamera();
      return;
    }

    // Check if permission is permanently denied
    if (currentCameraStatus.permanentlyDenied) {
      print('[CameraPreview] Camera permission permanently denied');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _permissionDenied = true;
          _errorMessage =
              'Camera access permanently denied. Please enable camera permissions in your device settings.';
        });
      }
      return;
    }

    // Permission is not granted and not permanently denied, try to request it
    print('[CameraPreview] Requesting camera permission...');
    final cameraPermissionResult =
        await PermissionsManager.requestCameraPermission();
    print(
        '[CameraPreview] Camera permission result: ${cameraPermissionResult.status}');

    if (!cameraPermissionResult.granted) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _permissionDenied = true;
          if (cameraPermissionResult.permanentlyDenied) {
            _errorMessage =
                'Camera access permanently denied. Please enable camera permissions in your device settings.';
          } else {
            _errorMessage =
                'Camera permission is required for camera preview. Please allow camera access when prompted.';
          }
        });
      }
      print(
          '[CameraPreview] Camera permission not granted: ${cameraPermissionResult.status}');
      return;
    }

    // Reset permission state if we got here
    _permissionDenied = false;
    _errorMessage = '';

    await _localRenderer.initialize();
    await _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      // Check if PersonDetectionService is active and has a camera stream
      final personDetectionService = Get.isRegistered<PersonDetectionService>()
          ? Get.find<PersonDetectionService>()
          : null;
      final sharedStream = personDetectionService?.cameraStream;
      final isServiceActive = personDetectionService?.isEnabled.value == true &&
          sharedStream != null;

      // NEW: Wait if person detection is initializing
      int maxInitWaits = 5;
      int waits = 0;
      while (personDetectionService?.isInitializing.value == true && waits < maxInitWaits) {
        print('[CameraPreviewWidget] Person detection is initializing, waiting to avoid camera conflict...');
        await Future.delayed(Duration(milliseconds: 500));
        waits++;
      }

      if (isServiceActive) {
        // Use the shared stream from PersonDetectionService
        print(
            '[CameraPreviewWidget] Using shared camera stream from PersonDetectionService.');
        _localStream = sharedStream;
      } else {
        // Only acquire a new stream if the service is not running
        print(
            '[CameraPreviewWidget] Acquiring new camera stream (service not active).');
        final Map<String, dynamic> mediaConstraints = {
          'audio': false, // Only request video for preview
          'video': {
            'deviceId': widget.deviceId.isNotEmpty ? widget.deviceId : null,
          },
        };
        _localStream =
            await webrtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
      }
      await _localRenderer.srcObject?.dispose();
      _localRenderer.srcObject = _localStream;

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _permissionDenied = false;
          _errorMessage = '';
        });
      }
    } catch (e) {
      print('Error initializing camera preview: $e');

      // Handle permission-related errors specifically
      final errorStr = e.toString().toLowerCase();
      bool isPermissionError = errorStr.contains('permission') ||
          errorStr.contains('notallowed') ||
          errorStr.contains('denied');

      if (mounted) {
        setState(() {
          _permissionDenied = isPermissionError;
          _errorMessage = isPermissionError
              ? 'Camera access denied. Please allow camera permissions and try again.'
              : 'Failed to access camera: ${e.toString()}';
        });
      }

      // Only retry for non-permission errors
      if (!isPermissionError) {
        _scheduleRetry();
      }
    }
  }

  void _scheduleRetry() {
    // Only retry a limited number of times
    if (_retryCount < _maxRetryCount) {
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(seconds: 1), () {
        _retryCount++;
        _startCamera();
      });
    }
  }

  void _disposeStream() {
    _retryTimer?.cancel();
    // Prevent disposing the shared stream used by PersonDetectionService
    try {
      final personDetectionService = Get.isRegistered<PersonDetectionService>()
          ? Get.find<PersonDetectionService>()
          : null;
      final sharedStream = personDetectionService?.cameraStream;
      if (_localStream != null && _localStream != sharedStream) {
        print('[CameraPreviewWidget] Disposing local camera stream.');
        _localStream?.getTracks().forEach((track) {
          track.stop();
        });
        _localStream?.dispose();
      } else if (_localStream == sharedStream) {
        print('[CameraPreviewWidget] Not disposing shared camera stream.');
      }
    } catch (e) {
      // If PersonDetectionService is not available, dispose as normal
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      _localStream?.dispose();
    }
    _localStream = null;
  }

  @override
  void dispose() {
    _disposeStream();
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: _buildCameraContent(context),
      ),
    );
  }

  Widget _buildCameraContent(BuildContext context) {
    if (_permissionDenied) {
      return _buildPermissionDeniedWidget(context);
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget(context);
    }

    return webrtc.RTCVideoView(
      _localRenderer,
      objectFit: widget.fit == BoxFit.contain
          ? webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
          : webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      mirror: true, // Usually selfie cameras need mirroring
    );
  }

  Widget _buildPermissionDeniedWidget(BuildContext context) {
    final isPermanentlyDenied = _errorMessage.contains('permanently denied');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: Colors.white54,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isPermanentlyDenied) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await PermissionsManager.openAppSettings();
                  if (result) {
                    // Retry initialization after user returns from settings
                    _retryCount = 0;
                    _initRenderers();
                  }
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _permissionDenied = false;
                    _errorMessage = '';
                    _retryCount = 0;
                  });
                  _initRenderers();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Grant Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 12),
          Text(
            'Initializing camera...',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = '';
                  _retryCount = 0;
                });
                _initRenderers();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
