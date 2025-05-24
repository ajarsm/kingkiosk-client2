import 'dart:io';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:get_storage/get_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service to detect and manage hardware acceleration compatibility issues
class MediaHardwareDetectionService extends GetxService {
  // Singleton pattern
  static final MediaHardwareDetectionService _instance =
      MediaHardwareDetectionService._internal();

  factory MediaHardwareDetectionService() => _instance;

  MediaHardwareDetectionService._internal();

  // Observable values
  final isHardwareAccelerationEnabled = true.obs;
  final hasDetectedIssue = false.obs;
  final lastError = Rx<String?>(null);
  final deviceInfo = Rx<Map<String, dynamic>>({});

  // Known problematic processors and devices
  final problemDevices = <String>[
    'allwinner', // AllWinner SoCs (common in cheap tablets)
    'sunxi', // Another name for AllWinner
    'sun8i', // AllWinner H series
    'sun50i', // AllWinner A series
    'a64', // AllWinner A64
    'h616', // AllWinner H616
    'rockchip', // Some RockChip processors also have issues
    'amlogic', // Some Amlogic SoCs have issues with hardware acceleration
    's905', // Amlogic S905
  ];

  // Cache to avoid repeated detections
  final _storage = GetStorage();
  static const String _storageKey = 'mediakit_hardware_acceleration';

  /// Initialize the service
  Future<MediaHardwareDetectionService> init() async {
    // Load saved settings
    final savedValue = _storage.read<bool>(_storageKey);
    if (savedValue != null) {
      isHardwareAccelerationEnabled.value = savedValue;
      print(
          '🎬 Loaded hardware acceleration setting: ${savedValue ? 'enabled' : 'disabled'}');
    }

    // Get device info for detection
    await _detectDeviceInfo();

    // If device is in the problem list, disable hardware acceleration by default
    if (_isProblematicDevice() && savedValue == null) {
      isHardwareAccelerationEnabled.value = false;
      await saveSettings();
      print(
          '🎬 Problematic device detected, hardware acceleration disabled by default');
    }

    return this;
  }

