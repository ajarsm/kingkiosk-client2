#!/bin/bash

# Verification script for WebView controller reuse fix
echo "🔍 Starting WebView permanent fix verification..."

# Run app and monitor logs
echo "📱 Running app and monitoring WebView creation/deallocation..."
flutter run --verbose 2>&1 | tee webview_verification.log &
APP_PID=$!

# Wait for app to initialize
sleep 15

# Force multiple rebuilds to test fix
echo "🔄 Forcing widget tree rebuilds..."
for i in {1..5}; do
  # Simulate a state change that would cause rebuilds
  echo "🔄 Rebuild $i..."
  flutter pub run flutter_test:test_driver run_configs/trigger_rebuild.dart
  sleep 3
done

# Kill app process
kill $APP_PID
sleep 2

# Analyze logs
echo "📊 Analyzing logs..."
WEBVIEW_CREATED=$(grep "WebViewTile - Creating WebView for URL" webview_verification.log | wc -l)
WEBVIEW_DEALLOC=$(grep "FlutterWebViewController - dealloc" webview_verification.log | wc -l)
URL_LOADS=$(grep "WebViewTile - Load started for URL" webview_verification.log | wc -l)

echo "-------------------- VERIFICATION RESULTS --------------------"
echo "WebView creation count: $WEBVIEW_CREATED"
echo "WebView deallocation count: $WEBVIEW_DEALLOC"
echo "URL load count: $URL_LOADS"

if [ $WEBVIEW_DEALLOC -eq 0 ]; then
  echo "✅ SUCCESS: No WebView controllers were deallocated during rebuilds!"
  echo "✅ The permanent WebView fix is working correctly."
else
  echo "❌ FAILED: WebView controllers are still being deallocated."
  echo "WebView created count: $WEBVIEW_CREATED"
  echo "WebView deallocated count: $WEBVIEW_DEALLOC"
  echo "❌ The fix needs more work."
fi

# Final report
echo ""
echo "📝 Verification Summary:"
echo "-----------------------------------------------"
echo "1. WebView instance created once: $([ $WEBVIEW_CREATED -eq 1 ] && echo '✅ Yes' || echo '❌ No')"
echo "2. WebView controller persistent: $([ $WEBVIEW_DEALLOC -eq 0 ] && echo '✅ Yes' || echo '❌ No')"
echo "3. URL loads happening correctly: $([ $URL_LOADS -ge 1 ] && echo '✅ Yes' || echo '❌ No')"
echo ""
echo "🏁 Verification complete."
