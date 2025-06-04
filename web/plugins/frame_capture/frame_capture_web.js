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
        throw new Error('Video element not found for renderer ID: ' + rendererId);
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
      
      // Convert to Uint8Array for Flutter
      return Array.from(imageData.data);
      
    } catch (error) {
      console.error('Error capturing frame:', error);
      return null;
    }
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
        // Fallback: try to find video elements in the DOM
        const videoElements = document.querySelectorAll('video');
        if (videoElements.length > 0) {
          return videoElements[0]; // Return first video element
        }
        return null;
      }

      // If renderer has a video element property
      if (renderer.videoElement) {
        return renderer.videoElement;
      }

      // If renderer has a srcObject, try to find corresponding video element
      if (renderer.srcObject) {
        const videoElements = document.querySelectorAll('video');
        for (const video of videoElements) {
          if (video.srcObject === renderer.srcObject) {
            return video;
          }
        }
      }

      return null;
      
    } catch (error) {
      console.error('Error getting video element:', error);
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
}

// Auto-register when script loads
if (typeof window !== 'undefined') {
  FrameCaptureWeb.register();
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
  module.exports = FrameCaptureWeb;
}
