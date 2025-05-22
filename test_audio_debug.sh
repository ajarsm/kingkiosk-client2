#!/bin/bash
echo "Testing Audio Debug"
cd "$(dirname "$0")"
flutter run -d macos --verbose
