// Add this code to your WebViewTile and YouTubePlayerTile implementations:

// For WebViewTile: Add this in the _createWebView method, after the shouldOverrideUrlLoading handler:
onReceivedServerTrustAuthRequest: (controller, challenge) async {
  print('🔒 WebViewTile - Received SSL certificate challenge, proceeding anyway');
  return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
},

// For YouTubePlayerTile: Add this in the InAppWebView constructor, after the onConsoleMessage handler:
onReceivedServerTrustAuthRequest: (controller, challenge) async {
  print('🔒 YouTube player - Received SSL certificate challenge, proceeding anyway');
  return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
},
