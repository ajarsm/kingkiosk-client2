import 'package:flutter/material.dart';

class LocalCameraPreviewWidget extends StatelessWidget {
  final String deviceId;

  const LocalCameraPreviewWidget({Key? key, required this.deviceId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Camera preview functionality removed'),
    );
  }
}
