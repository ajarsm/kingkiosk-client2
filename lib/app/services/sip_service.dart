import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:sip_ua/sip_ua.dart';
import '../services/storage_service.dart';
import '../services/media_device_service.dart';
import '../core/utils/app_constants.dart';
import 'person_detection_service.dart';

/// Service for managing SIP UA connections
class SipService extends GetxService implements SipUaHelperListener {
  // Dependencies
  final StorageService _storageService;

  // SIP UA instance
  late final SIPUAHelper _helper;
  // Service state
  final isRegistered = false.obs;
  final currentCall = Rx<Call?>(null);
  final lastError = ''.obs;
  final callState = ''.obs;
  final isLocalVideoEnabled = true.obs; // Track video state
  final isCallMuted = false.obs; // Track mute state

  // Media device service reference for device enumeration
  MediaDeviceService? get _mediaDeviceService {
    try {
      return Get.find<MediaDeviceService>();
    } catch (e) {
      debugPrint('MediaDeviceService not available: $e');
      return null;
    }
  }

  // Device lists - delegate to MediaDeviceService
  List<webrtc.MediaDeviceInfo> get audioInputs =>
      _mediaDeviceService?.audioInputs ?? [];
  List<webrtc.MediaDeviceInfo> get videoInputs =>
      _mediaDeviceService?.videoInputs ?? [];
  List<webrtc.MediaDeviceInfo> get audioOutputs =>
      _mediaDeviceService?.audioOutputs ?? [];

  // Selected devices - delegate to MediaDeviceService
  webrtc.MediaDeviceInfo? get selectedAudioInput =>
      _mediaDeviceService?.selectedAudioInput.value;
  webrtc.MediaDeviceInfo? get selectedVideoInput =>
      _mediaDeviceService?.selectedVideoInput.value;
  webrtc.MediaDeviceInfo? get selectedAudioOutput =>
      _mediaDeviceService?.selectedAudioOutput.value;

  // Settings
  final serverHost = ''.obs;
  final deviceName = ''.obs; // SIP contact uses this as username
  final protocol = 'wss'.obs; // WebSocket protocol (ws or wss)
  final enabled = false.obs;

  // Constructor
  SipService(this._storageService) {
    _helper = SIPUAHelper();
  }

  /// Initialize the service
  Future<SipService> init() async {
    try {
      // Load settings
      serverHost.value =
          _storageService.read<String>(AppConstants.keySipServerHost) ??
              AppConstants.defaultSipServerHost;
      protocol.value =
          _storageService.read<String>(AppConstants.keySipProtocol) ?? 'wss';
      enabled.value =
          _storageService.read<bool>(AppConstants.keySipEnabled) ?? false;

      // Load device name - critical for registration
      deviceName.value =
          _storageService.read<String>(AppConstants.keyDeviceName) ??
              ''; // Register for SIP UA events
      _helper.addSipUaHelperListener(this);

      // Device enumeration is now handled by MediaDeviceService
      // No need to load devices here - they're available via MediaDeviceService

      // Auto-register if enabled and we have a device name
      if (enabled.value) {
        // Give a bit more time for other services to initialize
        Future.delayed(Duration(seconds: 3), () {
          if (deviceName.value.isNotEmpty) {
            debugPrint(
                'Auto-registering SIP with device name: ${deviceName.value}');
            register();
          } else {
            debugPrint('Cannot auto-register SIP: missing device name');
          }
        });
      }

      return this;
    } catch (e) {
      debugPrint('Error initializing SipService: $e');
      return this;
    }
  }

  /// Cleanup on service destruction
  void dispose() {
    try {
      // Ensure we're unregistered when the service is disposed
      if (isRegistered.value) {
        unregister();
      }
    } catch (e) {
      debugPrint('Error unregistering SIP: $e');
    }
    _helper.removeSipUaHelperListener(this);
  }

  @override
  void onClose() {
    // Make sure to clean up when GetX service is closed
    dispose();
    super.onClose();
  }

