#!/bin/bash

# verify_final_webview_fix.sh
# Tests the final WebView persistence implementation

echo "🔍 Starting WebView persistence verification test..."

# Initialize test variables
TEST_URL="https://flutter.dev"
WINDOW_ID="test_webview_window"
TEST_ITERATIONS=5

# Build and run the app with debug logging enabled
echo "🚀 Building and running the app with WebView debug logging..."
flutter run --verbose > webview_final_fix_log.txt 2>&1 &
APP_PID=$!

# Wait for app to fully start
echo "⏳ Waiting for app to initialize..."
sleep 10

# Send MQTT command to open a browser window
echo "📊 Sending MQTT command to open browser window with ID: $WINDOW_ID"
for i in $(seq 1 $TEST_ITERATIONS); do
    echo "🔄 Iteration $i: Triggering WebView creation and update"
    mosquitto_pub -h localhost -p 1883 -t kingkiosk/command -m "{\"command\":\"open_browser\",\"window_id\":\"$WINDOW_ID\",\"url\":\"$TEST_URL\"}"
    
    # Wait for WebView to load
    sleep 5
    
    # Update the same WebView to trigger update but not recreation
    mosquitto_pub -h localhost -p 1883 -t kingkiosk/command -m "{\"command\":\"open_browser\",\"window_id\":\"$WINDOW_ID\",\"url\":\"$TEST_URL?refresh=$i\"}"
    
    # Wait for update
    sleep 3
done

# Let the app run a bit longer to ensure stability
sleep 10

# Close the browser window
echo "🔒 Closing browser window"
mosquitto_pub -h localhost -p 1883 -t kingkiosk/command -m "{\"command\":\"close_window\",\"window_id\":\"$WINDOW_ID\"}"

# Wait for window to close
sleep 2

# Clean up
echo "🧹 Cleaning up and terminating test..."
kill $APP_PID

# Analyze log for WebView instance patterns
echo "📝 Analyzing logs for WebView instance creation and reuse patterns..."
echo "Expected pattern: WebView instances should only be created once per window ID"

# Count WebView creation instances
CREATION_COUNT=$(grep -c "Creating new WebView for ID: $WINDOW_ID" webview_final_fix_log.txt)
REUSE_COUNT=$(grep -c "Reusing WebView for ID: $WINDOW_ID" webview_final_fix_log.txt)

echo "Results:"
echo "  - New WebView creations: $CREATION_COUNT (should be 1)"
echo "  - WebView reuse count: $REUSE_COUNT (should be approximately $((TEST_ITERATIONS * 2 - 1)))"

if [ "$CREATION_COUNT" -eq 1 ] && [ "$REUSE_COUNT" -gt "$TEST_ITERATIONS" ]; then
  echo "✅ TEST PASSED: WebView instances are being properly maintained and reused!"
else
  echo "❌ TEST FAILED: WebView instances are still being recreated unnecessarily."
fi

echo "📊 Test complete. See webview_final_fix_log.txt for detailed logs."
