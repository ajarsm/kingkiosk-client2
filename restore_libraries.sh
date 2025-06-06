#!/bin/bash

# Script to restore TensorFlow Lite libraries after flutter clean
# This ensures the libraries are available after clean operations

echo "🔧 Restoring TensorFlow Lite libraries after clean..."

# Source libraries (in project root)
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
SOURCE_LIBTFLITE_C="$PROJECT_ROOT/libtensorflowlite_c.dylib"
SOURCE_LIBTFLITE_METAL="$PROJECT_ROOT/libtensorflowlite_metal_delegate.dylib"

# Target directory (macOS Runner Resources)
TARGET_DIR="$PROJECT_ROOT/macos/Runner/Resources"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Copy libtensorflowlite_c.dylib
if [ -f "$SOURCE_LIBTFLITE_C" ]; then
    cp "$SOURCE_LIBTFLITE_C" "$TARGET_DIR/"
    cp "$SOURCE_LIBTFLITE_C" "$TARGET_DIR/libtensorflowlite_c-mac.dylib"
    echo "✅ Restored libtensorflowlite_c.dylib and libtensorflowlite_c-mac.dylib"
else
    echo "❌ Source libtensorflowlite_c.dylib not found at: $SOURCE_LIBTFLITE_C"
fi

# Copy libtensorflowlite_metal_delegate.dylib
if [ -f "$SOURCE_LIBTFLITE_METAL" ]; then
    cp "$SOURCE_LIBTFLITE_METAL" "$TARGET_DIR/"
    cp "$SOURCE_LIBTFLITE_METAL" "$TARGET_DIR/libtensorflowlite_metal_delegate-mac.dylib"
    echo "✅ Restored libtensorflowlite_metal_delegate.dylib and libtensorflowlite_metal_delegate-mac.dylib"
else
    echo "❌ Source libtensorflowlite_metal_delegate.dylib not found at: $SOURCE_LIBTFLITE_METAL"
fi

# Make the copy script executable and integrate it into build
COPY_SCRIPT="$PROJECT_ROOT/macos/copy_tflite_libs.sh"
if [ -f "$COPY_SCRIPT" ]; then
    chmod +x "$COPY_SCRIPT"
    echo "✅ Made copy_tflite_libs.sh executable"
fi

echo "🎉 TensorFlow Lite library restoration complete"
echo "💡 Run this script after 'flutter clean' to restore native libraries"
