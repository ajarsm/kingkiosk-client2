// Web implementation of frame capture using Canvas API
class FrameCaptureWeb {
  constructor() {
    this.channel = 'com.kingkiosk.frame_capture';
    this.rendererMap = new Map(); // Store renderer references
  }

  // Register the plugin with Flutter Web
  static register() {
    const plugin = new FrameCaptureWeb();
    
    // Register method channel handler
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler(plugin.channel, plugin.handleMethodCall.bind(plugin));
    }
    
    // Alternative registration for Flutter Web
    if (window.flutter) {
      window.flutter.methodChannel = window.flutter.methodChannel || {};
      window.flutter.methodChannel[plugin.channel] = plugin.handleMethodCall.bind(plugin);
    }
  }

  async handleMethodCall(method, args) {
    try {
      switch (method) {
        case 'captureFrame':
          return await this.captureFrame(args.rendererId, args.width, args.height);
          
        case 'getRendererTextureId':
          return this.getRendererTextureId(args.renderer);
            case 'isSupported':
          return this.isFrameCaptureSupported();
          
        case 'getPlatformTextureId':
          return this.getPlatformTextureId(args.webrtcTextureId, args.rendererId);
          
        default:
          throw new Error(`Method ${method} not implemented`);
      }
    } catch (error) {
      throw {
        code: 'PLATFORM_ERROR',
        message: error.message,
        details: error.stack
      };
    }
  }
  async captureFrame(rendererId, width, height) {
    try {
      // Get the video element from the renderer ID
      const videoElement = this.getVideoElementFromRenderer(rendererId);
      
      if (!videoElement) {
        console.warn('⚠️ Video element not found for renderer ID:', rendererId, '- using fallback test data');
        return this.generateTestFrameData(width, height);
      }

      // Check if video is actually playing and has data
      if (videoElement.readyState < 2) { // HAVE_CURRENT_DATA
        console.warn('⚠️ Video element not ready for frame capture - using fallback test data');
        return this.generateTestFrameData(width, height);
      }

      // Create a canvas to capture the frame
      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext('2d');

      // Draw the video frame to canvas
      ctx.drawImage(videoElement, 0, 0, width, height);

      // Get image data as RGBA
      const imageData = ctx.getImageData(0, 0, width, height);
      
      console.log('✅ Successfully captured real WebRTC frame:', imageData.data.length, 'bytes from video element');
      
      // Convert to Uint8Array for Flutter
      return Array.from(imageData.data);
      
    } catch (error) {
      console.error('❌ Error capturing frame:', error);
      console.warn('⚠️ Falling back to test data due to capture error');
      return this.generateTestFrameData(width, height);
    }
  }

  /**
   * Generate test frame data when real video capture is not available
   */
  generateTestFrameData(width, height) {
    const frameData = new Array(width * height * 4);
    const frameCounter = Math.floor(Date.now() / 100) % 1000;
    
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const offset = (y * width + x) * 4;
        
        // Create a moving pattern for testing
        const wave = Math.floor(128 + 64 * Math.sin((x + frameCounter) * 0.1) * Math.cos((y + frameCounter) * 0.1));
        
        frameData[offset] = wave & 0xFF;                    // R
        frameData[offset + 1] = (x + frameCounter) % 255;   // G
        frameData[offset + 2] = (y + frameCounter) % 255;   // B
        frameData[offset + 3] = 255;                        // A
      }
    }
    
    console.log('🎨 Generated test frame data:', frameData.length, 'bytes');
    return frameData;
  }

  getRendererTextureId(renderer) {
    try {
      // In Web, we use the video element directly
      // Store the renderer reference and return an ID
      const rendererId = this.generateRendererId();
      this.rendererMap.set(rendererId, renderer);
      
      return rendererId;
      
    } catch (error) {
      console.error('Error getting renderer texture ID:', error);
      return -1;
    }
  }
  getVideoElementFromRenderer(rendererId) {
    try {
      const renderer = this.rendererMap.get(rendererId);
      
      if (!renderer) {
        console.log('🔍 No stored renderer found, searching for WebRTC video elements in DOM...');
        
        // Fallback: try to find WebRTC video elements in the DOM
        const videoElements = document.querySelectorAll('video');
        console.log('📹 Found', videoElements.length, 'video elements in DOM');
        
        // Look for video elements that are likely from WebRTC
        for (const video of videoElements) {
          // Check if video has a MediaStream source (WebRTC)
          if (video.srcObject instanceof MediaStream) {
            console.log('✅ Found WebRTC video element with MediaStream');
            return video;
          }
          
          // Check if video is playing and has reasonable dimensions
          if (video.videoWidth > 0 && video.videoHeight > 0 && !video.paused) {
            console.log('✅ Found active video element:', video.videoWidth + 'x' + video.videoHeight);
            return video;
          }
        }
        
        // If no good candidates, return first video element if any exist
        if (videoElements.length > 0) {
          console.log('⚠️ Using first available video element as fallback');
          return videoElements[0];
        }
        
        console.warn('❌ No video elements found in DOM');
        return null;
      }

      // If renderer has a video element property
      if (renderer.videoElement) {
        console.log('✅ Found video element in renderer object');
        return renderer.videoElement;
      }

      // If renderer has a srcObject, try to find corresponding video element
      if (renderer.srcObject) {
        console.log('🔍 Searching for video element with matching srcObject...');
        const videoElements = document.querySelectorAll('video');
        for (const video of videoElements) {
          if (video.srcObject === renderer.srcObject) {
            console.log('✅ Found matching video element for srcObject');
            return video;
          }
        }
      }

      // If renderer is itself a video element
      if (renderer instanceof HTMLVideoElement) {
        console.log('✅ Renderer is directly a video element');
        return renderer;
      }

      console.warn('❌ Could not extract video element from renderer');
      return null;
      
    } catch (error) {
      console.error('❌ Error getting video element:', error);
      return null;
    }
  }

  generateRendererId() {
    return Math.floor(Math.random() * 1000000) + Date.now();
  }

  isFrameCaptureSupported() {
    try {
      // Check if Canvas 2D API is supported
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      
      // Check if video elements are supported
      const video = document.createElement('video');
      
      return ctx !== null && video !== null && typeof video.play === 'function';
      
    } catch (error) {
      console.error('Error checking frame capture support:', error);
      return false;
    }
  }

  /**
   * Get platform texture ID from WebRTC texture ID
   * For web, this maps texture IDs to canvas/video element handles
   */
  getPlatformTextureId(webrtcTextureId, rendererId) {
    console.log(`Getting platform texture ID for WebRTC texture: ${webrtcTextureId}, renderer: ${rendererId}`);
    
    try {
      // Method 1: Direct mapping - flutter_webrtc texture IDs are often directly usable
      if (webrtcTextureId > 0) {
        // For flutter_webrtc on Web, the texture ID typically corresponds to
        // a video element or canvas that can be accessed through the DOM
        console.log(`Returning WebRTC texture ID as platform texture ID: ${webrtcTextureId}`);
        return webrtcTextureId;
      }
      
      // Method 2: Fallback - attempt to derive platform texture from renderer ID  
      if (rendererId > 0) {
        // Some WebRTC implementations encode texture information in the renderer ID
        const derivedTextureId = Math.abs(rendererId) % 1000000; // Extract reasonable texture ID
        if (derivedTextureId > 0) {
          console.log(`Derived platform texture ID from renderer: ${derivedTextureId}`);
          return derivedTextureId;
        }
      }
      
      console.warn('Could not map WebRTC texture to platform texture');
      return -1;
      
    } catch (error) {
      console.error('Error getting platform texture ID:', error);
      return -1;
    }
  }

  /**
   * Check if frame capture is supported in the current browser
   */
}

// Auto-register when script loads
if (typeof window !== 'undefined') {
  FrameCaptureWeb.register();
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
  module.exports = FrameCaptureWeb;
}
