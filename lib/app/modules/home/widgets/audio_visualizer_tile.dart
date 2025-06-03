import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'media_tile.dart'; // Import to reuse the PlayerManager

class AudioVisualizerTile extends StatefulWidget {
  final String url;
  final String? title;

  const AudioVisualizerTile({
    Key? key,
    required this.url,
    this.title,
  }) : super(key: key);

  @override
  State<AudioVisualizerTile> createState() => _AudioVisualizerTileState();
}

class _AudioVisualizerTileState extends State<AudioVisualizerTile>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late final PlayerWithController _playerData;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  Duration _position = Duration.zero;
  
  // Visualizer animation properties
  late AnimationController _visualizerController;
  late AnimationController _colorController;
  Timer? _animationTimer;
  
  // Frequency data simulation
  List<double> _frequencyData = [];
  static const int _frequencyBars = 64;
  final math.Random _random = math.Random();
  
  // Color cycling for the visualizer
  List<Color> _visualizerColors = [
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize frequency data
    _frequencyData = List.generate(_frequencyBars, (index) => 0.0);
    
    // Initialize animation controllers
    _visualizerController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    
    _colorController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _playerData = MediaPlayerManager().getPlayerFor(widget.url);
    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitialized) {
      _playerData.player.seek(_position);
      _startVisualizerAnimation();
    } else if (state == AppLifecycleState.paused) {
      _position = _playerData.player.state.position;
      _stopVisualizerAnimation();
    }
  }

  Future<void> _initializePlayer() async {
    if (_playerData.isInitialized) {
      setState(() {
        _isInitialized = true;
      });
      _startVisualizerAnimation();
      return;
    }

    try {
      // Position listener
      _playerData.player.streams.position.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
      
      // Playing state listener to control visualizer
      _playerData.player.streams.playing.listen((isPlaying) {
        if (mounted) {
          if (isPlaying) {
            _startVisualizerAnimation();
          } else {
            _stopVisualizerAnimation();
          }
        }
      });

      await _playerData.player.open(Media(widget.url));
      _playerData.isInitialized = true;

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startVisualizerAnimation();
      }
    } catch (error) {
      print('Error initializing audio visualizer player: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = error.toString();
        });
      }
    }
  }

  void _startVisualizerAnimation() {
    if (_animationTimer != null) return;
    
    _animationTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (mounted && _playerData.player.state.playing) {
        _updateFrequencyData();
        _visualizerController.forward(from: 0);
      }
    });
  }

  void _stopVisualizerAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    
    // Gradually fade out the frequency data
    if (mounted) {
      setState(() {
        for (int i = 0; i < _frequencyData.length; i++) {
          _frequencyData[i] *= 0.8;
        }
      });
    }
  }

  void _updateFrequencyData() {
    if (!mounted) return;
    
    setState(() {
      for (int i = 0; i < _frequencyData.length; i++) {
        // Simulate audio frequency data with some realistic patterns
        double baseIntensity = 0.1 + _random.nextDouble() * 0.4;
        
        // Lower frequencies (bass) tend to be more prominent
        if (i < _frequencyBars * 0.2) {
          baseIntensity += _random.nextDouble() * 0.6;
        }
        // Mid frequencies have moderate activity
        else if (i < _frequencyBars * 0.6) {
          baseIntensity += _random.nextDouble() * 0.4;
        }
        // Higher frequencies are generally lower
        else {
          baseIntensity += _random.nextDouble() * 0.2;
        }
        
        // Add some smoothing to prevent jarring changes
        _frequencyData[i] = (_frequencyData[i] * 0.7) + (baseIntensity * 0.3);
        
        // Clamp values
        _frequencyData[i] = _frequencyData[i].clamp(0.0, 1.0);
      }
    });
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Card(
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        color: Colors.red.shade50.withOpacity(0.95),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  colors: [Colors.redAccent, Colors.orangeAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(rect),
                child: Icon(Icons.equalizer_outlined, color: Colors.white, size: 64),
              ),
              SizedBox(height: 22),
              Text('Failed to load audio visualizer',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.red.shade700)),
              SizedBox(height: 12),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 400),
                style: TextStyle(fontSize: 14, color: Colors.red.shade400),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 28),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh_rounded),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                ),
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitialized = false;
                  });
                  _initializePlayer();
                },
                label: Text('Retry', style: TextStyle(fontSize: 17)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualizerBars() {
    return AnimatedBuilder(
      animation: _colorController,
      builder: (context, child) {
        return CustomPaint(
          painter: AudioVisualizerPainter(
            frequencyData: _frequencyData,
            colors: _visualizerColors,
            colorProgress: _colorController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildControls() {
    final duration = _playerData.player.state.duration;
    final position = _position;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
          ],

          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 4,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: position.inMilliseconds.toDouble(),
              max: duration.inMilliseconds > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1.0,
              onChanged: (value) {
                _playerData.player.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time display
              Text(
                _formatDuration(position) + ' / ' + _formatDuration(duration),
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),

              // Playback controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 28,
                    icon: Icon(Icons.replay_10, color: Colors.white),
                    onPressed: () => _playerData.player
                        .seek(position - Duration(seconds: 10)),
                  ),
                  StreamBuilder<bool>(
                    stream: _playerData.player.streams.playing,
                    builder: (context, snapshot) {
                      final bool isPlaying = snapshot.data ?? false;
                      return IconButton(
                        iconSize: 48,
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (isPlaying) {
                            _playerData.player.pause();
                          } else {
                            _playerData.player.play();
                          }
                        },
                      );
                    },
                  ),
                  IconButton(
                    iconSize: 28,
                    icon: Icon(Icons.forward_10, color: Colors.white),
                    onPressed: () => _playerData.player
                        .seek(position + Duration(seconds: 10)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  void didUpdateWidget(AudioVisualizerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _position = Duration.zero;
      _playerData = MediaPlayerManager().getPlayerFor(widget.url);
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _visualizerController.dispose();
    _colorController.dispose();
    _stopVisualizerAnimation();
    
    try {
      _playerData.player.pause();
      print('AudioVisualizerTile for ${widget.url} disposed');
    } catch (e) {
      print('Error cleaning up AudioVisualizerTile resources: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_hasError) {
      return _buildErrorWidget(_errorMessage);
    }

    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              'Loading Audio Visualizer...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          // Visualizer background
          Positioned.fill(
            child: _buildVisualizerBars(),
          ),
          
          // Controls overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }
}

class AudioVisualizerPainter extends CustomPainter {
  final List<double> frequencyData;
  final List<Color> colors;
  final double colorProgress;

  AudioVisualizerPainter({
    required this.frequencyData,
    required this.colors,
    required this.colorProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (frequencyData.isEmpty) return;

    final barWidth = size.width / frequencyData.length;
    final maxHeight = size.height * 0.8; // Leave space for controls

    for (int i = 0; i < frequencyData.length; i++) {
      final barHeight = frequencyData[i] * maxHeight;
      final x = i * barWidth;
      
      // Create gradient based on frequency position and time
      final colorIndex = ((i / frequencyData.length + colorProgress) * colors.length) % colors.length;
      final primaryColorIndex = colorIndex.floor();
      final secondaryColorIndex = (primaryColorIndex + 1) % colors.length;
      final lerpFactor = colorIndex - primaryColorIndex;
      
      final color = Color.lerp(
        colors[primaryColorIndex],
        colors[secondaryColorIndex],
        lerpFactor,
      )!;
      
      // Create gradient from bottom to top
      final rect = Rect.fromLTWH(x, size.height - barHeight, barWidth - 2, barHeight);
      
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color.withOpacity(0.8),
          color.withOpacity(0.4),
          color.withOpacity(0.1),
        ],
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;
      
      // Draw the bar with rounded top
      final roundedRect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(barWidth * 0.2),
      );
      
      canvas.drawRRect(roundedRect, paint);
      
      // Add glow effect for higher frequencies
      if (frequencyData[i] > 0.6) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawRRect(roundedRect, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(AudioVisualizerPainter oldDelegate) {
    return oldDelegate.frequencyData != frequencyData ||
           oldDelegate.colorProgress != colorProgress;
  }
}
