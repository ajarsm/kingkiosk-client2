import Cocoa
import FlutterMacOS

func RegisterCustomPlugins(registry: FlutterPluginRegistry) {
  let registrar = registry.registrar(forPlugin: "FrameCapturePlugin")
  FrameCapturePlugin.register(with: registrar)
  print("✅ CustomPluginRegistrant: FrameCapturePlugin registered")
}