#!/bin/bash
# Test notification system with sound playback
# This script triggers notifications with sound for testing

echo "Testing notification system with sound playback..."

cd "$(dirname "$0")"

# Run flutter app with specific test flags
flutter run -d chrome \
  --dart-define=TEST_NOTIFICATION=true \
  --dart-define=ENABLE_AUDIO_LOGGING=true \
  --dart-define=SHOW_TEST_NOTIFICATION=true
