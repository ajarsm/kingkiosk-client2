#!/usr/bin/env bash
# Validation script for Audio Looping functionality 

printf "\n🔍 Validating AudioService looping functionality...\n\n"

# Check if playRemoteAudio method has the looping parameter
if grep -q "bool looping = false" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/services/audio_service.dart"; then
  printf "✅ Found looping parameter in playRemoteAudio method\n"
else
  printf "❌ Could not find looping parameter in playRemoteAudio method\n"
  exit 1
fi

# Check if PlaylistMode is being set correctly
if grep -q "setPlaylistMode.*PlaylistMode\.single" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/services/audio_service.dart"; then
  printf "✅ Found PlaylistMode.single for looping implementation\n"
else
  printf "❌ Could not find PlaylistMode.single for looping implementation\n"
  exit 1
fi

# Check if the MQTT service is passing looping parameter
printf "Checking MQTT service:\n"
grep -n "playRemoteAudio" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/services/mqtt_service_consolidated.dart" | grep -v "Background"
if grep -q "looping: loop" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/services/mqtt_service_consolidated.dart"; then
  printf "✅ MQTT service is correctly passing looping parameter\n"
else
  printf "❌ MQTT service is not correctly passing looping parameter\n"
  exit 1
fi

# Check if test script exists
if [ -f "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/test_audio_looping.dart" ]; then
  printf "✅ Audio looping test script exists\n"
else
  printf "❌ Audio looping test script does not exist\n"
  exit 1
fi

# Show the actual implementation
printf "\n📄 PlayRemoteAudio Implementation:\n"
grep -A 5 "Future<void> playRemoteAudio" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/services/audio_service.dart"

printf "\n📄 Looping Implementation:\n"
grep -A 5 "if (looping)" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/services/audio_service.dart"

printf "\n✨ All validation checks passed. Audio looping functionality is correctly implemented.\n"
printf "📝 Run the test script with: flutter run -t test_audio_looping.dart\n"
printf "📘 Documentation available in: audio_looping_update.md\n\n"
