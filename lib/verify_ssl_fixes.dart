import 'dart:io';

void main() {
  // Define file paths
  final webViewTilePath = 'lib/app/modules/home/widgets/web_view_tile.dart';
  final youtubePlayerTilePath =
      'lib/app/modules/home/widgets/youtube_player_tile.dart';

  // Read files
  final webViewTileContent = File(webViewTilePath).readAsStringSync();
  final youtubePlayerTileContent =
      File(youtubePlayerTilePath).readAsStringSync();

  // Test for absence of problematic patterns
  bool allowsInsecureConnectionsPresent =
      webViewTileContent.contains('allowsInsecureConnections: true');
  bool internetDisconnectedPresent = youtubePlayerTileContent
      .contains('WebResourceErrorType.INTERNET_DISCONNECTED');
  bool connectTypePresent =
      youtubePlayerTileContent.contains('WebResourceErrorType.CONNECT');

  // Test for presence of required patterns
  bool serverTrustHandlerInWebView =
      webViewTileContent.contains('onReceivedServerTrustAuthRequest');
  bool serverTrustHandlerInYouTube =
      youtubePlayerTileContent.contains('onReceivedServerTrustAuthRequest');

  // Print results
  print('===== WebView SSL Certificate Handling Check =====');
  print(
      '1. allowsInsecureConnections removed: ${!allowsInsecureConnectionsPresent ? '✅' : '❌'}');
  print(
      '2. WebResourceErrorType.INTERNET_DISCONNECTED removed: ${!internetDisconnectedPresent ? '✅' : '❌'}');
  print(
      '3. WebResourceErrorType.CONNECT removed: ${!connectTypePresent ? '✅' : '❌'}');
  print(
      '4. ServerTrustAuthRequest handler in WebViewTile: ${serverTrustHandlerInWebView ? '✅' : '❌'}');
  print(
      '5. ServerTrustAuthRequest handler in YouTubePlayerTile: ${serverTrustHandlerInYouTube ? '✅' : '❌'}');

  // Exit with appropriate code
  if (!allowsInsecureConnectionsPresent &&
      !internetDisconnectedPresent &&
      !connectTypePresent &&
      serverTrustHandlerInWebView &&
      serverTrustHandlerInYouTube) {
    print('\nAll SSL certificate handling fixes verified! ✅');
    exit(0);
  } else {
    print('\nSome SSL certificate handling fixes are missing! ❌');
    exit(1);
  }
}
