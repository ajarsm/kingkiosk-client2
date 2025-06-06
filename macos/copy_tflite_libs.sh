#!/bin/bash

# Script to copy TensorFlow Lite libraries to the macOS app bundle
# This ensures the libraries are available at runtime and survive flutter clean

echo "Copying TensorFlow Lite libraries to app bundle..."

# Source libraries in the Runner/Resources directory
SOURCE_DIR="$SRCROOT/Runner/Resources"
TARGET_DIR="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Resources"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Copy libraries and sign them for macOS compatibility
if [ -f "$SOURCE_DIR/libtensorflowlite_c.dylib" ]; then
    cp "$SOURCE_DIR/libtensorflowlite_c.dylib" "$TARGET_DIR/"
    cp "$SOURCE_DIR/libtensorflowlite_c.dylib" "$TARGET_DIR/libtensorflowlite_c-mac.dylib"
    
    # Sign the copied libraries (ad-hoc signing for development)
    codesign --force --sign - "$TARGET_DIR/libtensorflowlite_c.dylib" 2>/dev/null || echo "⚠️ Could not sign libtensorflowlite_c.dylib"
    codesign --force --sign - "$TARGET_DIR/libtensorflowlite_c-mac.dylib" 2>/dev/null || echo "⚠️ Could not sign libtensorflowlite_c-mac.dylib"
    
    echo "✅ Copied and signed libtensorflowlite_c.dylib and libtensorflowlite_c-mac.dylib"
else
    echo "❌ libtensorflowlite_c.dylib not found in $SOURCE_DIR"
fi

if [ -f "$SOURCE_DIR/libtensorflowlite_metal_delegate.dylib" ]; then
    cp "$SOURCE_DIR/libtensorflowlite_metal_delegate.dylib" "$TARGET_DIR/"
    cp "$SOURCE_DIR/libtensorflowlite_metal_delegate.dylib" "$TARGET_DIR/libtensorflowlite_metal_delegate-mac.dylib"
    
    # Sign the copied libraries (ad-hoc signing for development)
    codesign --force --sign - "$TARGET_DIR/libtensorflowlite_metal_delegate.dylib" 2>/dev/null || echo "⚠️ Could not sign libtensorflowlite_metal_delegate.dylib"
    codesign --force --sign - "$TARGET_DIR/libtensorflowlite_metal_delegate-mac.dylib" 2>/dev/null || echo "⚠️ Could not sign libtensorflowlite_metal_delegate-mac.dylib"
    
    echo "✅ Copied and signed libtensorflowlite_metal_delegate.dylib and libtensorflowlite_metal_delegate-mac.dylib"
else
    echo "❌ libtensorflowlite_metal_delegate.dylib not found in $SOURCE_DIR"
fi

# Also copy to the macOS-style Frameworks directory for compatibility
FRAMEWORKS_DIR="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Frameworks"
mkdir -p "$FRAMEWORKS_DIR"

if [ -f "$SOURCE_DIR/libtensorflowlite_c.dylib" ]; then
    cp "$SOURCE_DIR/libtensorflowlite_c.dylib" "$FRAMEWORKS_DIR/"
    cp "$SOURCE_DIR/libtensorflowlite_c.dylib" "$FRAMEWORKS_DIR/libtensorflowlite_c-mac.dylib"
    
    # Sign the libraries in Frameworks directory too
    codesign --force --sign - "$FRAMEWORKS_DIR/libtensorflowlite_c.dylib" 2>/dev/null || echo "⚠️ Could not sign libtensorflowlite_c.dylib in Frameworks"
    codesign --force --sign - "$FRAMEWORKS_DIR/libtensorflowlite_c-mac.dylib" 2>/dev/null || echo "⚠️ Could not sign libtensorflowlite_c-mac.dylib in Frameworks"
    
    echo "✅ Also copied and signed libtensorflowlite_c.dylib and libtensorflowlite_c-mac.dylib to Frameworks"
fi

if [ -f "$SOURCE_DIR/libtensorflowlite_metal_delegate.dylib" ]; then
    cp "$SOURCE_DIR/libtensorflowlite_metal_delegate.dylib" "$FRAMEWORKS_DIR/"
    cp "$SOURCE_DIR/libtensorflowlite_metal_delegate.dylib" "$FRAMEWORKS_DIR/libtensorflowlite_metal_delegate-mac.dylib"
    
    # Sign the libraries in Frameworks directory too
    codesign --force --sign - "$FRAMEWORKS_DIR/libtensorflowlite_metal_delegate.dylib" 2>/dev/null || echo "⚠️ Could not sign libtensorflowlite_metal_delegate.dylib in Frameworks"
    codesign --force --sign - "$FRAMEWORKS_DIR/libtensorflowlite_metal_delegate-mac.dylib" 2>/dev/null || echo "⚠️ Could not sign libtensorflowlite_metal_delegate-mac.dylib in Frameworks"
    
    echo "✅ Also copied and signed libtensorflowlite_metal_delegate.dylib and libtensorflowlite_metal_delegate-mac.dylib to Frameworks"
fi

echo "TensorFlow Lite library copy complete"
