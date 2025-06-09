#!/bin/bash

# Script to reset iOS permissions for King Kiosk app
BUNDLE_ID="com.example.flutterGetxKiosk"

echo "🔧 Resetting iOS permissions for King Kiosk ($BUNDLE_ID)..."

# Check if running on physical device or simulator
if [ "$1" == "device" ]; then
    echo "📱 Physical device detected - please manually reset permissions in iOS Settings:"
    echo "   1. Go to Settings > General > Transfer or Reset iPhone > Reset > Reset Location & Privacy"
    echo "   2. Or delete the app and reinstall it"
    echo "   3. Or go to Settings > Privacy & Security > Camera/Microphone and remove the app if listed"
else
    echo "🖥️  Simulator mode - attempting to reset permissions..."
    
    # Boot a simulator if none are running
    BOOTED_DEVICE=$(xcrun simctl list devices | grep "Booted" | head -1 | sed 's/.*(\([^)]*\)).*/\1/')
    
    if [ -z "$BOOTED_DEVICE" ]; then
        echo "📲 No simulator running, booting iPhone 16 Pro..."
        DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro (" | head -1 | grep -o '([A-F0-9-]*)')
        DEVICE_ID=${DEVICE_ID//[()]/}
        if [ -n "$DEVICE_ID" ]; then
            xcrun simctl boot "$DEVICE_ID"
            BOOTED_DEVICE="$DEVICE_ID"
            sleep 5
        else
            echo "❌ Could not find iPhone 16 Pro simulator"
            exit 1
        fi
    else
        echo "📲 Using booted simulator: $BOOTED_DEVICE"
    fi
    
    # Reset privacy and location warnings for this app
    echo "🔄 Resetting privacy permissions..."
    xcrun simctl privacy "$BOOTED_DEVICE" reset all "$BUNDLE_ID" 2>/dev/null || true
    
    # Reset specific permissions
    echo "📷 Resetting camera permissions..."
    xcrun simctl privacy "$BOOTED_DEVICE" reset camera "$BUNDLE_ID" 2>/dev/null || true
    
    echo "🎤 Resetting microphone permissions..."
    xcrun simctl privacy "$BOOTED_DEVICE" reset microphone "$BUNDLE_ID" 2>/dev/null || true
    
    echo "📍 Resetting location permissions..."
    xcrun simctl privacy "$BOOTED_DEVICE" reset location "$BUNDLE_ID" 2>/dev/null || true
    
    # Uninstall the app if it exists
    echo "🗑️  Uninstalling app if present..."
    xcrun simctl uninstall "$BOOTED_DEVICE" "$BUNDLE_ID" 2>/dev/null || true
    
    echo "✅ Reset complete!"
fi

echo ""
echo "📋 Next steps:"
echo "   1. Run: flutter clean"
echo "   2. Run: flutter pub get"
echo "   3. Run: flutter run"
echo "   4. Test camera/mic permissions in the app"
echo ""
echo "🐛 If issues persist, try:"
echo "   - Reset all simulator content: Device > Erase All Content and Settings"
echo "   - Use a different simulator device"
echo "   - Test on a physical device"
