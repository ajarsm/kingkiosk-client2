import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:async';
import 'package:get/get.dart';
import '../../../services/media_hardware_detection.dart';
import '../controllers/media_tile_controller.dart';

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

class MediaTile extends GetView<MediaTileController> {
  final String url;
  final bool loop;

  const MediaTile({
    Key? key,
    required this.url,
    this.loop = false,
  }) : super(key: key);

  @override
  String get tag => url; // Use URL as unique tag for multiple instances

  @override
  Widget build(BuildContext context) {
    // Initialize controller with URL-specific tag
    Get.put(MediaTileController(url: url, loop: loop), tag: tag);

    return Obx(() {
      if (controller.hasError.value) {
        return _buildErrorWidget();
      }

      if (!controller.isInitialized.value) {
        return _buildLoadingWidget();
      }

      return _buildVideoPlayer();
    });
  }

  Widget _buildErrorWidget() {
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
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                ),
              ),

              // Show hardware acceleration status if it's a hardware issue
              if (controller.isHardwareIssue) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Hardware acceleration is ${controller.isHardwareAccelerationEnabled ? 'enabled' : 'disabled'}',
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
                    onPressed: () => controller.retry(),
                    label: Text('Retry', style: TextStyle(fontSize: 17)),
                  ),

                  // Add button to toggle hardware acceleration if it's a hardware issue
                  if (controller.isHardwareIssue) ...[
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: Icon(controller.isHardwareAccelerationEnabled
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
                      onPressed: () =>
                          controller.toggleHardwareAccelerationAndRetry(),
                      label: Text(
                        controller.isHardwareAccelerationEnabled
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

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 8),
            Text(
              'Loading media...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Material(
      color: Colors.black,
      child: Video(
        controller: controller.videoController,
        controls: AdaptiveVideoControls, // Use MediaKit's built-in controls
      ),
    );
  }
}
