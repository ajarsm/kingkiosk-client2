#!/bin/bash

# Clear flutter cache and get dependencies
echo "Getting dependencies..."
flutter pub get

# Run the app on macOS
echo "Running app on macOS..."
flutter run -d macos

echo "Done!"