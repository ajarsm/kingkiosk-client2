#!/bin/bash

echo "🔍 Simplified WebView permanence test..."
echo "This script will test if WebView controllers are deallocated during rebuilds"
echo

# Run the app with logging enabled (truncated output) 
flutter run --verbose 2>&1 | grep -E "WebViewTile|WebViewController|dealloc" | tee webview_controller_test.log

# To analyze the output manually, look for:
# 1. "Creating WebView" messages followed by "WebViewController - dealloc" 
# 2. Check if new controllers are created every time the UI rebuilds

echo
echo "Test complete. Check webview_controller_test.log for detailed WebView controller lifecycle events."
