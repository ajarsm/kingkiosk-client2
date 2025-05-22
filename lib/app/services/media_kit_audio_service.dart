import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Handles audio playback with caching using media_kit
class AudioService extends GetxService {
  final Map<String, Player> _players = {};
  final Map<String, String> _cachedFilePaths = {};
  final Map<String, Player> _remotePlayerCache = {};
  final RxBool _isInitialized = false.obs;

  // Track currently playing remote audio
  final Rx<String?> currentRemoteAudio = Rx<String?>(null);
  final RxBool isRemotePlaying = false.obs;

  // Pre-defined sound keys
  static const String wrongPin = 'wrong_pin';
  static const String success = 'success';
  static const String notification = 'notification';

  Future<AudioService> init() async {
    print('🔊 AudioService init() called');
    // Initialize the sound players in advance
    try {
      print('🔊 Initializing wrong pin sound...');
      await _initializePlayer(wrongPin, 'assets/sounds/wrong.wav');

      print('🔊 Initializing success sound...');
      await _initializePlayer(success, 'assets/sounds/correct.wav');

      print('🔊 Initializing notification sound...');
      await _initializePlayer(notification, 'assets/sounds/notification.wav');

      // Verify players were created
      print('🔊 Initialized players: ${_players.keys.join(', ')}');

      // Add any other sounds from the assets folder as needed
      print('🔊 Audio service initialized successfully');
    } catch (e) {
      print('⚠️ Warning: Error initializing audio files: $e');
    }

    _isInitialized.value = true;
    return this;
  }

  /// Initialize a player with a specific sound
  Future<void> _initializePlayer(String key, String assetPath) async {
    try {
      print('🔊 Initializing player for sound key: $key, path: $assetPath');
      final player = Player();
      await player.open(Media('asset:///$assetPath'), play: false);

      _players[key] = player;
      print('🔊 Successfully initialized player for $key');
    } catch (e) {
      print('⚠️ Error initializing audio player for key "$key": $e');
      print('⚠️ Stack trace: ${StackTrace.current}');
    }
  }

  /// Generate a key from URL for caching purposes
  String _generateKeyFromUrl(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // Use first 16 chars of the hash
  }

  /// Static utility method to play wrong PIN sound from anywhere
  static Future<void> playError() async {
    try {
      if (Get.isRegistered<AudioService>()) {
        final audioService = Get.find<AudioService>();
        await audioService.playWrongPinSound();
      }
    } catch (e) {
      print('Error playing error sound: $e');
    }
  }

  /// Static utility method to play success sound from anywhere
  static Future<void> playSuccess() async {
    try {
      if (Get.isRegistered<AudioService>()) {
        final audioService = Get.find<AudioService>();
        await audioService.playSuccessSound();
      }
    } catch (e) {
      print('Error playing success sound: $e');
    }
  }

  /// Static utility method to play notification sound from anywhere
  static Future<void> playNotification() async {
    try {
      print('🔊 Static playNotification() called');
      if (Get.isRegistered<AudioService>()) {
        print('🔊 AudioService is registered, using instance');
        final audioService = Get.find<AudioService>();
        await audioService.playNotificationSound();
      } else {
        // If service isn't registered yet, create a temporary instance
        print('🔊 AudioService not registered, creating temporary instance');
        final tempService = AudioService();
        await tempService.init();
        await tempService.playNotificationSound();
      }
    } catch (e) {
      print('⚠️ Error playing notification sound: $e');

      // Last resort: create a direct player
      try {
        print('🔊 Creating static direct player as last resort');
        final player = Player();

        try {
          print('🔊 Static direct player attempting to play notification');
          await player.open(Media('asset:///assets/sounds/notification.wav'));
          await player.play();
          print('🔊 Static direct player successfully played notification');
        } catch (e2) {
          print('⚠️ Static direct player failed: $e2');
        }

        // Dispose after playing to avoid memory leaks
        Future.delayed(Duration(seconds: 2), () {
          player.dispose();
        });
      } catch (e2) {
        print('⚠️ Final attempt to play notification sound failed: $e2');
      }
    }
  }

