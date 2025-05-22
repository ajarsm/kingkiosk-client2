import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Handles audio playback with caching using just_audio
class AudioService extends GetxService {
  final Map<String, AudioPlayer> _players = {};
  final Map<String, LockCachingAudioSource> _remoteSourceCache = {};
  final Map<String, AudioPlayer> _remotePlayerCache = {};
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
      final player = AudioPlayer();

      // Use the helper method to safely set the audio asset
      final success = await _safelySetAudioAsset(player, assetPath);
      if (!success) {
        throw Exception('Failed to set audio asset for $key');
      }

      _players[key] = player;
      print('🔊 Successfully initialized player for $key');
    } catch (e) {
      print('⚠️ Error initializing audio player for key "$key": $e');
      print('⚠️ Stack trace: ${StackTrace.current}');
    }
  }

  /// Helper method to safely set an audio asset with fallback mechanisms
  Future<bool> _safelySetAudioAsset(
      AudioPlayer player, String assetPath) async {
    print('🔊 Attempting to safely set audio asset: $assetPath');

    try {
      // Standard approach - should work in most cases
      print('🔊 Try standard setAsset approach');
      await player.setAsset(assetPath);
      print('✅ Standard setAsset succeeded');
      return true;
    } catch (e1) {
      print('⚠️ Standard setAsset approach failed: $e1');

      try {
        // Try with 'asset:' prefix
        final assetUrl = 'asset:$assetPath';
        print('🔊 Try with asset: scheme: $assetUrl');
        await player.setUrl(assetUrl);
        print('✅ asset: scheme succeeded');
        return true;
      } catch (e2) {
        print('⚠️ asset: scheme approach failed: $e2');

        try {
          // Try direct URL with bundled asset approach
          final bundledAssetUrl = 'asset:///$assetPath';
          print('🔊 Try bundled asset URL: $bundledAssetUrl');
          await player.setUrl(bundledAssetUrl);
          print('✅ bundledAsset URL succeeded');
          return true;
        } catch (e3) {
          print('⚠️ All asset loading approaches failed for $assetPath');
          print('⚠️ Errors: $e1, $e2, $e3');
          return false;
        }
      }
    }
  }

  // The _getCachedFile method has been removed as it's no longer used with the new asset loading approach

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
        final player = AudioPlayer();

        // Create an instance of the service to access non-static methods
        final tempService = AudioService();
        final success = await tempService._safelySetAudioAsset(
            player, 'assets/sounds/notification.wav');

        if (success) {
          print('🔊 Static direct player asset set successfully');
          await player.play();
          print('🔊 Static direct player successfully played notification');
        } else {
          print(
              '⚠️ Static direct player failed to set asset after all attempts');
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

  // The _cacheAssetFile method has been removed as it's no longer used with the new asset loading approach

  /// Play a sound by key
  Future<void> playSound(String key) async {
    if (!_isInitialized.value) {
      print('Audio service not initialized, initializing now...');
      await init();
    }

    try {
      // Check if we have the key in our player map
      print('🔊 Attempting to play sound: $key');
      print('🔊 Available sound keys: ${_players.keys.join(', ')}');

      AudioPlayer? player = _players[key];
      if (player == null) {
        // Try to reinitialize the player if it's missing
        print('Sound "$key" not found, attempting to reinitialize...');
        switch (key) {
          case notification:
            await _initializePlayer(
                notification, 'assets/sounds/notification.wav');
            break;
          case wrongPin:
            await _initializePlayer(wrongPin, 'assets/sounds/wrong.wav');
            break;
          case success:
            await _initializePlayer(success, 'assets/sounds/correct.wav');
            break;
        }
        player = _players[key];
      }

      if (player != null) {
        print('🔊 Found player for sound "$key", playing...');
        await player.stop();
        await player.seek(Duration.zero);
        await player.play();
        print('🔊 Sound "$key" playback started');
      } else {
        print('⚠️ Sound "$key" still not found after reinitialization attempt');

        // Last resort: create a one-time player
        print('🔊 Creating one-time player for "$key"');
        final tempPlayer = AudioPlayer();

        // Get the asset path based on the sound key
        final assetPath =
            'assets/sounds/${key == notification ? 'notification.wav' : key == wrongPin ? 'wrong.wav' : 'correct.wav'}';

        // Use our helper method that tries multiple approaches
        final success = await _safelySetAudioAsset(tempPlayer, assetPath);

        if (success) {
          print('🔊 One-time player asset set for "$key"');
          await tempPlayer.play();
          print('🔊 One-time player started playing "$key"');
        } else {
          print('⚠️ All attempts to play one-time sound "$key" have failed');
        }
        // Clean up after playing
        tempPlayer.processingStateStream.listen((state) {
          if (state == ProcessingState.completed) {
            tempPlayer.dispose();
          }
        });
      }
    } catch (e) {
      print('⚠️ Error playing sound: $e');
      print('⚠️ Stack trace: ${StackTrace.current}');
    }
  }

  /// Play wrong PIN beep sound
  Future<void> playWrongPinSound() async {
    await playSound(wrongPin);
  }

  /// Play success sound
  Future<void> playSuccessSound() async {
    await playSound(success);
  }

  /// Play notification sound
  Future<void> playNotificationSound() async {
    await playSound(notification);
  }

  /// Play remote audio URL with caching support
  Future<void> playRemoteAudio(String url, {bool loop = false}) async {
    try {
      print('🔊 Playing remote audio: $url');

      // Stop any currently playing remote audio
      await stopRemoteAudio();

      // Generate a cache key from the URL
      final cacheKey = _generateKeyFromUrl(url);

      // Try to get an existing player from cache
      AudioPlayer? player = _remotePlayerCache[cacheKey];

      // If no existing player, create one
      if (player == null) {
        player = AudioPlayer();
        _remotePlayerCache[cacheKey] = player;

        // Create or get audio source with caching
        LockCachingAudioSource? source = _remoteSourceCache[cacheKey];
        if (source == null) {
          source = LockCachingAudioSource(Uri.parse(url));
          _remoteSourceCache[cacheKey] = source;
        }

        // Set the source to the player
        await player.setAudioSource(source);
      } else {
        // Reset existing player
        await player.seek(Duration.zero);
      }

      // Configure loop mode
      await player.setLoopMode(loop ? LoopMode.one : LoopMode.off);

      // Play and update status
      await player.play();
      isRemotePlaying.value = true;
      currentRemoteAudio.value = url;

      // Listen for completion to update status
      player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed && !loop) {
          isRemotePlaying.value = false;
          currentRemoteAudio.value = null;
        }
      });
    } catch (e) {
      print('❌ Error playing remote audio: $e');
      isRemotePlaying.value = false;
      currentRemoteAudio.value = null;
    }
  }

  /// Stop current remote audio playback
  Future<void> stopRemoteAudio() async {
    if (currentRemoteAudio.value != null) {
      try {
        final cacheKey = _generateKeyFromUrl(currentRemoteAudio.value!);
        final player = _remotePlayerCache[cacheKey];
        if (player != null) {
          await player.pause();
          await player.seek(Duration.zero);
        }
      } catch (e) {
        print('Error stopping remote audio: $e');
      }

      isRemotePlaying.value = false;
      currentRemoteAudio.value = null;
    }
  }

  /// Clear all cached audio files
  Future<void> clearCache() async {
    try {
      // Stop any playing audio
      await stopRemoteAudio();

      // Clear asset cache
      await AudioPlayer.clearAssetCache();

      // Also clear our manually cached files
      final dir = await getTemporaryDirectory();
      final cacheFiles = dir.listSync().where(
          (entity) => entity is File && entity.path.contains('audio_cache_'));

      for (var file in cacheFiles) {
        await (file as File).delete();
      }

      // Clear memory caches
      for (var player in _remotePlayerCache.values) {
        await player.dispose();
      }
      _remotePlayerCache.clear();
      _remoteSourceCache.clear();

      print('Audio cache cleared');
    } catch (e) {
      print('Error clearing audio cache: $e');
    }
  }

  @override
  void onClose() {
    // Dispose all players
    for (var player in _players.values) {
      player.dispose();
    }
    _players.clear();

    // Dispose all remote players
    for (var player in _remotePlayerCache.values) {
      player.dispose();
    }
    _remotePlayerCache.clear();
    _remoteSourceCache.clear();

    super.onClose();
  }
}
