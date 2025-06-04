import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    // Register FrameCapturePlugin
    guard let registrar = mainFlutterWindow?.registrar(forPlugin: "FrameCapturePlugin") else {
      fatalError("Failed to get registrar for FrameCapturePlugin")
    }
    FrameCapturePlugin.register(with: registrar)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}