  /// Register with SIP server
  Future<bool> register() async {
    if (serverHost.value.isEmpty || deviceName.value.isEmpty) {
      lastError.value = 'Missing server host or device name';
      debugPrint('SIP registration failed: Missing server host or device name');
      return false;
    }

    try {
      debugPrint(
          'Attempting to register SIP server: ${protocol.value}://${serverHost.value}');
      final UaSettings settings = UaSettings();

      // Sanitize device name for SIP use (no spaces or special characters)
      final String sanitizedName = deviceName.value
          .replaceAll(RegExp(r'\s+'), '-')
          .replaceAll(RegExp(r'[^A-Za-z0-9-]'), '')
          .toLowerCase();

      // Set server settings - all required fields must be non-null
      settings.webSocketUrl = '${protocol.value}://${serverHost.value}/ws';
      settings.displayName = deviceName.value;
      settings.userAgent = 'KingKiosk';
      settings.uri = '${sanitizedName}@${serverHost.value}';
      settings.authorizationUser = sanitizedName;
      settings.password =
          ''; // Empty password is fine if server doesn't require it
      settings.transportType = TransportType.WS; // Required in newer versions

      // Additional settings that might help avoid issues
      settings.register = true; // Explicitly set register flag
      settings.sessionTimers = true;
      settings.iceGatheringTimeout =
          1000; // Increase timeout for better connection chances

      // Other settings
      settings.dtmfMode = DtmfMode.INFO;

      // Verify all required fields are set
      if (settings.webSocketUrl == null ||
          settings.uri == null ||
          settings.transportType == null) {
        throw Exception('Required SIP settings are missing');
      }

      _helper.start(settings);
      debugPrint('SIP UA registration initiated');
      return true;
    } catch (e, stacktrace) {
      lastError.value = 'Failed to register: $e';
      debugPrint('SIP registration error: $e');
      debugPrint('Stack trace: $stacktrace');
      return false;
    }
  }

  /// Unregister from SIP server
  Future<bool> unregister() async {
    try {
      debugPrint('Unregistering from SIP server');

      // End any ongoing call first
      if (currentCall.value != null) {
        try {
          currentCall.value!.hangup();
        } catch (e) {
          debugPrint('Error hanging up call during unregister: $e');
          // Continue with unregistration even if hangup fails
        } finally {
          currentCall.value = null;
        }
      }

      // Reset states
      isCallMuted.value = false;
      isLocalVideoEnabled.value = true;

      // Stop the SIP UA helper
      _helper.stop();
      debugPrint('SIP UA unregistered successfully');
      return true;
    } catch (e) {
      lastError.value = 'Failed to unregister: $e';
      debugPrint('Failed to unregister from SIP server: $e');
      return false;
    }
  }

  /// Refresh device list by asking MediaDeviceService to reload
  Future<void> loadDevices() async {
    final mediaService = _mediaDeviceService;
    if (mediaService != null) {
      await mediaService.refreshDevices();
      debugPrint('📱 Device enumeration refreshed via MediaDeviceService');
      debugPrint('   🎤 Audio inputs: ${audioInputs.length}');
      debugPrint('   📹 Video inputs: ${videoInputs.length}');
      debugPrint('   🔊 Audio outputs: ${audioOutputs.length}');
    } else {
      debugPrint('⚠️ MediaDeviceService not available for device enumeration');
    }
  }

  /// Device selection is now handled by MediaDeviceService
  /// This method is kept for compatibility but does nothing
  Future<void> loadSelectedDevices() async {
    debugPrint('📱 Device selection is now managed by MediaDeviceService');
    // Selected devices are accessed via MediaDeviceService getters
  }

