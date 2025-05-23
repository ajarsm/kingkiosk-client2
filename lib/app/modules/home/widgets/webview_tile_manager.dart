import 'package:flutter/material.dart';
import 'web_view_tile.dart';

/// Global manager to maintain stable instances of WebViewTile widgets
/// This prevents recreation of WebViewTiles (and their child WebViews) during UI rebuilds
class WebViewTileManager {
  static final WebViewTileManager _instance = WebViewTileManager._internal();

  factory WebViewTileManager() => _instance;

  WebViewTileManager._internal();

  // Map of window IDs to their stable WebViewTile instances
  final Map<String, WebViewTile> _webViewTiles = {};

  /// Get a stable WebViewTile instance for a given window ID and URL
  /// If one doesn't exist, creates and stores a new instance
  WebViewTile getWebViewTileFor(String windowId, String url,
      {int? refreshKey}) {
    if (!_webViewTiles.containsKey(windowId)) {
      print(
          '🔒 WebViewTileManager - Creating new stable WebViewTile for windowId: $windowId, url: $url');
      _webViewTiles[windowId] = WebViewTile(
        key: ValueKey('stable_webview_tile_$windowId'),
        url: url,
        windowId: windowId,
        refreshKey: refreshKey,
      );
    } else if (refreshKey != null) {
      // If we have a refreshKey and the URL changed, update the existing instance with a new URL
      final existingTile = _webViewTiles[windowId]!;
      if (existingTile.url != url || existingTile.refreshKey != refreshKey) {
        print(
            '🔒 WebViewTileManager - Updating URL for existing WebViewTile, windowId: $windowId, old URL: ${existingTile.url}, new URL: $url');
        _webViewTiles[windowId] = WebViewTile(
          key: ValueKey('stable_webview_tile_$windowId'),
          url: url,
          windowId: windowId,
          refreshKey: refreshKey,
        );
      }
    }

    print(
        '🔒 WebViewTileManager - Returning stable WebViewTile for windowId: $windowId');
    return _webViewTiles[windowId]!;
  }

  /// Remove a WebViewTile when its window is closed
  void removeWebViewTile(String windowId) {
    if (_webViewTiles.containsKey(windowId)) {
      print(
          '🔒 WebViewTileManager - Removing WebViewTile for windowId: $windowId');
      _webViewTiles.remove(windowId);

      // Clean up the static WebView instances using the static method
      try {
        // Call the static cleanup method on WebViewTile
        final cleaned = WebViewTile.cleanUpWebViewInstance(windowId);
        print(
            '🔒 WebViewTileManager - Cleaned static WebView resources: $cleaned');
      } catch (e) {
        print('⚠️ WebViewTileManager - Error cleaning up static resources: $e');
      }
    }
  }
}
