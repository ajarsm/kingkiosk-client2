#!/bin/sh
# This script starts the application and then simulates different shutdown scenarios
# to verify that the cleanup code is working properly

# Run the Flutter app in debug mode so we can see logs
echo "Starting Flutter app in debug mode..."
flutter run -d macos --debug &
APP_PID=$!

# Wait for app to fully start up
echo "Waiting for app to start..."
sleep 10

# Capture the app's process ID
echo "App started with PID: $APP_PID"

echo "The app should now:
1. Connect to MQTT (if configured)
2. Register with SIP (if configured)

Now, test the following scenarios:
- Close the app window using the window close button
- Use Cmd+Q to quit the app
- Force quit the app

Check the logs for:
- 'MQTT service onClose called - performing clean shutdown' 
- 'Published offline status before disconnect'
- 'MQTT Disconnected successfully'
- 'SIP UA unregistered successfully'

Hit Ctrl+C to terminate this script when done testing.
"

# Keep the script alive to allow manual testing
wait $APP_PID

echo "App terminated - check the logs to verify clean shutdown worked correctly!"
