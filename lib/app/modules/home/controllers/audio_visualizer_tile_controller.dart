import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'dart:async';
import 'dart:math' as math;
import '../widgets/media_tile.dart'; // Import to reuse the PlayerManager

/// Controller for AudioVisualizerTile to replace StatefulWidget state management
class AudioVisualizerTileController extends GetxController
    with GetTickerProviderStateMixin, WidgetsBindingObserver {
  final String url;
  final String? title;

  // Reactive state variables
  final isInitialized = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final position = Duration.zero.obs;

  // Non-reactive variables (animation controllers don't need to be reactive)
  late final PlayerWithController _playerData;
  late AnimationController visualizerController;
  late AnimationController colorController;
  Timer? _animationTimer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;

  // Frequency data simulation
  final frequencyData = <double>[].obs;
  static const int _frequencyBars = 64;
  final math.Random _random = math.Random();

  // Color cycling for the visualizer
  final List<Color> _visualizerColors = [
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.indigo,
    Colors.teal,
  ];

  AudioVisualizerTileController({
    required this.url,
    this.title,
  });

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimationControllers();
    _initializeFrequencyData();
    initializePlayer();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _handleLifecycleChange(state);
  }

  void _initializeAnimationControllers() {
    visualizerController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );

    colorController = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  void _initializeFrequencyData() {
    frequencyData.value = List.generate(_frequencyBars, (index) => 0.0);
    _startVisualizerAnimation();
  }

  Future<void> initializePlayer() async {
    try {
      _playerData = MediaPlayerManager().getPlayerFor(url);

      if (_playerData.isInitialized) {
        // If already initialized, just update our state reactively
        isInitialized.value = true;
        _setupPlayerListeners();
        return;
      }

      // Set up position listener
      _positionSubscription = _playerData.player.streams.position.listen((pos) {
        position.value = pos;
      });

      // Set up playing state listener
      _playingSubscription =
          _playerData.player.streams.playing.listen((playing) {
        if (playing) {
          _startVisualizerAnimation();
        } else {
          _stopVisualizerAnimation();
        }
      });

      // Open media
      await _playerData.player.open(Media(url));

      // Set playlist mode to loop
      try {
        await _playerData.player.setPlaylistMode(PlaylistMode.loop);
      } catch (e) {
        print('Warning: Could not set playlist mode: $e');
      }

      // Mark as initialized
      _playerData.isInitialized = true;
      isInitialized.value = true; // Reactive update

      // Auto-play for audio visualizer
      await _playerData.player.play();
    } catch (error) {
      print('Error initializing audio player: $error');
      hasError.value = true;
      errorMessage.value = error.toString();
      isInitialized.value = false;
    }
  }

  void _setupPlayerListeners() {
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();

    _positionSubscription = _playerData.player.streams.position.listen((pos) {
      position.value = pos;
    });

    _playingSubscription = _playerData.player.streams.playing.listen((playing) {
      if (playing) {
        _startVisualizerAnimation();
      } else {
        _stopVisualizerAnimation();
      }
    });
  }

  void _startVisualizerAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _updateFrequencyData();
    });
  }

  void _stopVisualizerAnimation() {
    _animationTimer?.cancel();
    // Gradually fade out the bars
    for (int i = 0; i < frequencyData.length; i++) {
      frequencyData[i] = math.max(0.0, frequencyData[i] - 0.1);
    }
    frequencyData.refresh(); // Trigger UI update
  }

  void _updateFrequencyData() {
    // Simulate frequency data based on audio (since we don't have real FFT data)
    final newData = <double>[];

    for (int i = 0; i < _frequencyBars; i++) {
      // Create more realistic frequency distribution
      // Lower frequencies (bass) should be more prominent
      final bassWeight = i < _frequencyBars * 0.2 ? 1.5 : 1.0;
      final midWeight =
          i >= _frequencyBars * 0.2 && i < _frequencyBars * 0.6 ? 1.2 : 1.0;
      final trebleWeight = i >= _frequencyBars * 0.6 ? 0.8 : 1.0;

      final baseAmplitude =
          _random.nextDouble() * bassWeight * midWeight * trebleWeight;

      // Add some momentum to make animation smoother
      final currentValue = frequencyData.length > i ? frequencyData[i] : 0.0;
      final targetValue = math.min(1.0, baseAmplitude);
      final smoothedValue = currentValue + (targetValue - currentValue) * 0.3;

      newData.add(smoothedValue);
    }

    frequencyData.value = newData;
  }

  void _handleLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (isInitialized.value && !_playerData.player.state.playing) {
          _playerData.player.play();
        }
        break;
      case AppLifecycleState.paused:
        if (isInitialized.value) {
          _playerData.player.pause();
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Do nothing for these states
        break;
    }
  }

  void _cleanup() {
    _animationTimer?.cancel();
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    visualizerController.dispose();
    colorController.dispose();

    // Dispose player using PlayerManager
    MediaPlayerManager().disposePlayerFor(url);
  }

  // Public methods for controlling playback
  void play() {
    if (isInitialized.value) {
      _playerData.player.play();
    }
  }

  void pause() {
    if (isInitialized.value) {
      _playerData.player.pause();
    }
  }

  void stop() {
    if (isInitialized.value) {
      _playerData.player.stop();
    }
  }

  bool get isPlaying {
    return isInitialized.value ? _playerData.player.state.playing : false;
  }

  Color getCurrentVisualizerColor() {
    final progress = colorController.value;
    final colorIndex = (progress * _visualizerColors.length).floor();
    final nextColorIndex = (colorIndex + 1) % _visualizerColors.length;
    final colorProgress = (progress * _visualizerColors.length) - colorIndex;

    return Color.lerp(
          _visualizerColors[colorIndex],
          _visualizerColors[nextColorIndex],
          colorProgress,
        ) ??
        _visualizerColors[0];
  }
}