  /// Set audio input device
  Future<void> setAudioInput(webrtc.MediaDeviceInfo device) async {
    final mediaService = _mediaDeviceService;
    if (mediaService != null) {
      mediaService.setAudioInput(device);
      debugPrint(
          '🎤 Audio input changed via MediaDeviceService: ${device.label}');
    } else {
      debugPrint('⚠️ MediaDeviceService not available for audio input change');
      return;
    }

    // Apply to current call if exists - this requires advanced WebRTC handling
    if (currentCall.value != null) {
      try {
        debugPrint('Attempting to change microphone to: ${device.label}');
        // This would require accessing the RTCPeerConnection from currentCall and replacing tracks
        // In a real implementation, you would access the RTCPeerConnection
        // and replace the audio track with a new one from the selected device
        // This is complex and would require direct WebRTC manipulation
      } catch (e) {
        debugPrint('Error changing microphone: $e');
      }
    }
  }

  /// Set video input device
  Future<void> setVideoInput(webrtc.MediaDeviceInfo device) async {
    final mediaService = _mediaDeviceService;
    if (mediaService != null) {
      mediaService.setVideoInput(device);
      debugPrint(
          '📹 Video input changed via MediaDeviceService: ${device.label}');
    } else {
      debugPrint('⚠️ MediaDeviceService not available for video input change');
      return;
    }

    // Notify PersonDetectionService of camera change if it's active and enabled
    try {
      final personDetectionService = Get.find<PersonDetectionService>();
      if (personDetectionService.isEnabled.value &&
          personDetectionService.isProcessing.value) {
        debugPrint(
            '📷 Camera changed, switching person detection to: ${device.label}');
        await personDetectionService.switchCamera(device.deviceId);
      }
    } catch (e) {
      // PersonDetectionService may not be available - that's okay
      debugPrint(
          'PersonDetectionService not available for camera change notification: $e');
    }

    // Apply to current call if exists
    if (currentCall.value != null) {
      try {
        debugPrint('Attempting to change camera to: ${device.label}');
        // This would require accessing the RTCPeerConnection from currentCall and replacing tracks
        // Similar to audio input, this would require direct WebRTC manipulation
        // to replace the video track
      } catch (e) {
        debugPrint('Error changing camera: $e');
      }
    }
  }

  /// Set audio output device
  Future<void> setAudioOutput(webrtc.MediaDeviceInfo device) async {
    final mediaService = _mediaDeviceService;
    if (mediaService != null) {
      mediaService.setAudioOutput(device);
      debugPrint(
          '🔊 Audio output changed via MediaDeviceService: ${device.label}');
    } else {
      debugPrint('⚠️ MediaDeviceService not available for audio output change');
      return;
    }

    // Apply to current call if exists
    if (currentCall.value != null) {
      try {
        debugPrint('Attempting to change speaker to: ${device.label}');
        // This would involve setting the sink ID on the audio element
        // in WebRTC, which requires platform-specific handling
      } catch (e) {
        debugPrint('Error changing speaker: $e');
      }
    }
  }

  /// Set SIP protocol (ws or wss)
  void setProtocol(String newProtocol) {
    if (newProtocol != 'ws' && newProtocol != 'wss') {
      debugPrint('Invalid SIP protocol: $newProtocol. Must be "ws" or "wss"');
      return;
    }

    protocol.value = newProtocol;
    _storageService.write(AppConstants.keySipProtocol, newProtocol);
    debugPrint('SIP protocol set to: $newProtocol');

    // Re-register if already registered
    if (isRegistered.value) {
      unregister();
      Future.delayed(Duration(milliseconds: 500), () {
        register();
      });
    }
  }

