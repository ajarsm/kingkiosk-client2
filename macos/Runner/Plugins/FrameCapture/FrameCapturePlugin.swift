import FlutterMacOS
import Foundation
import Metal
import MetalKit
import AVFoundation

public class FrameCapturePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.kingkiosk.frame_capture", binaryMessenger: registrar.messenger)
    let instance = FrameCapturePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "captureFrame":
      guard let args = call.arguments as? [String: Any],
            let rendererId = args["rendererId"] as? Int,
            let width = args["width"] as? Int,
            let height = args["height"] as? Int else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
        return
      }
      
      if let frameData = captureFrameFromTexture(rendererId: rendererId, width: width, height: height) {
        result(frameData)
      } else {
        result(FlutterError(code: "CAPTURE_FAILED", message: "Failed to capture frame from texture", details: nil))
      }
      
    case "getRendererTextureId":
      guard let args = call.arguments as? [String: Any],
            let renderer = args["renderer"] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing renderer argument", details: nil))
        return
      }
      
      let textureId = getRendererTextureId(renderer: renderer)
      if textureId >= 0 {
        result(textureId)
      } else {
        result(FlutterError(code: "NO_TEXTURE_ID", message: "Unable to get texture ID from renderer", details: nil))
      }
      
    case "isSupported":
      result(isFrameCaptureSupported())
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func captureFrameFromTexture(rendererId: Int, width: Int, height: Int) -> FlutterStandardTypedData? {
    // Note: In a real implementation, you would:
    // 1. Get the Metal texture from the WebRTC renderer using rendererId
    // 2. Create a Metal command buffer and encoder
    // 3. Copy the texture data to a CPU-accessible buffer
    // 4. Convert from GPU format (usually BGRA) to RGBA
    
    // For now, create dummy RGBA data as placeholder
    let dataSize = width * height * 4
    var frameData = Data(count: dataSize)
    
    frameData.withUnsafeMutableBytes { bytes in
      let buffer = bytes.bindMemory(to: UInt8.self)
      
      // Fill with dummy pattern for testing
      for i in stride(from: 0, to: dataSize, by: 4) {
        buffer[i] = 128     // R
        buffer[i + 1] = 64  // G
        buffer[i + 2] = 192 // B
        buffer[i + 3] = 255 // A
      }
    }
    
    return FlutterStandardTypedData(bytes: frameData)
  }
  
  private func getRendererTextureId(renderer: Any) -> Int {
    // Note: In a real implementation, you would extract the texture ID from the WebRTC renderer
    // This requires accessing the flutter_webrtc plugin's internal texture management
    
    // For now, return a dummy texture ID
    // In production, this would involve:
    // 1. Getting the renderer's internal Metal texture handle
    // 2. Extracting the texture ID or handle
    // 3. Returning the ID for use in captureFrameFromTexture
    
    return 1 // Dummy texture ID
  }
  
  private func isFrameCaptureSupported() -> Bool {
    // Check if Metal is available
    return MTLCreateSystemDefaultDevice() != nil
  }
}
