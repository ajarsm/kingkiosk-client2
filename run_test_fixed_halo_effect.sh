#!/bin/bash

# Script to test the fixed halo effect with directionality issue resolved
# Location: /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/run_test_fixed_halo_effect.sh

echo "🧪 Running Halo Effect Directionality Fix Test..."
echo "This test will run the standalone halo effect test application"

# Run the test app
cd /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk
flutter run -d macos test_fixed_halo_effect.dart

echo "✅ Test completed"
