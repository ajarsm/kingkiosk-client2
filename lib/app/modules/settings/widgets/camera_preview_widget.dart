import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/utils/permissions_manager.dart'; // Import PermissionsManager

/// A widget that displays a live preview of the selected video device
class CameraPreviewWidget extends StatefulWidget {
  final String deviceId;
  final double width;
  final double height;
  final BoxFit fit;

  const CameraPreviewWidget({
    Key? key,
    required this.deviceId,
    this.width = 320,
    this.height = 240,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  MediaStream? _localStream;
  final _localRenderer = RTCVideoRenderer();
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
      final Map<String, dynamic> mediaConstraints = {
        'audio': false,
        'video': {
          'deviceId': widget.deviceId,
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        }
      };

      _localStream = await MediaDevices.getUserMedia(mediaConstraints);
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
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
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
        child: RTCVideoView(
          _localRenderer,
          objectFit: widget.fit == BoxFit.contain
              ? RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
              : RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          mirror: true, // Usually selfie cameras need mirroring
        ),
      ),
    );
  }
}
