import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register FrameCapturePlugin
    guard let registrar = self.registrar(forPlugin: "FrameCapturePlugin") else {
      fatalError("Failed to get registrar for FrameCapturePlugin")
    }
    FrameCapturePlugin.register(with: registrar)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
