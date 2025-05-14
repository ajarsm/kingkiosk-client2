import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';

/// A service for handling WebRTC communication via mediasoup
class MediasoupService extends GetxService {
  // Mediasoup device
  Device? device;
  final RxBool isInitialized = false.obs;
  final RxBool isConnected = false.obs;
  final RxBool isAudioEnabled = true.obs;
  final RxBool isVideoEnabled = true.obs;
  
  // Media streams and renderers
  webrtc.MediaStream? localStream;
  final webrtc.RTCVideoRenderer localRenderer = webrtc.RTCVideoRenderer();
  final Map<String, webrtc.RTCVideoRenderer> remoteRenderers = {};
  
  // Room info
  String? currentRoomId;
  String? serverUrl;
  Map<String, dynamic>? serverInfo;

  MediasoupService init() {
    // Initialize renderer in a non-blocking way
    localRenderer.initialize();
    return this;
  }

  /// Initialize the mediasoup device with router capabilities
  Future<void> initializeDevice(Map<String, dynamic> routerRtpCapabilitiesMap) async {
    try {
      device = Device();
      
      // Convert the Map to RtpCapabilities
      final codecs = (routerRtpCapabilitiesMap['codecs'] as List<dynamic>)
          .map((c) => RtpCodecCapability(
                kind: c['kind'] == 'audio' ? RTCRtpMediaType.RTCRtpMediaTypeAudio : RTCRtpMediaType.RTCRtpMediaTypeVideo,
                mimeType: c['mimeType'],
                preferredPayloadType: c['preferredPayloadType'],
                clockRate: c['clockRate'],
                channels: c['channels'],
                parameters: c['parameters'] ?? {},
                rtcpFeedback: _parseRtcpFeedback(c['rtcpFeedback']),
              ))
          .toList();

      final headerExtensions = <RtpHeaderExtension>[];
      if (routerRtpCapabilitiesMap.containsKey('headerExtensions')) {
        for (var ext in routerRtpCapabilitiesMap['headerExtensions']) {
          headerExtensions.add(RtpHeaderExtension(
            kind: ext['kind'] == 'audio' ? RTCRtpMediaType.RTCRtpMediaTypeAudio : RTCRtpMediaType.RTCRtpMediaTypeVideo,
            uri: ext['uri'],
            preferredId: ext['preferredId'],
            preferredEncrypt: ext['preferredEncrypt'] ?? false,
            direction: ext['direction'] ?? 'sendrecv',
          ));
        }
      }
      
      final rtpCapabilities = RtpCapabilities(
        codecs: codecs,
        headerExtensions: headerExtensions,
      );
      
      await device?.load(routerRtpCapabilities: rtpCapabilities);
      isInitialized.value = true;
      print('Mediasoup device initialized');
    } catch (e) {
      print('Error initializing device: $e');
      isInitialized.value = false;
      rethrow;
    }
  }
  
  // Helper to parse RTCP feedback
  List<RtcpFeedback> _parseRtcpFeedback(List<dynamic>? feedbackList) {
    if (feedbackList == null) return [];
    
    return feedbackList.map((fb) => RtcpFeedback(
      type: fb['type'],
      parameter: fb['parameter'],
    )).toList();
  }

  /// Create a local media stream for camera/microphone
  Future<void> createLocalStream({bool audio = true, bool video = true}) async {
    try {
      isAudioEnabled.value = audio;
      isVideoEnabled.value = video;
      
      Map<String, dynamic> mediaConstraints = {
        'audio': audio,
        'video': video ? {
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '30',
          },
          'facingMode': 'user',
          'optional': [],
        } : false,
      };
      
      localStream = await webrtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = localStream;
    } catch (e) {
      print('Error getting user media: $e');
    }
  }

  /// Toggle audio on/off
  void toggleAudio() {
    if (localStream != null && localStream!.getAudioTracks().isNotEmpty) {
      final enabled = !isAudioEnabled.value;
      localStream!.getAudioTracks()[0].enabled = enabled;
      isAudioEnabled.value = enabled;
    }
  }

  /// Toggle video on/off
  void toggleVideo() {
    if (localStream != null && localStream!.getVideoTracks().isNotEmpty) {
      final enabled = !isVideoEnabled.value;
      localStream!.getVideoTracks()[0].enabled = enabled;
      isVideoEnabled.value = enabled;
    }
  }
  
  /// Join a mediasoup room
  Future<void> joinRoom({
    required String url,
    required String roomId,
    required Function onJoinSuccess,
    required Function(String) onJoinError,
  }) async {
    try {
      serverUrl = url;
      currentRoomId = roomId;
      
      // In a real application, you would connect to the mediasoup server here
      // For this example, we're simulating a connection
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network request
      
      // Mock router capabilities - in a real app, this would come from the server
      final routerRtpCapabilities = {
        'codecs': [
          {
            'kind': 'audio',
            'mimeType': 'audio/opus',
            'clockRate': 48000,
            'channels': 2,
            'rtcpFeedback': [],
            'parameters': {},
            'preferredPayloadType': 111
          },
          {
            'kind': 'video',
            'mimeType': 'video/VP8',
            'clockRate': 90000,
            'rtcpFeedback': [
              { 'type': 'nack' },
              { 'type': 'nack', 'parameter': 'pli' },
              { 'type': 'ccm', 'parameter': 'fir' },
              { 'type': 'goog-remb' }
            ],
            'parameters': {},
            'preferredPayloadType': 96
          }
        ],
        'headerExtensions': []
      };
      
      // Initialize the device
      await initializeDevice(routerRtpCapabilities);
      
      // Create a local stream if one doesn't exist
      if (localStream == null) {
        await createLocalStream();
      }
      
      isConnected.value = true;
      onJoinSuccess();
    } catch (e) {
      print('Error joining room: $e');
      isConnected.value = false;
      onJoinError(e.toString());
    }
  }

  /// Leave the current room
  void leaveRoom() {
    // Close local tracks
    if (localStream != null) {
      localStream!.getTracks().forEach((track) => track.stop());
    }
    
    // Clear renderers
    localRenderer.srcObject = null;
    remoteRenderers.forEach((_, renderer) => renderer.dispose());
    remoteRenderers.clear();
    
    // Reset state
    isConnected.value = false;
    currentRoomId = null;
  }

  /// Clean up resources when service is disposed
  @override
  void onClose() {
    leaveRoom();
    localRenderer.dispose();
    super.onClose();
  }
}