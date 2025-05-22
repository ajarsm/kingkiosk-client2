# WebView Duplicate Loading Fix

## Issue Description

The application was experiencing a problem where WebView tiles were loading twice when opened via MQTT `open_browser` command. This caused:

1. Duplicate network requests
2. Increased memory usage
3. Potentially slowed down application performance
4. Visible flickering during page load

The logs showed that for a single MQTT command, two WebView instances were being created:
```
flutter: 🔄 [REFRESH] WebViewManager - Created new WebViewData for URL: https://archive.org/details/Porcelain_457
...
flutter: WebView URL loading: https://archive.org/details/Porcelain_457
flutter: WebView URL loading: about:blank
...
flutter: 🔄 [REFRESH] WebViewManager - Reusing existing WebViewData for URL: https://archive.org/details/Porcelain_457
...
flutter: WebView URL loading: https://archive.org/details/Porcelain_457
flutter: WebView URL loading: about:blank
```

## Root Causes

After investigating, we identified three main issues:

1. **Inconsistent WebView Creation**: The `_buildTileContent` method in `TilingWindowView` was creating WebView tiles without stable keys, leading to unnecessary rebuilds.

2. **Overly Aggressive WebView Refreshing**: The `didUpdateWidget` logic in `WebViewTile` was triggering reloads even for minor prop changes.

3. **Inconsistent URL Caching**: The `WebViewManager` was using raw URLs as cache keys, which could lead to duplicate WebView creation for URLs that were semantically the same but formatted differently.

## Solution

We implemented fixes at three levels:

### 1. Added Stable Keys to WebView Creation

In `TilingWindowView`, we added a stable key to the WebViewTile to prevent unnecessary recreation:

```dart
// Create the WebViewTile without a controller and with a stable key
return WebViewTile(
  key: ValueKey('initial_webview_${tile.id}'),
  url: tile.url,
  windowId: tile.id,
);
```

### 2. Improved WebView Update Logic

In `WebViewTile`, we refined the logic for when to reset a WebView:

```dart
// Only reset the WebView when explicitly requested
bool shouldReset = oldWidget.url != widget.url;

// Only consider refreshKey changes when a non-null refreshKey is provided
if (widget.refreshKey != null && oldWidget.refreshKey != widget.refreshKey) {
  shouldReset = true;
}
```

### 3. Normalized URL Caching

In `WebViewManager`, we added URL normalization to ensure consistent caching:

```dart
String _normalizeUrl(String url) {
  // Remove trailing slashes, query parameters, or other variations
  try {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.host}${uri.path}';
  } catch (_) {
    return url;
  }
}
```

## Testing

To verify the fix works:

1. Send an MQTT command to open a browser window:
```json
{
  "command": "open_browser",
  "url": "https://archive.org/details/Porcelain_457",
  "title": "media in browser test"
}
```

2. Check logs for WebView creation - you should see only one instance of:
```
WebViewManager - Created new WebViewData for URL: https://archive.org/details/Porcelain_457
```

3. Observe the WebView loading behavior - it should only load once without flickering.

## Benefits

- Reduced memory usage
- Improved application performance
- Better user experience with no flickering
- More efficient network usage (no duplicate requests)

## Future Considerations

- Consider implementing a caching mechanism for web content to improve reload speed
- Monitor WebView memory usage for long-running sessions
- Add capability to preload commonly used web pages
