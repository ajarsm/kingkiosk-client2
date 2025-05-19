import 'package:get/get.dart';

// Empty class to maintain API compatibility during cleanup
class MediasoupController extends GetxController {
  // Core components - empty values
  final device = Rx<dynamic>(null);
  final sendTransport = Rx<dynamic>(null);
  final recvTransport = Rx<dynamic>(null);

  // Media state tracking
  final producers = <dynamic>[].obs;
  final consumers = <dynamic>[].obs;
  final localStream = Rx<dynamic>(null);
  final videoProducer = Rx<dynamic>(null);
  final audioProducer = Rx<dynamic>(null);

  // Data channel components
  final dataProducer = Rx<dynamic>(null);
  final dataConsumers = <dynamic>[].obs;
  final dataMessages = <dynamic>[].obs;

  // Call state
  final callState = 'disconnected'.obs;
  final isVideoCall = false.obs;
  final isMuted = false.obs;
  final isCameraOn = true.obs;
  final isScreenSharing = false.obs;

  // Device selection tracking
  final audioInputDevices = <dynamic>[].obs;
  final videoInputDevices = <dynamic>[].obs;
  final audioOutputDevices = <dynamic>[].obs;

  // Selected devices
  final selectedAudioInput = Rx<dynamic>(null);
  final selectedVideoInput = Rx<dynamic>(null);
  final selectedAudioOutput = Rx<dynamic>(null);

  // Remote streams
  final remoteStreams = <dynamic>[].obs;
  final callDuration = 0.obs;
  final networkStats = <String, dynamic>{}.obs;
  final lastError = ''.obs;

  // Placeholder method implementations to maintain API compatibility
  void enumerateDevices() {}

  Future<void> switchAudioInput(dynamic device) async {}

  Future<void> switchVideoInput(dynamic device) async {}

  Future<void> setAudioOutput(dynamic device) async {}

  void toggleMute() {}

  void toggleCamera() {}

  void endCall() {}
}
