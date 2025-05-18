#!/bin/zsh
# Apply necessary patches to fix plugin compatibility issues

# Create patches directory if it doesn't exist
mkdir -p patches

# Image Gallery Saver patch (fix namespace issue)
PLUGIN_PATH="/Users/raj/.pub-cache/hosted/pub.dev/image_gallery_saver-2.0.3/android/build.gradle"
if [ -f "$PLUGIN_PATH" ]; then
  echo "Patching image_gallery_saver plugin..."
  cp patches/image_gallery_saver_build.gradle "$PLUGIN_PATH"
  echo "✅ Successfully patched image_gallery_saver plugin"
else
  echo "❌ Cannot find image_gallery_saver plugin at $PLUGIN_PATH"
fi

echo "All patches have been applied. You can now build for Android."
