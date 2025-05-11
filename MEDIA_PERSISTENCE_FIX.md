# Media Persistence Fix

## Issue

When resizing or changing focus of windows containing media players (videos or audio), the media would restart from the beginning. This was happening because:

1. The window component was being rebuilt when its size changed or it gained/lost focus
2. Each rebuild was recreating a new Player instance, losing any playback state
3. The new Player would always restart the media from the beginning

## Solution

A persistence layer has been implemented to maintain media player state across rebuilds:

### 1. Player Manager Singleton

Created a `MediaPlayerManager` singleton class that:
- Maintains a persistent map of media URLs to Player instances
- Ensures each unique URL gets only one Player instance
- Keeps players alive even when their UI components are temporarily removed from view

```dart
class MediaPlayerManager {
  static final MediaPlayerManager _instance = MediaPlayerManager._internal();
  factory MediaPlayerManager() => _instance;
  
  final Map<String, PlayerWithController> _players = {};
  
  PlayerWithController getPlayerFor(String url) {
    if (!_players.containsKey(url)) {
      final player = Player();
      final controller = VideoController(player);
      _players[url] = PlayerWithController(player, controller);
    }
    return _players[url]!;
  }
}
```

### 2. Keeping State Alive

Both MediaTile and AudioTile implement:
- `AutomaticKeepAliveClientMixin` - Keeps the widget state alive when it's not visible
- `WidgetsBindingObserver` - Tracks app lifecycle changes (foreground/background)

### 3. Position Tracking

The solution tracks media position and preserves it across:
- Window focus changes
- Window resizing
- App lifecycle changes (background/foreground)

### 4. Benefits

This implementation provides:
- Seamless playback experience (videos don't restart)
- Memory efficiency (players are reused rather than recreated)
- Better user experience when manipulating multiple windows
- Preservation of media position even when the app is backgrounded

## Usage

The fix is transparently integrated into the existing MediaTile and AudioTile components. No API changes were needed.

## Future Improvements

Potential future enhancements:
- Add a cleanup mechanism to dispose unused players after some timeout
- Implement a limit on the number of simultaneous active players
- Add options for pre-loading media to reduce initial load time