import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../core/utils/app_constants.dart';

/// Service for managing media device enumeration and selection
/// This service is independent of SIP calling functionality
class MediaDeviceService extends GetxService {
  // Dependencies
  final StorageService _storageService = Get.find<StorageService>();

  // Device lists for media selection
  final audioInputs = <webrtc.MediaDeviceInfo>[].obs;
  final videoInputs = <webrtc.MediaDeviceInfo>[].obs;
  final audioOutputs = <webrtc.MediaDeviceInfo>[].obs;

  // Selected devices
  final selectedAudioInput = Rx<webrtc.MediaDeviceInfo?>(null);
  final selectedVideoInput = Rx<webrtc.MediaDeviceInfo?>(null);
  final selectedAudioOutput = Rx<webrtc.MediaDeviceInfo?>(null);

  // Service state
  final isInitialized = false.obs;
  final lastError = ''.obs;

  /// Initialize the service
  Future<MediaDeviceService> init() async {
    try {
      debugPrint('🎥 Initializing MediaDeviceService...');
      
      // Load available devices
      await loadDevices();

      // Load selected device IDs from storage and set selected
      await loadSelectedDevices();

      isInitialized.value = true;
      debugPrint('✅ MediaDeviceService initialized successfully');
      debugPrint('📱 Available devices:');
      debugPrint('   🎤 Audio inputs: ${audioInputs.length}');
      debugPrint('   📹 Video inputs: ${videoInputs.length}');
      debugPrint('   🔊 Audio outputs: ${audioOutputs.length}');

      return this;
    } catch (e) {
      lastError.value = 'Failed to initialize MediaDeviceService: $e';
      debugPrint('❌ Error initializing MediaDeviceService: $e');
      return this;
    }
  }

  /// Load available media devices
  Future<void> loadDevices() async {
    try {
      debugPrint('🔍 Enumerating media devices...');
      final devices = await webrtc.navigator.mediaDevices.enumerateDevices();

      audioInputs.value = devices
          .where((device) => device.kind == 'audioinput')
          .cast<webrtc.MediaDeviceInfo>()
          .toList();

      videoInputs.value = devices
          .where((device) => device.kind == 'videoinput')
          .cast<webrtc.MediaDeviceInfo>()
          .toList();

      audioOutputs.value = devices
          .where((device) => device.kind == 'audiooutput')
          .cast<webrtc.MediaDeviceInfo>()
          .toList();

      debugPrint('📊 Device enumeration complete:');
      debugPrint('   🎤 Audio inputs: ${audioInputs.length}');
      for (var device in audioInputs) {
        debugPrint('      - ${device.label} (${device.deviceId})');
      }
      debugPrint('   📹 Video inputs: ${videoInputs.length}');
      for (var device in videoInputs) {
        debugPrint('      - ${device.label} (${device.deviceId})');
      }
      debugPrint('   🔊 Audio outputs: ${audioOutputs.length}');
      for (var device in audioOutputs) {
        debugPrint('      - ${device.label} (${device.deviceId})');
      }
    } catch (e) {
      lastError.value = 'Error enumerating devices: $e';
      debugPrint('❌ Error enumerating devices: $e');
    }
  }

