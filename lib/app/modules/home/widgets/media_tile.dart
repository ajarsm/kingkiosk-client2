import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:async';

// Player manager to keep players persistent across rebuilds
class MediaPlayerManager {
  static final MediaPlayerManager _instance = MediaPlayerManager._internal();
  
  factory MediaPlayerManager() => _instance;
  
  MediaPlayerManager._internal() {
    // Start periodic cleanup timer
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _cleanupUnusedPlayers();
    });
  }
  
  final Map<String, PlayerWithController> _players = {};
  Timer? _cleanupTimer;
  final Map<String, DateTime> _lastAccessTime = {};
  
  PlayerWithController getPlayerFor(String url) {
    // Update last access time when player is requested
    _lastAccessTime[url] = DateTime.now();
    
    if (!_players.containsKey(url)) {
      final player = Player();
      final controller = VideoController(player);
      _players[url] = PlayerWithController(player, controller);
    }
    return _players[url]!;
  }
  
  /// Safely dispose a specific player by URL
  /// Returns true if a player was found and disposed
  bool disposePlayerFor(String url) {
    if (_players.containsKey(url)) {
      try {
        final playerData = _players[url]!;
        // Remove from map first to prevent race conditions
        _players.remove(url);
        
        // Force cleanup before disposal
        playerData.player.stop();
        
        // Use a delayed disposal to give time for resource cleanup
        Future.delayed(Duration(milliseconds: 100), () {
          try {            // Then dispose the player
            playerData.player.dispose();
            // VideoController doesn't have a dispose method
            print('Player for $url successfully disposed');
          } catch (e) {
            print('Error in delayed disposal for $url: $e');
          }
        });
        return true;
      } catch (e) {
        print('Error disposing player for $url: $e');
        return false;
      }
    }
    return false;
  }
  
  void dispose() {
    for (final playerData in _players.values) {
      try {
        playerData.player.stop();
        playerData.player.dispose();
      } catch (e) {
        print('Error disposing player during manager cleanup: $e');
      }
    }
    _players.clear();
    _cleanupTimer?.cancel();
  }
  
  /// Force cleanup all players and reset the manager
  /// Use this when black screens start appearing, or device seems unstable
  void resetAllPlayers() {
    // Make a copy of URLs to avoid modification during iteration
    final urls = List<String>.from(_players.keys);
    
    // First stop all players to release hardware resources
    for (final url in urls) {
      try {
        if (_players.containsKey(url)) {
          _players[url]!.player.stop();
        }
      } catch (e) {
        print('Error stopping player during reset: $e');
      }
    }
    
    // Wait briefly to allow hardware resources to be released
    Future.delayed(Duration(milliseconds: 200), () {
      // Then dispose all players
      for (final url in urls) {
        try {
          if (_players.containsKey(url)) {
            _players[url]!.player.dispose();
            print('Player for $url disposed during reset');
          }
        } catch (e) {
          print('Error disposing player during reset: $e');
        }
      }
      
      // Clear the map
      _players.clear();
      print('All media players reset and disposed');
      
      // Force re-initialization of MediaKit
      MediaKit.ensureInitialized();
    });
  }
  
  /// Cleanup players that haven't been accessed in a while
  void _cleanupUnusedPlayers() {
    final now = DateTime.now();
    final urlsToRemove = <String>[];
    
    // Find players that haven't been used in the last 10 minutes
    for (final url in _players.keys) {
      final lastAccess = _lastAccessTime[url] ?? now;
      if (now.difference(lastAccess).inMinutes > 10) {
        urlsToRemove.add(url);
      }
    }
    
    // Dispose unused players
    for (final url in urlsToRemove) {
      disposePlayerFor(url);
      print('Auto-disposed unused player for: $url');
    }
    
    // If more than 5 players are active, force a MediaKit re-initialization
    if (_players.length > 5) {
      MediaKit.ensureInitialized();
    }
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
  bool get wantKeepAlive => true; // Keep this widget alive when it's not visible  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      _playerData = MediaPlayerManager().getPlayerFor(widget.url);
      // Defer playlist mode setting to _initializePlayer to avoid race conditions
      _initializePlayer();
    } catch (e) {
      print('Error initializing media player in MediaTile: $e');
      // Handle initialization error gracefully
      setState(() {
        _hasError = true;
        _errorMessage = 'Error initializing player: $e';
      });
    }
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
      
      // Set playlist mode safely after player is initialized
      try {
        if (widget.loop) {
          await _playerData.player.setPlaylistMode(PlaylistMode.loop);
        } else {
          await _playerData.player.setPlaylistMode(PlaylistMode.none);
        }
      } catch (e) {
        print('Warning: Could not set playlist mode: $e');
        // Continue anyway - better to play without loop than to fail
      }
      
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
    // Note: We don't fully dispose the player here since it's managed by MediaPlayerManager
    // But we do need to stop it to release hardware resources
    try {
      _playerData.player.pause();
      
      // Notify the system that this tile is no longer active
      print('MediaTile for ${widget.url} disposed');
    } catch (e) {
      print('Error cleaning up MediaTile resources: $e');
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