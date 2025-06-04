#include "frame_capture_plugin.h"
#include <flutter_linux/flutter_linux.h>
#include <glib-object.h>
#include <string.h>
#include <stdio.h>

// Channel name
static const char kChannelName[] = "com.kingkiosk.frame_capture";

// Method names
static const char kCaptureFrameMethod[] = "captureFrame";
static const char kGetRendererTextureIdMethod[] = "getRendererTextureId";
static const char kIsSupportedMethod[] = "isSupported";

// Plugin structure
struct _FrameCapturePlugin {
  GObject parent_instance;
  FlMethodChannel* channel;
  GLXContext gl_context;
  Display* display;
  Window window;
};

G_DEFINE_TYPE(FrameCapturePlugin, frame_capture_plugin, G_TYPE_OBJECT)

/**
 * Initialize OpenGL context for texture operations
 */
static gboolean init_opengl_context(FrameCapturePlugin* self) {
  self->display = XOpenDisplay(NULL);
  if (!self->display) {
    g_warning("Failed to open X11 display");
    return FALSE;
  }

  // Get default screen
  int screen = DefaultScreen(self->display);
  
  // Create a window for OpenGL context
  self->window = XCreateSimpleWindow(
    self->display,
    RootWindow(self->display, screen),
    0, 0, 1, 1, 0,
    BlackPixel(self->display, screen),
    WhitePixel(self->display, screen)
  );

  // Create OpenGL context
  self->gl_context = glXCreateContext(self->display, NULL, NULL, GL_TRUE);
  if (!self->gl_context) {
    g_warning("Failed to create OpenGL context");
    XCloseDisplay(self->display);
    return FALSE;
  }

  // Make context current
  if (!glXMakeCurrent(self->display, self->window, self->gl_context)) {
    g_warning("Failed to make OpenGL context current");
    glXDestroyContext(self->display, self->gl_context);
    XCloseDisplay(self->display);
    return FALSE;
  }

  return TRUE;
}

/**
 * Capture frame from OpenGL texture
 */
static FlValue* capture_frame_from_texture(FrameCapturePlugin* self, 
                                         GLuint texture_id, 
                                         int width, 
                                         int height) {
  if (!self->gl_context) {
    g_warning("OpenGL context not initialized");
    return fl_value_new_null();
  }

  // Make sure OpenGL context is current
  if (!glXMakeCurrent(self->display, self->window, self->gl_context)) {
    g_warning("Failed to make OpenGL context current");
    return fl_value_new_null();
  }

  // Create framebuffer
  GLuint framebuffer;
  glGenFramebuffers(1, &framebuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);

  // Attach texture to framebuffer
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture_id, 0);

  // Check framebuffer status
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
    g_warning("Framebuffer not complete");
    glDeleteFramebuffers(1, &framebuffer);
    return fl_value_new_null();
  }

  // Allocate buffer for RGBA data
  size_t buffer_size = width * height * 4;
  guint8* pixels = g_malloc(buffer_size);

  // Read pixels from framebuffer
  glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

  // Check for OpenGL errors
  GLenum error = glGetError();
  if (error != GL_NO_ERROR) {
    g_warning("OpenGL error during glReadPixels: %d", error);
    g_free(pixels);
    glDeleteFramebuffers(1, &framebuffer);
    return fl_value_new_null();
  }

  // Clean up OpenGL resources
  glDeleteFramebuffers(1, &framebuffer);

  // Create Flutter byte array
  FlValue* result = fl_value_new_uint8_list(pixels, buffer_size);
  g_free(pixels);

  return result;
}

/**
 * Handle method calls from Flutter
 */
static void method_call_handler(FlMethodChannel* channel,
                               FlMethodCall* method_call,
                               gpointer user_data) {
  FrameCapturePlugin* self = FRAME_CAPTURE_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(method, kCaptureFrameMethod) == 0) {
    // Extract arguments
    FlValue* renderer_id_value = fl_value_lookup_string(args, "rendererId");
    FlValue* width_value = fl_value_lookup_string(args, "width");
    FlValue* height_value = fl_value_lookup_string(args, "height");

    if (!renderer_id_value || !width_value || !height_value) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGUMENTS",
        "Missing required arguments: rendererId, width, height",
        nullptr
      ));
    } else {
      int64_t renderer_id = fl_value_get_int(renderer_id_value);
      int64_t width = fl_value_get_int(width_value);
      int64_t height = fl_value_get_int(height_value);

      // Capture frame from WebRTC texture
      FlValue* frame_data = capture_frame_from_texture(self, (GLuint)renderer_id, (int)width, (int)height);
      
      if (frame_data) {
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(frame_data));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "CAPTURE_FAILED",
          "Failed to capture frame from texture",
          nullptr
        ));
      }
    }
  }
  else if (strcmp(method, kGetRendererTextureIdMethod) == 0) {
    // In Linux WebRTC, we typically get the texture ID directly from the renderer
    // This is a placeholder - actual implementation depends on WebRTC integration
    FlValue* renderer_value = fl_value_lookup_string(args, "renderer");
    
    if (renderer_value) {
      // For now, return a mock texture ID
      // In production, extract actual texture ID from WebRTC renderer
      int64_t texture_id = 1; // Placeholder
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(texture_id)));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGUMENTS",
        "Missing renderer argument",
        nullptr
      ));
    }
  }
  else if (strcmp(method, kIsSupportedMethod) == 0) {
    // Check if OpenGL is available
    gboolean supported = (self->gl_context != nullptr);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(supported)));
  }
  else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

/**
 * Initialize the plugin
 */
static void frame_capture_plugin_init(FrameCapturePlugin* self) {
  self->channel = nullptr;
  self->gl_context = nullptr;
  self->display = nullptr;
  self->window = 0;
}

/**
 * Dispose the plugin
 */
static void frame_capture_plugin_dispose(GObject* object) {
  FrameCapturePlugin* self = FRAME_CAPTURE_PLUGIN(object);

  // Clean up OpenGL resources
  if (self->gl_context) {
    glXDestroyContext(self->display, self->gl_context);
    self->gl_context = nullptr;
  }

  if (self->display) {
    if (self->window) {
      XDestroyWindow(self->display, self->window);
      self->window = 0;
    }
    XCloseDisplay(self->display);
    self->display = nullptr;
  }

  g_clear_object(&self->channel);
  G_OBJECT_CLASS(frame_capture_plugin_parent_class)->dispose(object);
}

/**
 * Class initialization
 */
static void frame_capture_plugin_class_init(FrameCapturePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = frame_capture_plugin_dispose;
}

/**
 * Create new plugin instance
 */
FrameCapturePlugin* frame_capture_plugin_new() {
  return FRAME_CAPTURE_PLUGIN(g_object_new(frame_capture_plugin_get_type(), nullptr));
}

/**
 * Register plugin with Flutter engine
 */
void frame_capture_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FrameCapturePlugin* plugin = frame_capture_plugin_new();

  // Initialize OpenGL context
  if (!init_opengl_context(plugin)) {
    g_warning("Failed to initialize OpenGL context for frame capture");
  }

  // Create method channel
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(
    fl_plugin_registrar_get_messenger(registrar),
    kChannelName,
    FL_METHOD_CODEC(codec)
  );

  // Set method call handler
  fl_method_channel_set_method_call_handler(
    plugin->channel,
    method_call_handler,
    g_object_ref(plugin),
    g_object_unref
  );

  g_object_unref(plugin);
}
