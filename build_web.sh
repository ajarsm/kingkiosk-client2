#!/bin/bash

# Web Build Script for KingKiosk with Secure Storage Support
# This script builds the web version with proper secure storage configurations

echo "🌐 Building KingKiosk for Web Platform..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web with optimizations
echo "🏗️ Building for web (release mode)..."
flutter build web \
  --web-renderer canvaskit \
  --release \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  --dart-define=FLUTTER_WEB_AUTO_DETECT=true

echo "✅ Web build completed!"
echo ""
echo "📋 Important Notes for Web Deployment:"
echo "   • Ensure HTTPS is enabled for secure storage"
echo "   • Web secure storage uses browser localStorage"
echo "   • Consider additional encryption for sensitive data"
echo "   • Test on target browsers for compatibility"
echo ""
echo "📁 Build output: build/web/"
echo "🚀 Deploy the build/web/ folder to your web server"
