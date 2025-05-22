#!/bin/bash
# Script to verify WebView touch events are working properly

echo "Running WebView Touch Event Test..."
cd "$(dirname "$0")"

# Run the app with debugging flags for the WebView
flutter run -d chrome \
  --dart-define=WEBVIEW_DEBUG=true \
  --dart-define=VERBOSE_WEBVIEW=true \
  --dart-define=TRACE_TOUCH_EVENTS=true \
  --web-renderer html