  /// Detect device information to identify potential problem devices
  Future<void> _detectDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final Map<String, dynamic> info = {};

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        info['model'] = androidInfo.model;
        info['manufacturer'] = androidInfo.manufacturer;
        info['androidVersion'] = androidInfo.version.release;
        info['sdkInt'] = androidInfo.version.sdkInt;
        info['board'] = androidInfo.board;
        info['hardware'] = androidInfo.hardware;
        info['device'] = androidInfo.device;
        info['product'] = androidInfo.product;
        info['isPhysicalDevice'] = androidInfo.isPhysicalDevice;
        info['supported32BitAbis'] = androidInfo.supported32BitAbis;
        info['supported64BitAbis'] = androidInfo.supported64BitAbis;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        info['model'] = iosInfo.model;
        info['systemName'] = iosInfo.systemName;
        info['systemVersion'] = iosInfo.systemVersion;
        info['isPhysicalDevice'] = iosInfo.isPhysicalDevice;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        info['name'] = linuxInfo.name;
        info['version'] = linuxInfo.version;
        info['id'] = linuxInfo.id;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        info['computerName'] = windowsInfo.computerName;
        info['majorVersion'] = windowsInfo.majorVersion;
        info['minorVersion'] = windowsInfo.minorVersion;
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfoPlugin.macOsInfo;
        info['model'] = macOsInfo.model;
        info['kernelVersion'] = macOsInfo.kernelVersion;
        info['osRelease'] = macOsInfo.osRelease;
      }

      deviceInfo.value = info;
      print('🎬 Detected device info: $info');
    } catch (e) {
      print('⚠️ Error detecting device info: $e');
    }
  }

  /// Check if the current device is in the problematic device list
  bool _isProblematicDevice() {
    if (!Platform.isAndroid) return false;

    final info = deviceInfo.value;
    final deviceDetails = [
      info['model'] ?? '',
      info['manufacturer'] ?? '',
      info['hardware'] ?? '',
      info['board'] ?? '',
      info['device'] ?? '',
      info['product'] ?? '',
    ].map((s) => s.toString().toLowerCase()).toList();

    // Check if any device detail contains problematic processor names
    for (final detail in deviceDetails) {
      for (final problem in problemDevices) {
        if (detail.contains(problem)) {
          print('🎬 Detected problematic device: $detail');
          return true;
        }
      }
    }

    return false;
  }

  /// Save the current hardware acceleration setting
  Future<void> saveSettings() async {
    await _storage.write(_storageKey, isHardwareAccelerationEnabled.value);
    print(
        '🎬 Saved hardware acceleration setting: ${isHardwareAccelerationEnabled.value ? 'enabled' : 'disabled'}');
  }

  /// Toggle hardware acceleration and save setting
  Future<void> toggleHardwareAcceleration(bool enabled) async {
    isHardwareAccelerationEnabled.value = enabled;
    await saveSettings();

    // Reset error flag on manual change
    hasDetectedIssue.value = false;
    lastError.value = null;
  }

  /// Track media errors for potential hardware acceleration issues
  void trackMediaError(String error) {
    lastError.value = error;
    print('🎬 Tracking media error: $error');

    // Check if error seems related to hardware acceleration
    final errorLower = error.toLowerCase();
    final List<String> hardwareAccelErrors = [
      'hw decoder init failed',
      'hardware acceleration',
      'hardware decoder',
      'gpu',
      'opengl',
      'vdpau',
      'vaapi',
      'decoder error',
      'mediacodec',
      'h264_mediacodec',
      'codec error',
      'decode error',
      'black screen',
      'avcodec',
      'acceleration context',
      'failed to initialize decoder',
      'failed to init decoder',
      'decoder initialization failed',
      'could not open codec',
      'h264', // Common codec with hardware acceleration issues
      'hevc', // H.265 codec
      'encoder not found',
      'decoder not found',
      'vdec',
      'video decoder',
      'video decoding',
      'frame dropped',
      'cannot play media',
      'media parsing failed',
      'media could not be played',
      'media playback error',
      'video renderer',
      'video rendering',
      'renderer failed',
      'surface error',
      'drm', // Direct Rendering Manager
      'gles', // OpenGL ES
      'egl', // EGL interface
      'initialization failed',
      'player initialization failed',
      'player failed',
      'ffmpeg', // FFmpeg errors can indicate codec/hardware issues
    ];

    bool isHardwareError = false;
    for (final keyword in hardwareAccelErrors) {
      if (errorLower.contains(keyword)) {
        isHardwareError = true;
        print('🎬 Detected hardware-related keyword in error: $keyword');
        break;
      }
    }

    // If device is known to be problematic, lower the threshold for detecting hardware issues
    if (!isHardwareError && _isProblematicDevice()) {
      // For problematic devices, consider any playback failure as potential hardware issue
      final List<String> generalPlaybackErrors = [
        'error',
        'failed',
        'failure',
        'exception',
        'cannot play',
        'unable to play',
        'playback',
        'cannot load',
      ];

      for (final keyword in generalPlaybackErrors) {
        if (errorLower.contains(keyword)) {
          print('🎬 Problematic device with general playback error: $keyword');
          isHardwareError = true;
          break;
        }
      }
    }

    if (isHardwareError && isHardwareAccelerationEnabled.value) {
      print('⚠️ Detected potential hardware acceleration issue, disabling it');
      hasDetectedIssue.value = true;
      isHardwareAccelerationEnabled.value = false;
      saveSettings();
    }
  }

  /// Get MediaKit player options based on current hardware acceleration setting
  PlayerConfiguration getPlayerConfiguration() {
    final Map<String, String> options = {};

    if (isHardwareAccelerationEnabled.value) {
      // Hardware acceleration enabled options
      options['hwdec'] = 'auto'; // Use hardware decoding if available
      options['vd'] = 'mediacodec'; // Android MediaCodec
      options['hwdec-codecs'] =
          'h264,hevc,vp8,vp9'; // Common codecs for hardware acceleration
    } else {
      // Software decoding fallback options
      options['hwdec'] = 'no'; // Disable hardware decoding
      options['vd'] = ''; // Don't specify video decoder
      options['software-decoding'] = 'yes'; // Ensure software decoding
      options['skip_loop_filter'] =
          'all'; // Speed up decoding at cost of quality
      options['skip_idct'] = 'all'; // Skip IDCT step when possible
      options['fast'] = 'yes'; // Enable fast decoding mode
      options['framedrop'] =
          'vo'; // Allow frame dropping to maintain performance
      options['threads'] = 'auto'; // Use multiple threads for decoding

      // Additional optimizations for software decoding
      options['vf'] =
          'scale=w=960:h=540:force_original_aspect_ratio=decrease'; // Reduce resolution if needed
    }

    // Add more detail about problematic device
    if (_isProblematicDevice()) {
      options['problem-device'] = 'yes'; // Just for logging/debugging

      // Get specific hardware info for better tuning
      final info = deviceInfo.value;
      if (info.containsKey('hardware')) {
        options['device-hardware'] = info['hardware'].toString();
      }
      if (info.containsKey('model')) {
        options['device-model'] = info['model'].toString();
      }
    }

    final configuration = PlayerConfiguration(
      // Basic configuration
      bufferSize: 64 * 1024 * 1024, // 64MB buffer
      protocolWhitelist: const [
        'udp',
        'rtp',
        'tcp',
        'tls',
        'data',
        'file',
        'http',
        'https',
        'crypto',
      ],
    );

    print(
        '🎬 Player configuration: hardware acceleration ${isHardwareAccelerationEnabled.value ? 'enabled' : 'disabled'}');
    if (_isProblematicDevice()) {
      print('🎬 Configured for known problematic device');
    }
    return configuration;
  }
}
