import '../../../services/window_manager_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebWindowController extends KioskWindowController {
  @override
  final String windowName;
  @override
  KioskWindowType get windowType => KioskWindowType.web;
  final InAppWebViewController webViewController;
  final void Function()? onClose;

  WebWindowController({
    required this.windowName,
    required this.webViewController,
    this.onClose,
  });

  @override
  void handleCommand(String action, Map<String, dynamic>? payload) async {
    switch (action) {
      case 'refresh':
        await webViewController.reload();
        break;
      case 'close':
        disposeWindow();
        break;
      case 'restart':
        final url = await webViewController.getUrl();
        if (url != null) await webViewController.loadUrl(urlRequest: URLRequest(url: url));
        break;
      case 'evaljs':
        if (payload != null && payload['js'] is String) {
          await webViewController.evaluateJavascript(source: payload['js']);
        }
        break;
      case 'loadurl':
        if (payload != null && payload['url'] is String) {
          final urlString = payload['url'] as String;
          Uri? uri;
          try {
            uri = Uri.tryParse(urlString);
          } catch (e) {
            print('Invalid URL in loadurl command: $urlString');
            break;
          }
          if (uri == null || (!uri.hasScheme && !uri.isAbsolute)) {
            print('Invalid URL in loadurl command: $urlString');
            break;
          }
          await webViewController.loadUrl(urlRequest: URLRequest(url: WebUri(uri.toString())));
        }
        break;
      default:
        print('Unknown web command: $action');
    }
  }

  @override
  void disposeWindow() {
    webViewController.stopLoading();
    if (onClose != null) onClose!();
  }
}
