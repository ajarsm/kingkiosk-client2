// WebRTC Texture Bridge Service
// This service bridges between flutter_webrtc and the native frame capture plugins
// to access real GPU texture handles instead of generating test data

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

class WebRTCTextureBridge extends GetxService {
  static const MethodChannel _channel = MethodChannel('com.kingkiosk.frame_capture');
  
  // Map to store renderer to texture ID mappings
  final Map<int, RTCVideoRenderer> _rendererMap = {};
  final Map<int, StreamSubscription> _rendererSubscriptions = {};
  
  // Observable texture information
  final RxMap<int, TextureInfo> _textureInfoMap = <int, TextureInfo>{}.obs;
  
  @override
  void onInit() {
    super.onInit();
    print('🔗 WebRTC Texture Bridge initialized');
  }
  
  @override
  void onClose() {
    // Clean up subscriptions
    for (var subscription in _rendererSubscriptions.values) {
      subscription.cancel();
    }
    _rendererSubscriptions.clear();
    _rendererMap.clear();
    super.onClose();
  }
  
  /// Register a WebRTC renderer and get its texture ID
  int registerRenderer(RTCVideoRenderer renderer) {
    final rendererId = renderer.hashCode;
    _rendererMap[rendererId] = renderer;
      // Monitor renderer for texture changes - WebRTC renderers don't have onResize stream
    // We'll update texture info manually when needed
    
    // Initial texture info update
    _updateTextureInfo(rendererId, renderer);
    
    print('📱 Registered WebRTC renderer $rendererId with texture ID: ${renderer.textureId}');
    
    return rendererId;
  }
  
  /// Unregister a WebRTC renderer
  void unregisterRenderer(int rendererId) {
    _rendererSubscriptions[rendererId]?.cancel();
    _rendererSubscriptions.remove(rendererId);
    _rendererMap.remove(rendererId);
    _textureInfoMap.remove(rendererId);
    
    print('🗑️ Unregistered WebRTC renderer $rendererId');
  }
  
  /// Get texture information for a renderer
  TextureInfo? getTextureInfo(int rendererId) {
    return _textureInfoMap[rendererId];
  }
  
  /// Get the actual flutter_webrtc texture ID for a renderer
  int? getWebRTCTextureId(int rendererId) {
    final renderer = _rendererMap[rendererId];
    return renderer?.textureId;
  }
  
  /// Get the WebRTC renderer for a given renderer ID
  RTCVideoRenderer? getRenderer(int rendererId) {
    return _rendererMap[rendererId];
  }
  
  /// Attempt to get the native platform texture handle
  Future<int?> getNativePlatformTextureId(int rendererId) async {
    try {
      final webrtcTextureId = getWebRTCTextureId(rendererId);
      if (webrtcTextureId == null) {
        print('⚠️ No WebRTC texture ID for renderer $rendererId');
        return null;
      }
      
      // Call native method to extract platform-specific texture handle
      final result = await _channel.invokeMethod<int>('getPlatformTextureId', {
        'webrtcTextureId': webrtcTextureId,
        'rendererId': rendererId,
      });
      
      if (result != null && result > 0) {
        print('✅ Got native platform texture ID: $result for WebRTC texture: $webrtcTextureId');
        return result;
      }
      
      print('⚠️ Could not get native platform texture ID for WebRTC texture: $webrtcTextureId');
      return null;
      
    } catch (e) {
      print('❌ Error getting native platform texture ID: $e');
      return null;
    }
  }
  
  /// Capture a frame from a WebRTC renderer
  Future<Uint8List?> captureFrame(int rendererId, int width, int height) async {
    try {
      final renderer = _rendererMap[rendererId];
      if (renderer == null) {
        print('❌ No renderer found for ID: $rendererId');
        return null;
      }
      
      // Get the native platform texture ID
      final platformTextureId = await getNativePlatformTextureId(rendererId);
      if (platformTextureId == null) {
        print('⚠️ No platform texture ID available for renderer $rendererId');
        return null;
      }
      
      // Use the native frame capture with the platform texture ID
      final frameData = await _channel.invokeMethod<Uint8List>('captureFrameFromTexture', {
        'textureId': platformTextureId,
        'width': width,
        'height': height,
        'rendererId': rendererId,
      });
      
      if (frameData != null) {
        print('✅ Successfully captured frame from WebRTC renderer $rendererId: ${frameData.length} bytes');
        return frameData;
      }
      
      print('⚠️ Frame capture returned null for renderer $rendererId');
      return null;
      
    } catch (e) {
      print('❌ Error capturing frame from WebRTC renderer: $e');
      return null;
    }
  }
    /// Update texture information for a renderer
  void _updateTextureInfo(int rendererId, RTCVideoRenderer renderer) {
    final textureInfo = TextureInfo(
      textureId: renderer.textureId,
      width: renderer.value.width.toInt(),
      height: renderer.value.height.toInt(),
      rotation: renderer.value.rotation,
      rendererId: rendererId,
    );
    
    _textureInfoMap[rendererId] = textureInfo;
    
    print('🔄 Updated texture info for renderer $rendererId: ${textureInfo.width}x${textureInfo.height} (texture: ${textureInfo.textureId})');
  }
  
  /// Get all registered renderer IDs
  List<int> get registeredRendererIds => _rendererMap.keys.toList();
  
  /// Get texture info for all registered renderers
  Map<int, TextureInfo> get allTextureInfo => Map.from(_textureInfoMap);
}

/// Information about a WebRTC texture
class TextureInfo {
  final int? textureId;
  final int width;
  final int height;
  final int rotation;
  final int rendererId;
  
  const TextureInfo({
    required this.textureId,
    required this.width,
    required this.height,
    required this.rotation,
    required this.rendererId,
  });
  
  @override
  String toString() {
    return 'TextureInfo(textureId: $textureId, size: ${width}x$height, rotation: $rotation, rendererId: $rendererId)';
  }
}
