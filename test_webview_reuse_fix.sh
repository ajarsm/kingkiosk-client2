#!/bin/bash

# Test script for verifying WebView reuse fix
echo "📱 Testing WebView controller reuse fix..."

# Clear logs
rm -f webview_test_log.txt

# Run the app with logging enabled
flutter run --verbose 2>&1 | tee webview_test_log.txt &
APP_PID=$!

# Wait for app to start
sleep 15

echo "📊 Analyzing logs for WebView creation and deallocation..."
# Check if WebView controllers are being deallocated
WEBVIEW_CREATED=$(grep "WebViewTile - Creating WebView for URL" webview_test_log.txt | wc -l)
WEBVIEW_DEALLOC=$(grep "FlutterWebViewController - dealloc" webview_test_log.txt | wc -l)

echo "🧪 Results:"
echo "WebView creation count: $WEBVIEW_CREATED"
echo "WebView dealloc count: $WEBVIEW_DEALLOC"

if [ $WEBVIEW_DEALLOC -eq 0 ]; then
  echo "✅ Success! No WebView controllers were deallocated."
  echo "🎯 Fix appears to be working correctly."
else
  echo "❌ WebView controllers are still being deallocated."
  echo "🔍 Check logs for more details."
fi

# Kill the app
kill $APP_PID