  /// Play a sound by key
  Future<void> playSound(String key) async {
    if (!_isInitialized.value) {
      print('Audio service not initialized, initializing now...');
      await init();
    }

    try {
      // Check if we have the key in our player map
      Player? player = _players[key];
      if (player == null) {
        // If not found, try to initialize it based on predefined keys
        String assetPath =
            'assets/sounds/${key == notification ? 'notification.wav' : key == wrongPin ? 'wrong.wav' : 'correct.wav'}';

        print('Player not found for key "$key", initializing with $assetPath');
        await _initializePlayer(key, assetPath);
        player = _players[key];

        if (player == null) {
          throw Exception('Failed to initialize player for key "$key"');
        }
      }

      // Reset to start and play
      await player.seek(Duration.zero);
      await player.play();

      print('🔊 Sound "$key" played successfully');
    } catch (e) {
      print('⚠️ Error playing sound "$key": $e');
    }
  }

  /// Wrapper for notification sound
  Future<void> playNotificationSound() async {
    print('🔔 Playing notification sound');
    return playSound(notification);
  }

  /// Wrapper for wrong PIN sound
  Future<void> playWrongPinSound() async {
    return playSound(wrongPin);
  }

  /// Wrapper for success sound
  Future<void> playSuccessSound() async {
    return playSound(success);
  }

  /// Play audio from a remote URL (like MQTT streaming)
  Future<void> playRemoteAudio(String url, {bool stopPrevious = true}) async {
    try {
      if (stopPrevious) {
        await stopRemoteAudio();
      }

      final cacheKey = _generateKeyFromUrl(url);
      print('Playing remote audio from URL: $url (Key: $cacheKey)');

      // Check if we have a cached player
      Player? player = _remotePlayerCache[cacheKey];
      if (player == null) {
        player = Player();
        _remotePlayerCache[cacheKey] = player;
      }

      // Try to get cached file path if we have it
      String? filePath = _cachedFilePaths[cacheKey];
      if (filePath != null && File(filePath).existsSync()) {
        print('Using cached file: $filePath');
        await player.open(Media(filePath));
      } else {
        // Use direct URL if no cache
        print('No cache found, streaming directly from URL');
        await player.open(Media(url));

        // Start caching for future use in the background
        _cacheRemoteFile(url, cacheKey);
      }

      await player.play();

      // Update state
      currentRemoteAudio.value = url;
      isRemotePlaying.value = true;

      print('Remote audio playback started successfully');
    } catch (e) {
      print('⚠️ Error playing remote audio: $e');
    }
  }

  /// Cache a remote audio file locally
  Future<void> _cacheRemoteFile(String url, String cacheKey) async {
    try {
      final dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/audio_cache_$cacheKey.mp3');

      // Don't cache if we already have it
      if (file.existsSync()) {
        _cachedFilePaths[cacheKey] = file.path;
        return;
      }

      // Download and cache
      // This would be implemented based on your app's HTTP client
      // For now, we'll just register the URL as the cached path
      _cachedFilePaths[cacheKey] = url;
    } catch (e) {
      print('⚠️ Error caching remote file: $e');
    }
  }

  /// Stop any playing remote audio
  Future<void> stopRemoteAudio() async {
    try {
      // If we have a current remote audio, stop it
      if (currentRemoteAudio.value != null && isRemotePlaying.value) {
        final cacheKey = _generateKeyFromUrl(currentRemoteAudio.value!);
        final player = _remotePlayerCache[cacheKey];
        if (player != null) {
          await player.pause();
        }
      }

      // Update state
      currentRemoteAudio.value = null;
      isRemotePlaying.value = false;
    } catch (e) {
      print('⚠️ Error stopping remote audio: $e');
    }
  }

  /// Pause any playing remote audio
  Future<void> pauseRemoteAudio() async {
    try {
      if (currentRemoteAudio.value != null && isRemotePlaying.value) {
        final cacheKey = _generateKeyFromUrl(currentRemoteAudio.value!);
        final player = _remotePlayerCache[cacheKey];
        if (player != null) {
          await player.pause();
          isRemotePlaying.value = false;
        }
      }
    } catch (e) {
      print('⚠️ Error pausing remote audio: $e');
    }
  }

  /// Resume any paused remote audio
  Future<void> resumeRemoteAudio() async {
    try {
      if (currentRemoteAudio.value != null && !isRemotePlaying.value) {
        final cacheKey = _generateKeyFromUrl(currentRemoteAudio.value!);
        final player = _remotePlayerCache[cacheKey];
        if (player != null) {
          await player.play();
          isRemotePlaying.value = true;
        }
      }
    } catch (e) {
      print('⚠️ Error resuming remote audio: $e');
    }
  }

  /// Clean up resources
  @override
  void onClose() {
    // Dispose all players
    for (final player in _players.values) {
      player.dispose();
    }
    for (final player in _remotePlayerCache.values) {
      player.dispose();
    }
    super.onClose();
  }
}
