#!/bin/bash

# Custom build script that runs after Flutter build to copy and sign TensorFlow Lite libraries
# This script should be called from Xcode build phases

echo "🔧 Running custom TensorFlow Lite library integration..."

# Set up environment variables for the copy script
export SRCROOT="${SRCROOT:-$PROJECT_DIR}"
export BUILT_PRODUCTS_DIR="${BUILT_PRODUCTS_DIR:-$BUILD_DIR/Build/Products/$CONFIGURATION}"
export PRODUCT_NAME="${PRODUCT_NAME:-king_kiosk}"

# Call our TensorFlow Lite library copy script
if [ -f "$SRCROOT/copy_tflite_libs.sh" ]; then
    echo "📦 Copying and signing TensorFlow Lite libraries..."
    bash "$SRCROOT/copy_tflite_libs.sh"
else
    echo "⚠️ copy_tflite_libs.sh not found at $SRCROOT"
fi

echo "✅ Custom build script complete"
