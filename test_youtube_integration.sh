#!/bin/bash

# Run the app with YouTube feature test
echo "Running KingKiosk with YouTube integration..."
cd /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk
flutter run -d chrome --web-port 8000

# Use this to test with a real device if needed
# flutter run -d <device-id>
