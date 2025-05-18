#!/bin/zsh
# Build and run the app on Android

# Apply patches first to ensure compatibility
echo "Applying plugin patches..."
./apply_plugin_patches.sh

# Do a thorough cleanup of the project
echo "Performing deep clean..."
flutter clean
rm -rf build/
rm -rf .dart_tool/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies

# Delete Gradle caches if needed
echo "Cleaning Gradle caches..."
rm -rf ~/.gradle/caches/modules-2/files-2.1/com.example.imagegallerysaver/ 2>/dev/null

# Get dependencies 
echo "Getting dependencies..."
flutter pub get

# Build and run on Android
echo "Building and running on Android..."
flutter run --verbose
