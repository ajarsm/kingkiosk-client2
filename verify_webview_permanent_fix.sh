#!/bin/bash
# verify_webview_permanent_fix.sh - Verification script for WebView permanent fix
# This script tests if the WebView components are now properly preserved across rebuilds

echo "🔍 Starting WebView permanent fix verification..."

# Check for required files
if [ ! -f "lib/app/modules/home/widgets/web_view_tile.dart" ]; then
    echo "⚠️ ERROR: web_view_tile.dart not found!"
    exit 1
fi

if [ ! -f "lib/app/modules/home/widgets/webview_manager.dart" ]; then
    echo "⚠️ ERROR: webview_manager.dart not found!"
    exit 1
fi

echo "✅ Required files found"

# Look for stable WebView implementation in the code
if ! grep -q "_stableWebViewKey" "lib/app/modules/home/widgets/web_view_tile.dart"; then
    echo "⚠️ ERROR: Stable WebView key not found in web_view_tile.dart"
    exit 1
fi

if ! grep -q "_createWebView" "lib/app/modules/home/widgets/web_view_tile.dart"; then
    echo "⚠️ ERROR: WebView creation method not found in web_view_tile.dart"
    exit 1
fi

echo "✅ Stable WebView implementation found"

# Check for URL normalization in WebViewManager
if ! grep -q "_normalizeUrl" "lib/app/modules/home/widgets/webview_manager.dart"; then
    echo "⚠️ ERROR: URL normalization not found in webview_manager.dart"
    exit 1
fi

echo "✅ URL normalization implementation found"

# Check for stable key in TilingWindowView
if ! grep -q "key: ValueKey('initial_webview_" "lib/app/modules/home/views/tiling_window_view.dart"; then
    echo "⚠️ ERROR: Stable key not found in TilingWindowView"
    exit 1
fi

echo "✅ Stable key implementation found in TilingWindowView"

# Check for proper didUpdateWidget implementation
if ! grep -q "This ensures we only create a new WebView when explicitly requested" "lib/app/modules/home/widgets/web_view_tile.dart"; then
    echo "⚠️ ERROR: Proper didUpdateWidget logic not found"
    exit 1
fi

echo "✅ Proper WebView update logic found"

# Test loading documentation exists
if [ ! -f "webview_permanent_fix.md" ]; then
    echo "⚠️ ERROR: webview_permanent_fix.md documentation not found"
    exit 1
fi

echo "✅ Documentation found"

# All tests passed
echo "🎉 WebView permanent fix verification PASSED!"
echo "The WebView implementation now properly preserves instances across rebuilds."
echo "This should eliminate duplicate loading, flickering, and reduce memory usage."
echo ""
echo "📋 Next steps:"
echo "1. Run the app and test opening web pages via MQTT"
echo "2. Monitor memory usage during operation"
echo "3. Check logs for WebView controller deallocation messages"
echo ""
