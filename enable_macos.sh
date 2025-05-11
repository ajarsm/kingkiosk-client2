#!/bin/bash

# Enable macOS desktop support
flutter config --enable-macos-desktop

# Create macOS platform files
flutter create --platforms=macos .

# Message
echo "macOS platform files created successfully!"
echo "To run the app on macOS, use: flutter run -d macos"