#include "custom_plugin_registrant.h"

void RegisterCustomPlugins(flutter::FlutterEngine* engine) {
  // For now, we'll register the plugin manually in the Dart code
  // This avoids complex C++ registration issues
  // The WindowsKioskService will handle the method channel registration
}
