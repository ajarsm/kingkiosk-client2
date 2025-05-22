#!/bin/bash
# Test notification sound playback
# This script runs the app with extra logging for notification sounds

echo "Running Flutter app with notification sound debugging..."
cd "$(dirname "$0")"

# Set environment variable to enable extra audio logging
export FLUTTER_AUDIO_DEBUG=true

# Run the app with verbose logging
echo "Starting Flutter app with notification sound debugging..."
echo "Watch for 🔊 emoji in logs to track audio playback..."

flutter run -v --debug \
  --dart-define=ENABLE_AUDIO_LOGGING=true \
  --dart-define=TEST_NOTIFICATION_SOUND=true \
  --dart-define=ENABLE_VERBOSE_AUDIO=true
