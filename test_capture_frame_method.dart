import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

/// Test script to verify if captureFrame() method is available
/// This will help us debug the frame capture issue
Future<void> main() async {
  print('🔍 Testing MediaStreamTrack.captureFrame() method availability...');
  
  try {
    // Test 1: Check if we can get user media
    print('\n📋 Test 1: Getting user media...');
    
    final mediaConstraints = {
      'audio': false,
      'video': {
        'width': {'ideal': 640},
        'height': {'ideal': 480},
        'facingMode': 'user',
      }
    };

    final stream = await webrtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
    print('✅ Successfully got media stream');
    
    // Test 2: Get video tracks
    print('\n📋 Test 2: Getting video tracks...');
    final videoTracks = stream.getVideoTracks();
    
    if (videoTracks.isEmpty) {
      print('❌ No video tracks found');
      return;
    }
    
    print('✅ Found ${videoTracks.length} video track(s)');
    final videoTrack = videoTracks.first;
    print('   Track ID: ${videoTrack.id}');
    print('   Track kind: ${videoTrack.kind}');
    print('   Track enabled: ${videoTrack.enabled}');
    
    // Test 3: Check if captureFrame method exists
    print('\n📋 Test 3: Testing captureFrame() method...');
    
    try {
      // This is the critical test - does the method exist and work?
      final frameBuffer = await videoTrack.captureFrame();
      final frameBytes = frameBuffer.asUint8List();
      
      print('✅ SUCCESS: captureFrame() method works!');
      print('   Frame buffer size: ${frameBytes.length} bytes');
      print('   Frame data type: ${frameBytes.runtimeType}');
      
      // Basic validation of frame data
      if (frameBytes.length > 0) {
        print('   Frame data looks valid (non-empty)');
        
        // Check if it looks like image data (should have reasonable size)
        if (frameBytes.length > 1000) {
          print('   Frame size suggests real image data');
        } else {
          print('   ⚠️ Frame size is very small, might be dummy data');
        }
      } else {
        print('   ❌ Frame data is empty');
      }
      
    } catch (e) {
      print('❌ FAILED: captureFrame() method error: $e');
      print('   Error type: ${e.runtimeType}');
      
      // Check if it's a "method not found" type error
      if (e.toString().contains('NoSuchMethodError') || 
          e.toString().contains('method not found') ||
          e.toString().contains('captureFrame')) {
        print('   🔍 This suggests captureFrame() method is not available in this version');
      } else {
        print('   🔍 This suggests captureFrame() exists but has runtime issues');
      }
    }
    
    // Test 4: Alternative approach - check method availability using reflection
    print('\n📋 Test 4: Method availability check...');
    
    try {
      // Try to access the method through reflection-like approach
      final hasMethod = videoTrack.toString().contains('captureFrame');
      print('   Track toString contains captureFrame: $hasMethod');
    } catch (e) {
      print('   Method reflection test failed: $e');
    }
    
    // Clean up
    print('\n🧹 Cleaning up...');
    stream.getTracks().forEach((track) => track.stop());
    stream.dispose();
    print('✅ Cleanup complete');
    
  } catch (e) {
    print('❌ Overall test failed: $e');
    print('   Error type: ${e.runtimeType}');
  }
  
  print('\n🎯 Test Summary:');
  print('   - If captureFrame() worked: The method exists and your implementation should work');
  print('   - If captureFrame() failed: We need to implement an alternative approach');
  print('   - This test helps identify the exact cause of the frame capture issue');
}
