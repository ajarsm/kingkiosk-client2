#!/bin/bash

# Run the simple Window Halo Test App
echo "🧪 Running Window Halo Effect Test App..."
cd "$(dirname "$0")"

# First kill any running instances
pkill -f flutter || true

# Run the test app
flutter run -d macos -t window_halo_test_app.dart

echo "🧹 Test complete"
