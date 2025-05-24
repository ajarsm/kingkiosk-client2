# SSL Certificate Handling Test Script
# This script tests the changes made to fix SSL certificate handling in WebView components

echo "Running SSL certificate handling verification..."
echo "================================================"

# Check for both pattern removals
echo "1. Checking for fixed error types in YouTubePlayerTile..."
# Should have removed WebResourceErrorType.INTERNET_DISCONNECTED and WebResourceErrorType.CONNECT 
grep -n "WebResourceErrorType.INTERNET_DISCONNECTED" lib/app/modules/home/widgets/youtube_player_tile.dart || echo "✅ INTERNET_DISCONNECTED reference removed"
grep -n "WebResourceErrorType.CONNECT" lib/app/modules/home/widgets/youtube_player_tile.dart || echo "✅ CONNECT reference removed"

echo ""
echo "2. Don't use allowsInsecureConnections in the InAppWebViewSettings"
grep -n "allowsInsecureConnections" lib/app/modules/home/widgets/web_view_tile.dart || echo "✅ allowsInsecureConnections removed"

echo ""
echo "3. Verify serverTrustAuthRequest handlers..."
grep -n "onReceivedServerTrustAuthRequest" lib/app/modules/home/widgets/web_view_tile.dart
grep -n "onReceivedServerTrustAuthRequest" lib/app/modules/home/widgets/youtube_player_tile.dart

echo ""
echo "4. Verify both files compile without errors..."
cd lib/app/modules/home/widgets
dart analyze web_view_tile.dart
dart analyze youtube_player_tile.dart

echo ""
echo "SSL Certificate Handling Test Complete!"
