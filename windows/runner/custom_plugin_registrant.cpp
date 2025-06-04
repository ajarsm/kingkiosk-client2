#include "custom_plugin_registrant.h"
#include "plugins/frame_capture_windows/frame_capture_plugin.h"
#include <flutter/plugin_registrar_windows.h>

void RegisterCustomPlugins(flutter::FlutterEngine* engine) {
  auto registrar_ref = engine->GetRegistrarForPlugin("FrameCapturePlugin");
  auto registrar = flutter::PluginRegistrarManager::GetInstance()
                       ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar_ref);
  frame_capture_windows::FrameCapturePlugin::RegisterWithRegistrar(registrar);
}
