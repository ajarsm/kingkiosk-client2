import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'media_tile.dart'; // Import to reuse the PlayerManager

class AudioTile extends StatefulWidget {
  final String url;
  
  const AudioTile({
    Key? key,
    required this.url,
  }) : super(key: key);

  @override
  State<AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends State<AudioTile> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late final PlayerWithController _playerData;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  Duration _position = Duration.zero;
  
  @override
  bool get wantKeepAlive => true; // Keep this widget alive when it's not visible

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playerData = MediaPlayerManager().getPlayerFor(widget.url);
    _initializePlayer();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to prevent restarts
    if (state == AppLifecycleState.resumed && _isInitialized) {
      // Resume from the saved position when app comes back to foreground
      _playerData.player.seek(_position);
    } else if (state == AppLifecycleState.paused) {
      // Save position when app goes to background
      _position = _playerData.player.state.position;
    }
  }

  Future<void> _initializePlayer() async {
    if (_playerData.isInitialized) {
      // If already initialized, just update our state
      setState(() {
        _isInitialized = true;
      });
      return;
    }

    try {
      // Save position listener to track playback position
      _playerData.player.streams.position.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
      
      // Wait for player to initialize
      await _playerData.player.open(Media(widget.url));
      
      // Mark as initialized
      _playerData.isInitialized = true;
      
      // Set the state to reflect that the player is initialized
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (error) {
      print('Error initializing audio player: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = error.toString();
        });
      }
    }
  }
  
  // A compact audio player UI suitable for smaller containers
  Widget _buildCompactAudioPlayer() {
    final duration = _playerData.player.state.duration;
    final position = _position;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Audio title and info
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              Uri.parse(widget.url).pathSegments.last,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SliderTheme(
              data: SliderThemeData(
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 4,
              ),
              child: Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds > 0 
                    ? duration.inMilliseconds.toDouble() 
                    : 1.0,
                onChanged: (value) {
                  _playerData.player.seek(Duration(milliseconds: value.toInt()));
                },
                activeColor: Colors.blue,
              ),
            ),
          ),
          
          // Time and controls row
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
                    iconSize: 24,
                    icon: Icon(Icons.replay_10, color: Colors.white),
                    padding: EdgeInsets.all(4),
                    onPressed: () => _playerData.player.seek(position - Duration(seconds: 10)),
                  ),
                  StreamBuilder<bool>(
                    stream: _playerData.player.streams.playing,
                    builder: (context, snapshot) {
                      final bool isPlaying = snapshot.data ?? false;
                      return IconButton(
                        iconSize: 32,
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.all(4),
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
                    iconSize: 24,
                    icon: Icon(Icons.forward_10, color: Colors.white),
                    padding: EdgeInsets.all(4),
                    onPressed: () => _playerData.player.seek(position + Duration(seconds: 10)),
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
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void didUpdateWidget(AudioTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If URL changed, get a different player
    if (oldWidget.url != widget.url) {
      _position = Duration.zero;
      _playerData = MediaPlayerManager().getPlayerFor(widget.url);
      _initializePlayer();
    }
  }
    @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Note: We don't fully dispose the player here since it's managed by MediaPlayerManager
    // But we do need to stop it to release hardware resources
    try {
      _playerData.player.pause();
      
      // Notify the system that this tile is no longer active
      print('AudioTile for ${widget.url} disposed');
    } catch (e) {
      print('Error cleaning up AudioTile resources: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text('Failed to load audio'),
              SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitialized = false;
                  });
                  _initializePlayer();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    // For audio, use a more compact audio player that adapts to its container
    return Material(
      color: Colors.grey.shade800,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use compact controls when space is limited
          final bool useCompactControls = constraints.maxHeight < 200;
          
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: useCompactControls 
                ? _buildCompactAudioPlayer()
                : Video(
                    controller: _playerData.controller,
                    controls: MaterialDesktopVideoControls,
                    fill: Colors.transparent,
                  ),
          );
        }
      ),
    );
  }
}