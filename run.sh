#!/bin/bash

echo "Cleaning old build artifacts..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Building for macOS..."
flutter build macos --debug

echo "Running on macOS..."
flutter run -d macos

echo "Done!"