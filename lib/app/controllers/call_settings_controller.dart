// lib/controllers/call_settings_controller.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CallSettingsController extends GetxController {
  // Video quality settings
  final RxString videoResolution = '720p'.obs;
  final RxInt frameRate = 30.obs;
  final RxBool autoAdjustQuality = true.obs;

  // Audio settings
  final RxBool echoCancellation = true.obs;
  final RxBool noiseSuppression = true.obs;
  final RxBool autoGainControl = true.obs;

  // Network settings
  final RxBool forceTcp = false.obs;
  final RxInt maxBitrate = 1500.obs; // kbps

  // Mediasoup server settings
  final RxString mediasoupServerIp = ''.obs;
  final RxInt mediasoupServerPort = 0.obs;
  final RxBool autoConnectAudio = false.obs;
  final RxBool autoConnectVideo = false.obs;

  // Persisted device selections
  final RxString selectedAudioInputId = ''.obs;
  final RxString selectedVideoInputId = ''.obs;
  final RxString selectedAudioOutputId = ''.obs;

  // Get video constraints based on current settings
  Map<String, dynamic> getVideoConstraints() {
    Map<String, dynamic> mandatory = {};

    // Set resolution
    switch (videoResolution.value) {
      case '1080p':
        mandatory['minWidth'] = '1920';
        mandatory['minHeight'] = '1080';
        break;
      case '720p':
        mandatory['minWidth'] = '1280';
        mandatory['minHeight'] = '720';
        break;
      case '480p':
        mandatory['minWidth'] = '854';
        mandatory['minHeight'] = '480';
        break;
      case '360p':
        mandatory['minWidth'] = '640';
        mandatory['minHeight'] = '360';
        break;
    }

    // Set frame rate
    mandatory['minFrameRate'] = frameRate.value.toString();

    return {
      'mandatory': mandatory,
      'optional': [
        {'facingMode': 'user'},
      ]
    };
  }

  // Get audio constraints based on current settings
  Map<String, dynamic> getAudioConstraints() {
    return {
      'echoCancellation': echoCancellation.value,
      'noiseSuppression': noiseSuppression.value,
      'autoGainControl': autoGainControl.value,
    };
  }

  // Get full media constraints
  Map<String, dynamic> getMediaConstraints({bool videoEnabled = true}) {
    return {
      'audio': getAudioConstraints(),
      'video': videoEnabled ? getVideoConstraints() : false,
    };
  }

  // Save settings to persistent storage
  void saveSettings() {
    Get.find<GetStorage>().write('videoSettings', {
      'resolution': videoResolution.value,
      'frameRate': frameRate.value,
      'autoAdjust': autoAdjustQuality.value,
      'echoCancellation': echoCancellation.value,
      'noiseSuppression': noiseSuppression.value,
      'autoGainControl': autoGainControl.value,
      'forceTcp': forceTcp.value,
      'maxBitrate': maxBitrate.value,
      // Mediasoup fields
      'mediasoupServerIp': mediasoupServerIp.value,
      'mediasoupServerPort': mediasoupServerPort.value,
      'autoConnectAudio': autoConnectAudio.value,
      'autoConnectVideo': autoConnectVideo.value,
      // Device selections
      'selectedAudioInputId': selectedAudioInputId.value,
      'selectedVideoInputId': selectedVideoInputId.value,
      'selectedAudioOutputId': selectedAudioOutputId.value,
    });
  }

  // Load settings from persistent storage
  void loadSettings() {
    final settings = Get.find<GetStorage>().read('videoSettings');
    if (settings != null) {
      videoResolution.value = settings['resolution'] ?? '720p';
      frameRate.value = settings['frameRate'] ?? 30;
      autoAdjustQuality.value = settings['autoAdjust'] ?? true;
      echoCancellation.value = settings['echoCancellation'] ?? true;
      noiseSuppression.value = settings['noiseSuppression'] ?? true;
      autoGainControl.value = settings['autoGainControl'] ?? true;
      forceTcp.value = settings['forceTcp'] ?? false;
      maxBitrate.value = settings['maxBitrate'] ?? 1500;
      // Mediasoup fields
      mediasoupServerIp.value = settings['mediasoupServerIp'] ?? '';
      mediasoupServerPort.value = settings['mediasoupServerPort'] ?? 0;
      autoConnectAudio.value = settings['autoConnectAudio'] ?? false;
      autoConnectVideo.value = settings['autoConnectVideo'] ?? false;
      // Device selections
      selectedAudioInputId.value = settings['selectedAudioInputId'] ?? '';
      selectedVideoInputId.value = settings['selectedVideoInputId'] ?? '';
      selectedAudioOutputId.value = settings['selectedAudioOutputId'] ?? '';
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }
}
