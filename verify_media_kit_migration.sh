#!/bin/bash
# Verify media_kit migration is complete
# This script checks that just_audio has been completely replaced with media_kit

echo "Verifying media_kit migration..."
echo ""

echo "1. Checking for any remaining just_audio imports:"
grep -r "just_audio" --include="*.dart" . | grep -v "audio_service_backup_just_audio.dart"
if [ $? -eq 0 ]; then
  echo "❌ FAIL: Found just_audio imports that need to be removed"
else
  echo "✅ SUCCESS: No remaining just_audio imports found"
fi
echo ""

echo "2. Checking for media_kit imports:"
grep -r "media_kit" --include="*.dart" .
if [ $? -eq 0 ]; then
  echo "✅ SUCCESS: Found media_kit imports"
else
  echo "❌ FAIL: No media_kit imports found"
fi
echo ""

echo "3. Checking for audio_utils.dart imports:"
grep -r "import '.*audio_utils.dart'" --include="*.dart" .
if [ $? -eq 0 ]; then
  echo "✅ SUCCESS: Found audio_utils.dart imports"
else
  echo "❌ FAIL: No audio_utils.dart imports found"
fi
echo ""

echo "4. Checking for MediaKit initialization:"
grep -r "MediaKit.ensureInitialized()" --include="*.dart" .
if [ $? -eq 0 ]; then
  echo "✅ SUCCESS: Found MediaKit initialization"
else
  echo "❌ FAIL: MediaKit initialization not found"
fi
echo ""

echo "5. Checking pubspec.yaml for dependencies:"
echo "media_kit dependency:"
grep -A 5 "media_kit:" pubspec.yaml
echo ""
echo "just_audio dependency (should be removed):"
grep -A 1 "just_audio:" pubspec.yaml
if [ $? -eq 0 ]; then
  echo "❌ FAIL: just_audio dependency still present in pubspec.yaml"
else
  echo "✅ SUCCESS: just_audio dependency removed from pubspec.yaml"
fi
echo ""

echo "6. Checking for Player vs AudioPlayer usage:"
echo "Player class usage (media_kit):"
grep -r "Player(" --include="*.dart" . | grep -v "audio_service_backup_just_audio.dart"
echo ""
echo "AudioPlayer class usage (should only be in compatibility layer):"
grep -r "AudioPlayer(" --include="*.dart" . | grep -v "audio_utils.dart" | grep -v "audio_service_backup_just_audio.dart"
if [ $? -eq 0 ]; then
  echo "⚠️ WARNING: Found AudioPlayer instantiations outside compatibility layer"
else
  echo "✅ SUCCESS: No direct AudioPlayer instantiations found outside compatibility layer"
fi
echo ""

echo "Migration verification complete!"
