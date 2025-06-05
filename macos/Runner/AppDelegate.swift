import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    // Register the FrameCapturePlugin manually since it's not in GeneratedPluginRegistrant
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      let registrar = controller.registrar(forPlugin: "FrameCapturePlugin")
      FrameCapturePlugin.register(with: registrar)
      print("✅ FrameCapturePlugin registered successfully")
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}