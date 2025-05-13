#!/bin/bash

# Run Flutter GetX Kiosk with proper settings
# This script ensures proper initialization and runs with optimized settings

echo "Starting Flutter GetX Kiosk..."

# Ensure GetStorage is properly initialized before launch
echo "Cleaning Flutter build cache..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Running app with optimized settings..."
flutter run --release -d macos

# If you want to run in debug mode instead, uncomment this line:
# flutter run -d macos

echo "Done!"
