#!/bin/bash

echo "Verifying all fixes for KingKiosk Client:"
echo ""

echo "1. Checking WebViewTile for blue outline removal:"
grep -n "border: Border.all(color: Colors.transparent" --include="*.dart" ./lib/app/modules/home/widgets/web_view_tile.dart
echo ""

echo "2. Checking WebViewTile for scroll settings:"
grep -n "verticalScrollBarEnabled: true" --include="*.dart" ./lib/app/modules/home/widgets/web_view_tile.dart
echo ""

echo "3. Checking WebViewTile for touch event handling:"
grep -n "touchstart" --include="*.dart" ./lib/app/modules/home/widgets/web_view_tile.dart
echo ""

echo "4. Checking for duplicate onLoadStop:"
echo "Number of onLoadStop occurrences:"
grep -c "onLoadStop" ./lib/app/modules/home/widgets/web_view_tile.dart
echo ""

echo "5. Checking audio service for notification sound:"
grep -n "notification.wav" --include="*.dart" ./lib/app/services/audio_service.dart
echo ""

echo "6. Checking for AI button:"
grep -n "buildFloatingAiButton" --include="*.dart" ./lib/app/modules/home/views/tiling_window_view.dart
echo ""

echo "Verification complete!"
