#!/bin/bash

# Updated script to test the fixed halo effect with proper widget structure
# Location: /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/run_better_halo_test.sh

echo "🧪 Running Improved Halo Effect Test..."
echo "This test avoids duplicate GlobalKey issues by restructuring the widget tree"

# Run the test app
cd /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk
flutter run -d macos better_test_halo_effect.dart

echo "✅ Test completed"
