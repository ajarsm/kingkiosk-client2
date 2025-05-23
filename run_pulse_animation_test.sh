#!/bin/bash

# Script to run the standalone halo effect pulse animation test
# Location: /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/run_pulse_animation_test.sh

echo "🧪 Running Halo Effect Pulse Animation Test..."
echo "This will launch a standalone test application that cycles through different pulse modes"

# Set up log file
LOG_FILE="halo_pulse_animation_test.log"
echo "Starting pulse animation test at $(date)" > $LOG_FILE

# Run the Flutter test application with output logged
flutter run -d macos test_pulse_animation.dart 2>&1 | tee -a $LOG_FILE

echo "✅ Test completed"
echo "Check the test application window to see the results"
echo "Log file saved to: $LOG_FILE"
