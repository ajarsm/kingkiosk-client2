#!/bin/bash

# Enhanced flutter clean script that automatically restores TensorFlow Lite libraries
# This ensures the libraries are available after clean operations

echo "🧹 Starting enhanced Flutter clean with library restoration..."

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Step 1: Run flutter clean
echo "1️⃣ Running flutter clean..."
flutter clean

# Step 2: Restore TensorFlow Lite libraries
echo "2️⃣ Restoring TensorFlow Lite libraries..."
if [ -f "$SCRIPT_DIR/restore_libraries.sh" ]; then
    "$SCRIPT_DIR/restore_libraries.sh"
else
    echo "⚠️ restore_libraries.sh not found, manual library restoration may be needed"
fi

# Step 3: Make sure the copy script is executable
echo "3️⃣ Ensuring build scripts are executable..."
if [ -f "$SCRIPT_DIR/macos/copy_tflite_libs.sh" ]; then
    chmod +x "$SCRIPT_DIR/macos/copy_tflite_libs.sh"
    echo "✅ Made copy_tflite_libs.sh executable"
fi

# Step 4: Run flutter pub get to restore dependencies
echo "4️⃣ Restoring Flutter dependencies..."
flutter pub get

echo "🎉 Enhanced Flutter clean complete with library restoration!"
echo ""
echo "Next steps:"
echo "  • Run: flutter run -d macos"
echo "  • Or: flutter build macos"
echo ""
echo "📋 What was restored:"
echo "  ✅ Flutter dependencies (pub get)"
echo "  ✅ TensorFlow Lite C library"
echo "  ✅ TensorFlow Lite Metal delegate library"
echo "  ✅ Build script permissions"