  /// Set server host
  void setServerHost(String host) {
    // Sanitize host - remove any protocol prefix and trailing slashes
    String sanitizedHost = host.trim();
    // Check for protocol prefixes and set the protocol value accordingly
    if (sanitizedHost.startsWith('http://')) {
      sanitizedHost = sanitizedHost.substring(7);
      // Don't change protocol as http != ws
    } else if (sanitizedHost.startsWith('https://')) {
      sanitizedHost = sanitizedHost.substring(8);
      // Don't change protocol as https != wss
    } else if (sanitizedHost.startsWith('wss://')) {
      protocol.value = 'wss';
      sanitizedHost = sanitizedHost.substring(6);
    } else if (sanitizedHost.startsWith('ws://')) {
      protocol.value = 'ws';
      sanitizedHost = sanitizedHost.substring(5);
    }

    // Remove trailing slashes and /ws if present
    sanitizedHost = sanitizedHost.replaceAll(RegExp(r'\/+$'), '');
    sanitizedHost = sanitizedHost.replaceAll(RegExp(r'\/ws$'), '');

    serverHost.value = sanitizedHost;
    _storageService.write(AppConstants.keySipServerHost, sanitizedHost);
    debugPrint('SIP server host set to: $sanitizedHost');

    // Re-register if already registered
    if (isRegistered.value) {
      unregister();
      Future.delayed(Duration(milliseconds: 500), () {
        register();
      });
    }
  }

  /// Enable or disable SIP
  void setEnabled(bool value) {
    enabled.value = value;
    _storageService.write(AppConstants.keySipEnabled, value);

    if (value && !isRegistered.value) {
      register();
    } else if (!value && isRegistered.value) {
      unregister();
    }
  }

  // Implementation of SipUaHelperListener methods

  @override
  void registrationStateChanged(RegistrationState state) {
    debugPrint('Registration state: ${state.state}');

    if (state.state == RegistrationStateEnum.REGISTERED) {
      isRegistered.value = true;
      debugPrint('SIP UA registered successfully');
    } else if (state.state == RegistrationStateEnum.UNREGISTERED) {
      isRegistered.value = false;
      debugPrint('SIP UA unregistered. Cause: ${state.cause}');
    } else if (state.state == RegistrationStateEnum.REGISTRATION_FAILED) {
      isRegistered.value = false;
      lastError.value = 'Registration failed: ${state.cause}';
      debugPrint('SIP UA registration failed: ${state.cause}');
    }
  }

  @override
  void callStateChanged(Call call, CallState state) {
    debugPrint('Call state changed: ${state.state}');
    callState.value = state.state.toString();

    if (state.state == CallStateEnum.CALL_INITIATION) {
      currentCall.value = call;
      // Reset state when starting a new call
      isCallMuted.value = false;
      isLocalVideoEnabled.value = true;

      // Upgrade camera to 720p for better call quality
      _upgradeCameraResolutionForCall();
    } else if (state.state == CallStateEnum.ENDED) {
      currentCall.value = null;
      // Reset state when call ends
      isCallMuted.value = false;
      isLocalVideoEnabled.value = true;

      // Downgrade camera back to 300x300 for person detection
      _downgradeCameraResolutionAfterCall();
    }
  }

  /// Upgrade camera resolution to 720p when a SIP call starts
  Future<void> _upgradeCameraResolutionForCall() async {
    try {
      // Get PersonDetectionService if available
      if (Get.isRegistered<PersonDetectionService>()) {
        final personDetectionService = Get.find<PersonDetectionService>();
        final success = await personDetectionService.upgradeTo720p();
        if (success) {
          debugPrint('📹 Camera upgraded to 720p for SIP call');
        } else {
          debugPrint('⚠️ Failed to upgrade camera to 720p for SIP call');
        }
      }
    } catch (e) {
      debugPrint('Error upgrading camera resolution for call: $e');
    }
  }

  /// Downgrade camera resolution to 300x300 when a SIP call ends
  Future<void> _downgradeCameraResolutionAfterCall() async {
    try {
      // Get PersonDetectionService if available
      if (Get.isRegistered<PersonDetectionService>()) {
        final personDetectionService = Get.find<PersonDetectionService>();
        final success = await personDetectionService.downgradeTo300x300();
        if (success) {
          debugPrint('📹 Camera downgraded to 300x300 for person detection');
        } else {
          debugPrint('⚠️ Failed to downgrade camera to 300x300 after call');
        }
      }
    } catch (e) {
      debugPrint('Error downgrading camera resolution after call: $e');
    }
  }

