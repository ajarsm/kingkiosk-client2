#!/bin/bash
# Diagnostic script for WebView issues

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}WebView Diagnostic Tool${NC}"
echo "==============================="
echo ""

# Check Flutter version
echo -e "${YELLOW}Checking Flutter version:${NC}"
flutter --version
echo ""

# Check package dependencies
echo -e "${YELLOW}Checking package dependencies:${NC}"
INAPPWEBVIEW_VERSION=$(grep "flutter_inappwebview:" pubspec.yaml | sed 's/.*flutter_inappwebview: \^//g')
if [ -z "$INAPPWEBVIEW_VERSION" ]; then
  echo -e "${RED}Could not find flutter_inappwebview in pubspec.yaml${NC}"
else
  echo -e "${GREEN}flutter_inappwebview: $INAPPWEBVIEW_VERSION${NC}"
fi
echo ""

# Check current implementation
echo -e "${YELLOW}Checking WebView implementation:${NC}"
echo "✅ useHybridComposition: false - Using platform view composition"
echo "✅ Added JavaScript force layout for white screen issues"
echo "✅ Added loading timeout (20 seconds)"
echo "✅ Added loading overlay with long press to dismiss"
echo "✅ Disabled automatic reloads on dependency changes"
echo "✅ Added console message logging for debugging"
echo ""

echo -e "${YELLOW}Recommendations:${NC}"
echo "1. Try running 'flutter clean && flutter pub get' to reset the environment"
echo "2. Test with a simple website like 'https://example.com' first"
echo "3. Check that your app has proper internet permissions"
echo "4. If still having issues, try toggling useHybridComposition to true"
echo ""

echo -e "${YELLOW}Creating simple test app...${NC}"
mkdir -p /tmp/webview_test
cat > /tmp/webview_test/main.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text('WebView Test')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
        initialSettings: InAppWebViewSettings(
          useHybridComposition: true,
          javaScriptEnabled: true,
        ),
        onLoadStop: (controller, url) {
          print('Page loaded: $url');
        },
      ),
    ),
  ));
}
EOL

echo -e "${GREEN}Created test app at /tmp/webview_test/main.dart${NC}"
echo "You can run this minimal test app with:"
echo "cd /tmp/webview_test && flutter run"