  /// Load selected devices from storage
  Future<void> loadSelectedDevices() async {
    try {
      final savedAudioInputId =
          _storageService.read<String>(AppConstants.keySelectedAudioInput);
      final savedVideoInputId =
          _storageService.read<String>(AppConstants.keySelectedVideoInput);
      final savedAudioOutputId =
          _storageService.read<String>(AppConstants.keySelectedAudioOutput);

      // Set selected audio input
      if (savedAudioInputId != null) {
        final audioInput = audioInputs
            .where((device) => device.deviceId == savedAudioInputId)
            .firstOrNull;
        if (audioInput != null) {
          selectedAudioInput.value = audioInput;
          debugPrint('🎤 Restored audio input: ${audioInput.label}');
        }
      }

      // Set selected video input
      if (savedVideoInputId != null) {
        final videoInput = videoInputs
            .where((device) => device.deviceId == savedVideoInputId)
            .firstOrNull;
        if (videoInput != null) {
          selectedVideoInput.value = videoInput;
          debugPrint('📹 Restored video input: ${videoInput.label}');
        }
      }

      // Set selected audio output
      if (savedAudioOutputId != null) {
        final audioOutput = audioOutputs
            .where((device) => device.deviceId == savedAudioOutputId)
            .firstOrNull;
        if (audioOutput != null) {
          selectedAudioOutput.value = audioOutput;
          debugPrint('🔊 Restored audio output: ${audioOutput.label}');
        }
      }

      // Set defaults if nothing was selected
      if (selectedAudioInput.value == null && audioInputs.isNotEmpty) {
        selectedAudioInput.value = audioInputs.first;
        debugPrint('🎤 Using default audio input: ${audioInputs.first.label}');
      }

      if (selectedVideoInput.value == null && videoInputs.isNotEmpty) {
        selectedVideoInput.value = videoInputs.first;
        debugPrint('📹 Using default video input: ${videoInputs.first.label}');
      }

      if (selectedAudioOutput.value == null && audioOutputs.isNotEmpty) {
        selectedAudioOutput.value = audioOutputs.first;
        debugPrint('🔊 Using default audio output: ${audioOutputs.first.label}');
      }
    } catch (e) {
      lastError.value = 'Error loading selected devices: $e';
      debugPrint('❌ Error loading selected devices: $e');
    }
  }

  /// Set the selected audio input device
  void setAudioInput(webrtc.MediaDeviceInfo device) {
    selectedAudioInput.value = device;
    _storageService.write(AppConstants.keySelectedAudioInput, device.deviceId);
    debugPrint('🎤 Selected audio input: ${device.label}');
  }

  /// Set the selected video input device
  void setVideoInput(webrtc.MediaDeviceInfo device) {
    selectedVideoInput.value = device;
    _storageService.write(AppConstants.keySelectedVideoInput, device.deviceId);
    debugPrint('📹 Selected video input: ${device.label}');
  }

  /// Set the selected audio output device
  void setAudioOutput(webrtc.MediaDeviceInfo device) {
    selectedAudioOutput.value = device;
    _storageService.write(AppConstants.keySelectedAudioOutput, device.deviceId);
    debugPrint('🔊 Selected audio output: ${device.label}');
  }

  /// Refresh device list (useful when devices are plugged/unplugged)
  Future<void> refreshDevices() async {
    debugPrint('🔄 Refreshing media devices...');
    await loadDevices();
    await loadSelectedDevices();
  }

  /// Check if a specific device type is available
  bool hasAudioInputs() => audioInputs.isNotEmpty;
  bool hasVideoInputs() => videoInputs.isNotEmpty;
  bool hasAudioOutputs() => audioOutputs.isNotEmpty;

  /// Get device by ID
  webrtc.MediaDeviceInfo? getAudioInputById(String deviceId) {
    return audioInputs.where((device) => device.deviceId == deviceId).firstOrNull;
  }

  webrtc.MediaDeviceInfo? getVideoInputById(String deviceId) {
    return videoInputs.where((device) => device.deviceId == deviceId).firstOrNull;
  }

  webrtc.MediaDeviceInfo? getAudioOutputById(String deviceId) {
    return audioOutputs.where((device) => device.deviceId == deviceId).firstOrNull;
  }

  /// Get current status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'initialized': isInitialized.value,
      'audio_inputs': audioInputs.length,
      'video_inputs': videoInputs.length,
      'audio_outputs': audioOutputs.length,
      'selected_audio_input': selectedAudioInput.value?.label,
      'selected_video_input': selectedVideoInput.value?.label,
      'selected_audio_output': selectedAudioOutput.value?.label,
      'last_error': lastError.value,
    };
  }

  @override
  void onClose() {
    debugPrint('🔌 MediaDeviceService disposed');
    super.onClose();
  }
}
