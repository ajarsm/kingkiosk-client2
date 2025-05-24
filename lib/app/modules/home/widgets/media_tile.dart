import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:async';
import 'package:get/get.dart';
import '../../../services/media_hardware_detection.dart';

// Player manager to keep players persistent across rebuilds
class MediaPlayerManager {
  static final MediaPlayerManager _instance = MediaPlayerManager._internal();

  factory MediaPlayerManager() => _instance;

  MediaPlayerManager._internal() {
    // Start periodic cleanup timer
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _cleanupUnusedPlayers();
    });

    // Initialize hardware detection service
    try {
      // Try to find existing instance
      Get.find<MediaHardwareDetectionService>();
    } catch (_) {
      // Create a new instance if not found
      final hardwareDetection = MediaHardwareDetectionService();
      hardwareDetection.init();
      Get.put(hardwareDetection, permanent: true);
    }
  }

  final Map<String, PlayerWithController> _players = {};
  Timer? _cleanupTimer;
  final Map<String, DateTime> _lastAccessTime = {};

  PlayerWithController getPlayerFor(String url) {
    // Update last access time when player is requested
    _lastAccessTime[url] = DateTime.now();

    if (!_players.containsKey(url)) {
      // Get hardware acceleration configuration
      final hardwareDetectionService =
          Get.find<MediaHardwareDetectionService>();
      final playerConfig = hardwareDetectionService.getPlayerConfiguration();

      // Create player with the configuration
      final player = Player(configuration: playerConfig);
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
        _lastAccessTime.remove(url);

        // Check if player is already disposed to prevent "Player has been disposed" errors
        bool isDisposed = false;
        try {
          // Try to access a property to check if player is disposed
          // If it throws an assertion error, it's already disposed
          final _ = playerData.player.state.playing;
        } catch (e) {
          if (e.toString().contains('Player has been disposed')) {
            isDisposed = true;
            print('Player for $url was already disposed, skipping disposal');
          }
        }

        if (!isDisposed) {
          // Only try to stop and dispose if not already disposed
          try {
            // Force cleanup before disposal
            playerData.player.stop();

            // Use a delayed disposal to give time for resource cleanup
            Future.delayed(Duration(milliseconds: 100), () {
              try {
                // Then dispose the player
                playerData.player.dispose();
                // VideoController doesn't have a dispose method
                print('Player for $url successfully disposed');
              } catch (e) {
                print('Error in delayed disposal for $url: $e');
              }
            });
          } catch (e) {
            print('Error stopping player for $url: $e');
          }
        }
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
        // Check if player is already disposed
        bool isDisposed = false;
        try {
          final _ = playerData.player.state.playing;
        } catch (e) {
          if (e.toString().contains('Player has been disposed')) {
            isDisposed = true;
            print('Player was already disposed, skipping disposal');
          }
        }

        if (!isDisposed) {
          playerData.player.stop();
          playerData.player.dispose();
        }
      } catch (e) {
        print('Error disposing player during manager cleanup: $e');
      }
    }
    _players.clear();
    _lastAccessTime.clear();
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
          // Check if player is already disposed
          bool isDisposed = false;
          try {
            final _ = _players[url]!.player.state.playing;
          } catch (e) {
            if (e.toString().contains('Player has been disposed')) {
              isDisposed = true;
              print('Player for $url was already disposed, skipping stop');
              // Remove from map since it's already disposed
              _players.remove(url);
              _lastAccessTime.remove(url);
            }
          }

          if (!isDisposed) {
            _players[url]!.player.stop();
          }
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
            // Check again if player is already disposed
            bool isDisposed = false;
            try {
              final _ = _players[url]!.player.state.playing;
            } catch (e) {
              if (e.toString().contains('Player has been disposed')) {
                isDisposed = true;
                print(
                    'Player for $url was already disposed, skipping disposal');
                // Remove from map since it's already disposed
                _players.remove(url);
                _lastAccessTime.remove(url);
              }
            }

            if (!isDisposed) {
              _players[url]!.player.dispose();
              print('Player for $url disposed during reset');
              // Remove from map after successful disposal
              _players.remove(url);
              _lastAccessTime.remove(url);
            }
          }
        } catch (e) {
          print('Error disposing player during reset: $e');
        }
      }

      // Clear the map (in case any entries remain)
      _players.clear();
      _lastAccessTime.clear();
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

    // Check for already disposed players that might still be in the map
    for (final url in _players.keys) {
      if (!urlsToRemove.contains(url)) {
        try {
          final _ = _players[url]!.player.state.playing;
        } catch (e) {
          if (e.toString().contains('Player has been disposed')) {
            urlsToRemove.add(url);
            print('Detected already disposed player for $url, cleaning up');
          }
        }
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

class _MediaTileState extends State<MediaTile>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late final PlayerWithController _playerData;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  Duration _position = Duration.zero;

  @override
  bool get wantKeepAlive =>
      true; // Keep this widget alive when it's not visible  @override
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

      // Report error to hardware detection service
      try {
        final hardwareDetectionService =
            Get.find<MediaHardwareDetectionService>();
        hardwareDetectionService.trackMediaError(error.toString());

        // If hardware acceleration was disabled due to this error,
        // try to recreate the player with new settings
        if (hardwareDetectionService.hasDetectedIssue.value) {
          print('Hardware issue detected, recreating player with new settings');
          // Force manager to dispose and recreate this player
          MediaPlayerManager().disposePlayerFor(widget.url);
          // Get a new player with updated hardware settings
          _playerData = MediaPlayerManager().getPlayerFor(widget.url);

          // Try to initialize again with new settings
          await _playerData.player.open(Media(widget.url));

          if (widget.loop) {
            await _playerData.player.setPlaylistMode(PlaylistMode.loop);
          }

          // If we got here, the player was successfully recreated with new settings
          _playerData.isInitialized = true;
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _hasError = false;
            });
          }
          return;
        }
      } catch (e) {
        print('Error reporting hardware issue: $e');
        // Continue with normal error handling
      }

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
      // Check if player is already disposed
      bool isDisposed = false;
      try {
        final _ = _playerData.player.state.playing;
      } catch (e) {
        if (e.toString().contains('Player has been disposed')) {
          isDisposed = true;
          print('Player for ${widget.url} was already disposed in MediaTile');
        }
      }

      if (!isDisposed) {
        _playerData.player.pause();
        print('MediaTile for ${widget.url} disposed');
      }
    } catch (e) {
      print('Error cleaning up MediaTile resources: $e');
    }
    super.dispose();
  }

  Widget _buildErrorWidget(String message) {
    // Check if this is a hardware acceleration issue
    bool isHardwareIssue = false;
    bool hardwareAccelerationEnabled = true;

    try {
      final hardwareDetectionService =
          Get.find<MediaHardwareDetectionService>();
      isHardwareIssue = hardwareDetectionService.hasDetectedIssue.value;
      hardwareAccelerationEnabled =
          hardwareDetectionService.isHardwareAccelerationEnabled.value;
    } catch (e) {
      print('Error checking hardware acceleration status: $e');
    }

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
                child: Icon(Icons.error_rounded, color: Colors.white, size: 64),
              ),
              SizedBox(height: 22),
              Text('Failed to load media',
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

              // Show hardware acceleration status if it's a hardware issue
              if (isHardwareIssue) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Hardware acceleration is ${hardwareAccelerationEnabled ? 'enabled' : 'disabled'}',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              SizedBox(height: 28),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh_rounded),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 36, vertical: 16),
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

                  // Add button to toggle hardware acceleration if it's a hardware issue
                  if (isHardwareIssue) ...[
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: Icon(hardwareAccelerationEnabled
                          ? Icons.hardware
                          : Icons.settings_applications),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                      ),
                      onPressed: () {
                        try {
                          final hardwareDetectionService =
                              Get.find<MediaHardwareDetectionService>();
                          hardwareDetectionService.toggleHardwareAcceleration(
                              !hardwareAccelerationEnabled);
                          // Force reload
                          setState(() {
                            _hasError = false;
                            _isInitialized = false;
                          });
                          _initializePlayer();
                        } catch (e) {
                          print('Error toggling hardware acceleration: $e');
                        }
                      },
                      label: Text(
                        hardwareAccelerationEnabled
                            ? 'Disable Hardware Accel.'
                            : 'Enable Hardware Accel.',
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_hasError) {
      return _buildErrorWidget(_errorMessage);
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
