#!/usr/bin/env bash

# Simple script without color codes for compatibility
echo "=== WebView Duplicate Loading Fix Verification ===="
echo

# Check if the fix is properly implemented
echo "Checking implementation of fixes..."

# Check for stable keys in TilingWindowView
if grep -q "key: ValueKey('initial_webview_" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/home/views/tiling_window_view.dart"; then
  echo "✓ TilingWindowView: Using stable keys for WebViewTile"
else
  echo "✗ TilingWindowView: Not using stable keys for WebViewTile"
fi

# Check for improved reset logic in WebViewTile
if grep -q "shouldReset = " "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/home/widgets/web_view_tile.dart"; then
  echo "✓ WebViewTile: Using improved reset logic"
else
  echo "✗ WebViewTile: Not using improved reset logic"
fi

# Check for URL normalization in WebViewManager
if grep -q "_normalizeUrl" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/home/widgets/webview_manager.dart"; then
  echo "✓ WebViewManager: Using URL normalization"
else
  echo "✗ WebViewManager: Not using URL normalization"
fi

echo
echo "Testing instructions:"
echo "1. Send the following MQTT command to open a browser window:"
echo 
echo '{
  "command": "open_browser",
  "url": "https://archive.org/details/Porcelain_457",
  "title": "Test WebView Loading"
}'
echo
echo "2. Watch the logs and check for the following:"
echo "   - Only ONE instance of: WebViewManager - Created new WebViewData for URL"
echo "   - The URL should only load ONCE (not twice as before)"
echo
echo "3. You should NOT see duplicate WebView loading or flickering."
echo

echo "=== Verification Complete ==="
echo "For detailed information, see: webview_duplicate_fix.md"
echo
