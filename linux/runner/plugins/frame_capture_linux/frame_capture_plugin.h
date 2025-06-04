#ifndef FRAME_CAPTURE_PLUGIN_H
#define FRAME_CAPTURE_PLUGIN_H

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <GL/gl.h>
#include <GL/glx.h>
#include <gdk/gdkx.h>

G_BEGIN_DECLS

#define FRAME_CAPTURE_TYPE_PLUGIN frame_capture_plugin_get_type()
G_DECLARE_FINAL_TYPE(FrameCapturePlugin, frame_capture_plugin, FRAME_CAPTURE, PLUGIN, GObject)

/**
 * FrameCapturePlugin:
 * 
 * Linux implementation of frame capture using OpenGL.
 * Captures frames from WebRTC video renderers using OpenGL texture extraction.
 */

/**
 * frame_capture_plugin_new:
 * 
 * Creates a new #FrameCapturePlugin.
 * 
 * Returns: a new #FrameCapturePlugin.
 */
FrameCapturePlugin* frame_capture_plugin_new();

/**
 * frame_capture_plugin_register_with_registrar:
 * @registrar: an #FlPluginRegistrar.
 * 
 * Registers this plugin with the Flutter engine.
 */
void frame_capture_plugin_register_with_registrar(FlPluginRegistrar* registrar);

G_END_DECLS

#endif // FRAME_CAPTURE_PLUGIN_H
