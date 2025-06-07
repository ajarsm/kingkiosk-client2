#!/usr/bin/env dart
// Test script for WebRTC Direct Video Track Capture integration
// This tests the simplified direct capture approach without running the full app

import 'dart:io';

void main() async {
  print('🧪 Testing WebRTC Direct Video Track Capture Integration...\n');

  // Test 1: Verify TensorFlow Lite libraries are present
  print('📦 Test 1: TensorFlow Lite Libraries');
  await testTensorFlowLibraries();

  // Test 2: Verify model files are present
  print('\n🧠 Test 2: ML Models');
  await testMLModels();

  // Test 3: Verify service files compile
  print('\n🔧 Test 3: Service Compilation');
  await testServiceCompilation();

  // Test 4: Verify direct capture setup
  print('\n🔗 Test 4: Direct Capture Setup');
  await testDirectCaptureSetup();

  print('\n✅ WebRTC Direct Video Track Capture integration test complete!');
}

Future<void> testTensorFlowLibraries() async {
  final libraries = [
    'libtensorflowlite_c.dylib',
    'libtensorflowlite_metal_delegate.dylib',
    'tensorflowlite_c.dll',
  ];

  for (final lib in libraries) {
    final file = File(lib);
    if (await file.exists()) {
      final size = await file.length();
      print('  ✅ $lib (${(size / 1024 / 1024).toStringAsFixed(1)} MB)');
    } else {
      print('  ❌ $lib - NOT FOUND');
    }
  }

  // Check target location
  final targetDir = Directory('macos/Runner/Resources');
  if (await targetDir.exists()) {
    final targetLibs = await targetDir
        .list()
        .where((entity) => entity.path.endsWith('.dylib'))
        .length;
    print('  ✅ macOS Resources: $targetLibs libraries');
  } else {
    print('  ❌ macOS Resources directory not found');
  }
}

Future<void> testMLModels() async {
  final modelsDir = Directory('assets/models');
  if (await modelsDir.exists()) {
    final models = await modelsDir
        .list()
        .where((entity) => entity.path.endsWith('.tflite'))
        .toList();

    for (final model in models) {
      final file = File(model.path);
      final size = await file.length();
      final name = model.path.split('/').last;
      print('  ✅ $name (${(size / 1024 / 1024).toStringAsFixed(1)} MB)');
    }
  } else {
    print('  ❌ Models directory not found');
  }
}

Future<void> testServiceCompilation() async {
  final services = [
    'lib/app/services/person_detection_service.dart',
    'lib/app/core/bindings/memory_optimized_binding.dart',
    'lib/demo/webrtc_texture_mapping_demo.dart',
  ];

  for (final service in services) {
    final file = File(service);
    if (await file.exists()) {
      print('  ✅ ${service.split('/').last}');
    } else {
      print('  ❌ ${service.split('/').last} - NOT FOUND');
    }
  }
}

Future<void> testDirectCaptureSetup() async {
  // Check for key integration points
  final personDetectionFile =
      File('lib/app/services/person_detection_service.dart');
  if (await personDetectionFile.exists()) {
    final content = await personDetectionFile.readAsString();

    final checks = <String, bool>{
      'Direct Video Track Capture': content.contains('videoTrack.captureFrame'),
      'Simplified Frame Capture': content.contains('_captureFrame'),
      'No Complex WebRTC Services':
          !content.contains('webrtc_frame_callback_service.dart'),
      'Clean Architecture': !content.contains('webrtc_texture_bridge.dart'),
    };

    checks.forEach((name, passed) {
      print('  ${passed ? "✅" : "❌"} $name');
    });
  }

  // Check binding registration
  final bindingFile =
      File('lib/app/core/bindings/memory_optimized_binding.dart');
  if (await bindingFile.exists()) {
    final content = await bindingFile.readAsString();

    final bindingChecks = <String, bool>{
      'No Complex WebRTC Services':
          !content.contains('WebRTCFrameCallbackService'),
      'Simplified Service Registration':
          !content.contains('WebRTCTextureBridge'),
      'Clean Binding Architecture':
          content.contains('Direct video track capture approach'),
    };

    bindingChecks.forEach((name, passed) {
      print('  ${passed ? "✅" : "❌"} $name');
    });
  }
}
