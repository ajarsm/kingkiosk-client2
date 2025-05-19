import 'package:flutter/services.dart';
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
    // Initialize the sound players in advance
    await _initializePlayer(wrongPin, 'assets/sounds/wrong.wav');
    await _initializePlayer(success, 'assets/sounds/success.wav');
    await _initializePlayer(notification, 'assets/sounds/notification.wav');

    // Add any other sounds from the assets folder as needed
    try {
      // Add custom initialization logic for additional sounds here if needed
      print('Audio service initialized successfully');
    } catch (e) {
      print('Warning: Error initializing additional audio files: $e');
    }

    _isInitialized.value = true;
    return this;
  }

  /// Initialize a player with a specific sound
  Future<void> _initializePlayer(String key, String assetPath) async {
    try {
      final player = AudioPlayer();
      // Try to load from cached file first
      final cachedFile = await _getCachedFile(key);

      if (cachedFile != null && await cachedFile.exists()) {
        // Use cached file
        await player.setFilePath(cachedFile.path);
      } else {
        // Load from assets and cache
        await player.setAsset(assetPath);
        // Cache the file for future use
        await _cacheAssetFile(key, assetPath);
      }

      _players[key] = player;
    } catch (e) {
      print('Error initializing audio player: $e');
    }
  }

  /// Get the cached file path
  Future<File?> _getCachedFile(String key) async {
    try {
      final dir = await getTemporaryDirectory();
      return File('${dir.path}/audio_cache_$key.mp3');
    } catch (e) {
      print('Error getting cached file: $e');
      return null;
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

  /// Cache an asset file for future use
  Future<void> _cacheAssetFile(String key, String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      final cachedFile = await _getCachedFile(key);
      if (cachedFile != null) {
        await cachedFile.writeAsBytes(bytes);
      }
    } catch (e) {
      print('Error caching asset file: $e');
    }
  }

  /// Play a sound by key
  Future<void> playSound(String key) async {
    if (!_isInitialized.value) {
      print('Audio service not initialized');
      return;
    }

    try {
      final player = _players[key];
      if (player != null) {
        await player.stop();
        await player.seek(Duration.zero);
        await player.play();
      } else {
        print('Sound "$key" not found');
      }
    } catch (e) {
      print('Error playing sound: $e');
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
