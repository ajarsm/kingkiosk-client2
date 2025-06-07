import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import '../../../core/utils/permissions_manager.dart'; // Import PermissionsManager
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
    // Request camera permission before initializing renderer (mobile only)
    final hasPermission =
        await PermissionsManager.requestCameraAndMicPermissions();
    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
      print('Camera/mic permission not granted. Cannot start camera preview.');
      return;
    }
    await _localRenderer.initialize();
    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      // Determine camera constraints based on resolution mode
      switch (widget.resolutionMode) {
        case CameraResolutionMode.personDetection:
          // Square 300x300 for person detection ML processing
          break;
        case CameraResolutionMode.sipCall:
          // High quality 720p for SIP video calls
          break;
        case CameraResolutionMode.preview:
        default:
          // HD quality for settings preview
          break;
      }

      final Map<String, dynamic> mediaConstraints = {
        'audio': false,
        'video': true,
      };

      _localStream =
          await webrtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
      await _localRenderer.srcObject?.dispose();
      _localRenderer.srcObject = _localStream;

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera preview: $e');
      _scheduleRetry();
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
        _localStream?.getTracks().forEach((track) {
          track.stop();
        });
        _localStream?.dispose();
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
    if (!_isInitialized) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: webrtc.RTCVideoView(
          _localRenderer,
          objectFit: widget.fit == BoxFit.contain
              ? webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
              : webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          mirror: true, // Usually selfie cameras need mirroring
        ),
      ),
    );
  }
}