  @override
  void transportStateChanged(TransportState state) {
    debugPrint('Transport state: ${state.state}');
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    debugPrint('New SIP message received');
  }

  @override
  void onNewNotify(Notify notify) {
    debugPrint('New SIP notification received');
  }

  @override
  void onNewReinvite(ReInvite event) {
    debugPrint('New SIP re-invite received');
  }

  // Call handling methods

  /// Format a dial string as a SIP URI if needed
  String formatDialString(String input) {
    // If input is a valid IPv4 address or domain, format as SIP URI
    final ipRegex = RegExp(r'^(?:\d{1,3}\.){3}\d{1,3}\$');
    final domainRegex = RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$');
    if ((ipRegex.hasMatch(input) || domainRegex.hasMatch(input)) &&
        !input.startsWith('sip:')) {
      return 'sip:' + input;
    }
    return input;
  }

  /// Make a call to a SIP address
  Future<bool> makeCall(String target, {bool video = false}) async {
    if (!isRegistered.value) {
      lastError.value = 'Not registered with SIP server';
      return false;
    }

    try {
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': video,
      }; // Add device constraints if selected
      if (selectedAudioInput != null) {
        mediaConstraints['audio'] = {
          'deviceId': {'exact': selectedAudioInput!.deviceId},
        };
      }

      if (video && selectedVideoInput != null) {
        mediaConstraints['video'] = {
          'deviceId': {'exact': selectedVideoInput!.deviceId},
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        };
      }

      final customOptions = <String, dynamic>{
        'mediaConstraints': mediaConstraints,
        'pcConfig': {
          'iceServers': [
            {'urls': 'stun:stun.l.google.com:19302'},
          ],
        },
      };

      // Format the target as a SIP URI if needed
      final formattedTarget = formatDialString(target);

      final result = await _helper.call(formattedTarget,
          voiceOnly: !video, customOptions: customOptions);

      // Call object will be assigned in callStateChanged callback
      return result;
    } catch (e) {
      lastError.value = 'Call failed: $e';
      return false;
    }
  }

  /// End the current call
  void hangUp() {
    if (currentCall.value != null) {
      try {
        currentCall.value!.hangup();
        currentCall.value = null;

        // Reset mute and video states
        isCallMuted.value = false;
        isLocalVideoEnabled.value = true;

        // Downgrade camera resolution when manually ending call
        _downgradeCameraResolutionAfterCall();
      } catch (e) {
        lastError.value = 'Hangup failed: $e';
      }
    }
  }

  /// Mute/unmute the current call
  void toggleMute() {
    if (currentCall.value == null) return;

    try {
      final call = currentCall.value!;
      if (isCallMuted.value) {
        call.unmute();
        isCallMuted.value = false;
        debugPrint('Microphone unmuted');
      } else {
        call.mute();
        isCallMuted.value = true;
        debugPrint('Microphone muted');
      }
    } catch (e) {
      lastError.value = 'Toggle mute failed: $e';
      debugPrint('Error toggling mute: $e');
    }
  }

  /// Enable/disable video on the current call
  void toggleVideo() {
    if (currentCall.value == null) return;

    try {
      final call = currentCall.value!;

      // Toggle our internal state
      isLocalVideoEnabled.value = !isLocalVideoEnabled.value;

      // Access the peerConnection to get local stream
      if (call.peerConnection != null) {
        final localStreams = call.peerConnection!.getLocalStreams();
        if (localStreams.isNotEmpty && localStreams.first != null) {
          final stream = localStreams.first;
          if (stream != null) {
            final videoTracks = stream.getVideoTracks();
            for (var track in videoTracks) {
              track.enabled = isLocalVideoEnabled.value;
            }
          }
        }

        debugPrint(
            'Video ${isLocalVideoEnabled.value ? 'enabled' : 'disabled'}');
      } else {
        debugPrint('Could not toggle video: No active video stream');
      }
    } catch (e) {
      lastError.value = 'Toggle video failed: $e';
      debugPrint('Error toggling video: $e');
    }
  }
}
