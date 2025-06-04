#include "custom_plugin_registrant.h"
#include "plugins/frame_capture_linux/frame_capture_plugin.h"

void register_custom_plugins(FlPluginRegistry* registry) {
  // Register FrameCapturePlugin
  g_autoptr(FlPluginRegistrar) frame_capture_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FrameCapturePlugin");
  frame_capture_plugin_register_with_registrar(frame_capture_registrar);
}
