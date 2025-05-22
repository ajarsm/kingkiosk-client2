#!/usr/bin/env bash

echo "===== WebView Duplicate Loading Fix Test ====="
echo

echo "Checking WebViewTile implementation..."
if grep -q "shouldReset = true" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/home/widgets/web_view_tile.dart"; then
  echo "✅ WebViewTile uses proper reset logic"
else
  echo "❌ WebViewTile missing proper reset logic"
fi

echo "Checking WebViewManager implementation..."
if grep -q "_normalizeUrl" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/home/widgets/webview_manager.dart"; then
  echo "✅ WebViewManager uses URL normalization for consistent caching"
else
  echo "❌ WebViewManager missing URL normalization"
fi

echo "Checking TilingWindowView implementation..."
if grep -q "key: ValueKey('initial_webview_" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/home/views/tiling_window_view.dart"; then
  echo "✅ TilingWindowView uses stable key for WebViewTile"
else
  echo "❌ TilingWindowView missing stable key for WebViewTile"
fi

echo
echo "Testing MQTT Open Browser Command:"
echo "1. Use this properly formatted JSON in your MQTT client:"
echo '{
  "command": "open_browser",
  "url": "https://archive.org/details/Porcelain_457",
  "title": "media in browser test"
}'
echo
echo "2. After fix, you should see only one WebViewTile created and loaded, not two."
echo "3. Check logs for 'WebViewManager - Created new WebViewData' - should appear only once per URL."
echo
echo "===== Test Complete ====="
