#!/bin/bash
# Test the enhanced WebViewTile implementation with SSL certificate handling and error management

echo "📱 Testing enhanced WebViewTile implementation..."

# Backup original file
echo "📂 Creating backup of original WebViewTile implementation..."
cp lib/app/modules/home/widgets/web_view_tile.dart lib/app/modules/home/widgets/web_view_tile.dart.bak

# Replace with enhanced version
echo "🔄 Replacing with enhanced WebViewTile implementation..."
mv lib/app/modules/home/widgets/web_view_tile_enhanced.dart lib/app/modules/home/widgets/web_view_tile.dart

# Run the app to test
echo "🚀 Running app to test WebViewTile enhancements..."
flutter run 

# Instructions for reverting changes if needed
echo ""
echo "ℹ️  To revert changes, run the following commands:"
echo "mv lib/app/modules/home/widgets/web_view_tile.dart.bak lib/app/modules/home/widgets/web_view_tile.dart"
