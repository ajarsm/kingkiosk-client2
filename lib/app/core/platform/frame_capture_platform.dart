import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Platform interface for WebRTC frame capture
class FrameCapturePlatform {
  static const MethodChannel _channel = MethodChannel('com.kingkiosk.frame_capture');
  
  /// Capture a frame from the specified WebRTC video renderer
  /// 
  /// [rendererId] - The ID of the WebRTC video renderer (texture ID)
  /// [width] - Desired output width
  /// [height] - Desired output height
  /// 
  /// Returns raw RGBA bytes or null if capture fails
  static Future<Uint8List?> captureFrame({
    required int rendererId,
    required int width,
    required int height,
  }) async {
    try {
      final result = await _channel.invokeMethod('captureFrame', {
        'rendererId': rendererId,
        'width': width,
        'height': height,
      });
      
      if (result is Uint8List) {
        return result;
      }
      return null;
    } on PlatformException catch (e) {
      print('Platform exception during frame capture: ${e.message}');
      return null;
    } catch (e) {
      print('Error capturing frame: $e');
      return null;
    }
  }
  
  /// Get the texture ID from a WebRTC video renderer
  /// This is a helper method that extracts the renderer's texture ID
  static Future<int?> getRendererTextureId(dynamic renderer) async {
    try {
      final result = await _channel.invokeMethod('getRendererTextureId', {
        'renderer': renderer,
      });
      
      if (result is int) {
        return result;
      }
      return null;
    } on PlatformException catch (e) {
      print('Platform exception getting texture ID: ${e.message}');
      return null;
    } catch (e) {
      print('Error getting renderer texture ID: $e');
      return null;
    }
  }
  
  /// Check if frame capture is supported on this platform
  static Future<bool> isSupported() async {
    try {
      final result = await _channel.invokeMethod('isSupported');
      return result as bool? ?? false;
    } catch (e) {
      print('Error checking frame capture support: $e');
      return false;
    }
  }
}
