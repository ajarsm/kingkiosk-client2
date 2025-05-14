import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

// Player manager to keep players persistent across rebuilds
class MediaPlayerManager {
  static final MediaPlayerManager _instance = MediaPlayerManager._internal();
  
  factory MediaPlayerManager() => _instance;
  
  MediaPlayerManager._internal();
  
  final Map<String, PlayerWithController> _players = {};
  
  PlayerWithController getPlayerFor(String url) {
    if (!_players.containsKey(url)) {
      final player = Player();
      final controller = VideoController(player);
      _players[url] = PlayerWithController(player, controller);
    }
    return _players[url]!;
  }
  
  void dispose() {
    for (final playerData in _players.values) {
      playerData.player.dispose();
    }
    _players.clear();
  }
}

class PlayerWithController {
  final Player player;
  final VideoController controller;
  bool isInitialized = false;
  
  PlayerWithController(this.player, this.controller);
}

class MediaTile extends StatefulWidget {
  final String url;
  final bool loop;
  
  const MediaTile({
    Key? key,
    required this.url,
    this.loop = false,
  }) : super(key: key);

  @override
  State<MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<MediaTile> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
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
    if (widget.loop) {
      _playerData.player.setPlaylistMode(PlaylistMode.loop);
    } else {
      _playerData.player.setPlaylistMode(PlaylistMode.none);
    }
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
        _position = position;
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
      print('Error initializing video player: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = error.toString();
        });
      }
    }
  }

  @override
  void didUpdateWidget(MediaTile oldWidget) {
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
    // Note: We don't dispose the player here since it's managed by MediaPlayerManager
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
              Text('Failed to load video'),
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

    // Use MediaKit's built-in video player with default controls
    return Material(
      color: Colors.black,
      child: Video(
        controller: _playerData.controller,
        controls: AdaptiveVideoControls, // Use MediaKit's built-in controls
      ),
    );
  }
}