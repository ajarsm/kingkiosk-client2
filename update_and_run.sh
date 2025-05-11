#!/bin/bash

echo "Updating Flutter GetX Kiosk with tiling window management..."

# Make sure we're in the right directory
cd "$(dirname "$0")"

# Clean the project to remove any cached builds
echo "Cleaning project..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build for macOS
echo "Building for macOS..."
flutter build macos --debug

# Run the app
echo "Running app..."
flutter run -d macos

echo "Done!"