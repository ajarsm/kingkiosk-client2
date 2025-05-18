import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';

class LocalCameraPreviewWidget extends StatefulWidget {
  final String deviceId;
  const LocalCameraPreviewWidget({Key? key, required this.deviceId})
      : super(key: key);

  @override
  State<LocalCameraPreviewWidget> createState() =>
      _LocalCameraPreviewWidgetState();
}

class _LocalCameraPreviewWidgetState extends State<LocalCameraPreviewWidget> {
  RTCVideoRenderer _renderer = RTCVideoRenderer();
  MediaStream? _stream;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void didUpdateWidget(covariant LocalCameraPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId) {
      _disposeStream();
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    await _renderer.initialize();
    try {
      final videoConstraints = kIsWeb
          ? {
              'deviceId': {'exact': widget.deviceId},
              'width': 640,
              'height': 360,
            }
          : {
              'deviceId': widget.deviceId,
              'width': 640,
              'height': 360,
            };
      final constraints = {
        'audio': false,
        'video': videoConstraints,
      };
      _stream = await navigator.mediaDevices.getUserMedia(constraints);
      _renderer.srcObject = _stream;
      setState(() {});
    } catch (e) {
      // ignore error, show blank
    }
  }

  void _disposeStream() {
    _renderer.srcObject = null;
    _stream?.getTracks().forEach((t) => t.stop());
    _stream = null;
  }

  @override
  void dispose() {
    _disposeStream();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_renderer.srcObject == null) {
      return Center(child: Text('No preview'));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: RTCVideoView(_renderer, mirror: true),
    );
  }
}
