#!/bin/bash

# Script to run the halo effect robustness tests
# Location: /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/run_halo_effect_robustness_test.sh

echo "🧪 Running Halo Effect Robustness Tests..."
echo "This will launch a test application that exercises various edge cases"
echo "to verify the robustness of our error handling"

# Set up log file
LOG_FILE="halo_effect_robustness_test.log"
echo "Starting robustness tests at $(date)" > $LOG_FILE

# Run the Flutter test application with output logged
flutter run -d macos test_halo_effect_robustness.dart 2>&1 | tee -a $LOG_FILE

echo "✅ Test completed"
echo "Check the test application window to see the results"
echo "Log file saved to: $LOG_FILE"
