import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:sip_ua/sip_ua.dart';
import '../services/storage_service.dart';
import '../core/utils/app_constants.dart';

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

  // Device lists for media selection
  final audioInputs = <webrtc.MediaDeviceInfo>[].obs;
  final videoInputs = <webrtc.MediaDeviceInfo>[].obs;
  final audioOutputs = <webrtc.MediaDeviceInfo>[].obs;

  // Selected devices
  final selectedAudioInput = Rx<webrtc.MediaDeviceInfo?>(null);
  final selectedVideoInput = Rx<webrtc.MediaDeviceInfo?>(null);
  final selectedAudioOutput = Rx<webrtc.MediaDeviceInfo?>(null);

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
          _storageService.read<String>(AppConstants.keyDeviceName) ?? '';

      // Register for SIP UA events
      _helper.addSipUaHelperListener(this);

      // Initialize device lists
      await loadDevices();

      // Load selected device IDs from storage and set selected devices
      await loadSelectedDevices();

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

  /// Load available media devices
  Future<void> loadDevices() async {
    try {
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

      debugPrint(
          'Device counts: Audio inputs: ${audioInputs.length}, Video inputs: ${videoInputs.length}, Audio outputs: ${audioOutputs.length}');
    } catch (e) {
      debugPrint('Error enumerating devices: $e');
    }
  }

  /// Load selected devices from storage
  Future<void> loadSelectedDevices() async {
    final savedAudioInputId =
        _storageService.read<String>(AppConstants.keySelectedAudioInput);
    final savedVideoInputId =
        _storageService.read<String>(AppConstants.keySelectedVideoInput);
    final savedAudioOutputId =
        _storageService.read<String>(AppConstants.keySelectedAudioOutput);

    if (savedAudioInputId != null && audioInputs.isNotEmpty) {
      selectedAudioInput.value = audioInputs.firstWhereOrNull(
              (device) => device.deviceId == savedAudioInputId) ??
          audioInputs.first;
    } else if (audioInputs.isNotEmpty) {
      selectedAudioInput.value = audioInputs.first;
    }

    if (savedVideoInputId != null && videoInputs.isNotEmpty) {
      selectedVideoInput.value = videoInputs.firstWhereOrNull(
              (device) => device.deviceId == savedVideoInputId) ??
          videoInputs.first;
    } else if (videoInputs.isNotEmpty) {
      selectedVideoInput.value = videoInputs.first;
    }

    if (savedAudioOutputId != null && audioOutputs.isNotEmpty) {
      selectedAudioOutput.value = audioOutputs.firstWhereOrNull(
              (device) => device.deviceId == savedAudioOutputId) ??
          audioOutputs.first;
    } else if (audioOutputs.isNotEmpty) {
      selectedAudioOutput.value = audioOutputs.first;
    }
  }

  /// Set audio input device
  Future<void> setAudioInput(webrtc.MediaDeviceInfo device) async {
    selectedAudioInput.value = device;

    // Save to storage
    _storageService.write(AppConstants.keySelectedAudioInput, device.deviceId);

    // Apply to current call if exists - this requires advanced WebRTC handling
    if (currentCall.value != null) {
      try {
        debugPrint('Attempting to change microphone to: ${device.label}');
        // This would require accessing the RTCPeerConnection from currentCall and replacing tracks

        // In a real implementation, you would access the RTCPeerConnection
        // and replace the audio track with a new one from the selected device
        // This is complex and would require direct WebRTC manipulation

        // Note: If the call object doesn't expose this functionality directly,
        // you'd need to implement a workaround or live with changing devices
        // only for new calls.
      } catch (e) {
        debugPrint('Error changing microphone: $e');
      }
    }
  }

  /// Set video input device
  Future<void> setVideoInput(webrtc.MediaDeviceInfo device) async {
    selectedVideoInput.value = device;

    // Save to storage
    _storageService.write(AppConstants.keySelectedVideoInput, device.deviceId);

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
    selectedAudioOutput.value = device;

    // Save to storage
    _storageService.write(AppConstants.keySelectedAudioOutput, device.deviceId);

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
    } else if (state.state == CallStateEnum.ENDED) {
      currentCall.value = null;
      // Reset state when call ends
      isCallMuted.value = false;
      isLocalVideoEnabled.value = true;
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
      };

      // Add device constraints if selected
      if (selectedAudioInput.value != null) {
        mediaConstraints['audio'] = {
          'deviceId': {'exact': selectedAudioInput.value!.deviceId},
        };
      }

      if (video && selectedVideoInput.value != null) {
        mediaConstraints['video'] = {
          'deviceId': {'exact': selectedVideoInput.value!.deviceId},
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
